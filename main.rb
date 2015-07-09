require 'logger'
require 'nokogiri'

class Main < Sinatra::Base

  configure do
    set :db, $db
  end


  get '/' do
    File.read(File.join('public', 'index.html'))
  end

  get '/sitemap.xml' do
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.urlset("xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9") {
        $db[:standard_sets].find().projection({_id: 1}).batch_size(1000).map{|doc|
          xml.url{
            xml.loc "http://beta.commonstandardsproject.com/search?ids=%5B\"#{doc["_id"]}\"%5D"
          }
        }
      }
    end

    content_type "text/xml"
    builder.to_xml
  end


end
