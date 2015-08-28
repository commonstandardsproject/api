require 'bundler/setup'
require 'oj'
require 'pp'
require 'date'
require 'time'
require 'typhoeus'
require 'parallel'
require_relative 'matchers/source_to_subject_mapping_grouped'
require_relative 'transformers/asn_resource_parser'
require_relative "../lib/update_standard_set"
require_relative '../config/mongo'
require_relative '../lib/send_to_algolia'

# Comment on the organization of this file:
# - Methods are at the top
# - The one line invocation is the last line of the file (due to how Ruby's load's methods)
# - The methods roughly go in order of execution
# - The file does one thing -- convert the documents.
# - If you're new to this file, I'd open it up in two panes. Put the
#   `convert_docs` method in your left pane and view the method that it calls on the right


class Importer

  def self.run(opts)
    docs  = Oj.load(File.read('sources/asn_standard_documents_aug-28.js'))

    hydra = Typhoeus::Hydra.new(max_concurrency: 20)

    # Check that we have all the right titles
    check_document_titles(docs).call
    docs = parse_doc_json(docs)

    previously_imported_docs = get_previously_imported_docs

    docs.select{|doc|
      # This makes sure we only get the documents we haven't already imported.
      # Return true from this labmda if we want to fetch all the docs.
      if opts[:import_all]
        true
      else
        Time.at(previously_imported_docs[doc[:id]].to_i) < Time.at(doc[:date_modified].to_i)
      end
    }.tap{|arr|
      puts "Importing #{arr.length} documents"
    }.each.with_index{ |_doc, index|
      # If we want to use the ASN urls, uncomment this line. I switched to using AWS urls to relieve load on ASN
      # servers and increase thoroughput
      # request = Typhoeus::Request.new(doc[:url] + "_full.json", followlocation: true)
      request = Typhoeus::Request.new("http://s3.amazonaws.com/asnstaticd2l/data/rdf/" + _doc[:id].upcase + ".json", followlocation: true)
      request.on_complete do |response|
        begin
          p "#{index + 1}. Converting: #{request.url}"
          doc = ASNResourceParser.convert(Oj.load(response.body))
          doc = set_retrieved(doc, request, _doc[:date_modified])
          doc = save_standard_document(doc)
          doc = generate_standard_sets(doc)
          update_jurisdiction(doc)

        rescue Exception => e
          rescue_exception(e, doc)
        end
      end
      hydra.queue(request)
    }

    hydra.run

    if opts[:cache_standards]
      CachedStandards.all
    end

    if opts[:send_to_algolia]
      SendToAlgolia.all_standard_sets
    end

  end



end

def check_document_titles(docs)
  -> {
    titles_to_be_edited =  docs["documents"].reduce({}){|acc, doc|
      subject = SOURCE_TO_SUBJECT_MAPPINGS_GROUPED[doc["data"]["jurisdiction"][0]][doc["id"].upcase]
      if subject.nil?
        acc[doc["data"]["jurisdiction"][0]] ||= {}
        acc[doc["data"]["jurisdiction"][0]][doc["id"].upcase] = doc["data"]["title"][0]
        acc
      end
      acc
    }

    # Notify if we don't have all the right titles
    if titles_to_be_edited.keys.length > 0
      puts ""
      pp titles_to_be_edited
      puts ""
      raise "You must add these subjects before you continue"
    else
      puts "You've added all the subjects. Nice work!"
    end
  }
end


# Here, we're just parsing the JSON into an easier to use format for the rest of the scripts
def parse_doc_json(docs)
  find_id = lambda{ |title| $db[:jurisdictions].find({title: title}).to_a.first[:_id]}
  docs["documents"].map{|doc|
    subject = SOURCE_TO_SUBJECT_MAPPINGS_GROUPED[doc["data"]["jurisdiction"][0]][doc["id"].upcase]
    {
      date_modified:   doc["data"]["date_modified"][0],
      date_valid:      doc["data"]["date_valid"][0],
      description:     doc["data"]["description"][0],
      id:              doc["id"].upcase,
      jurisdiction:    doc["data"]["jurisdiction"][0],
      jurisdiction_id: find_id.call(doc["data"]["jurisdiction"][0]),
      subject:         subject,
      title:           doc["data"]["title"][0],
      url:             doc["data"]["identifier"][0],
    }
  }
end


# There's an odd difference between the modified timestamp
# on the JSON we download and the modified timestamp we get from the API
# (haven't tried the RSS feed yet). I'm guessing this is because they're
# separate systems and the mark modified when they import it into their
# search service. The time delay isn't due to timezone differences as it's
# often 2-6 days didfferent.
def set_retrieved(doc, request, modified)
  doc["retrieved"] = {
    from:                      request.url,
    at:                        Time.now,
    modifiedAccordingToASNApi: modified
  }
  doc
end

def save_standard_document(doc)
  $db[:standard_documents].find({_id: doc["_id"]}).find_one_and_update(doc, {upsert: true, return_document: :after})
end


def generate_standard_sets(doc)
  Parallel.each(doc["standardSetQueries"], :in_processes => 16){|query|
    p "Converting #{doc["document"]["title"]}: #{query["title"]}"
    set = QueryToStandardSet.generate(doc, query)
    UpdateStandardSet.update(set, {cache_standards: false, send_to_algolia: false})
    Parallel::Kill
  }
  doc
end

def update_jurisdiction(doc)
  # We add the document to the jurisdiction so that we have can easily have a count
  # of how mnay documents a jurisdiction has
  $db[:jurisdictions].find({_id: doc["document"]["jurisdictionId"]}).update_one({
    :$addToSet => {:cachedDocumentIds => doc["_id"]}
  })
end

# See commnet on set_retrieved
def get_previously_imported_docs
  $db[:standard_documents].find()
    .projection({"documentMeta.primaryTopic" => 1, "retrieved.modifiedAccordingToASNApi" => 1, "_id" => 1})
    .to_a
    .reduce({}){|memo, d|
      memo.merge({
        d["documentMeta"]["primaryTopic"] => d["retrieved"]["modifiedAccordingToASNApi"]
      })
    }
end

def rescue_exception(e, doc)
  puts "EXCEPTION"
  puts e.message
  puts e.backtrace.inspect
  pp doc
end
