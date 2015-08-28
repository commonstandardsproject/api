require 'grape'
require_relative '../config/mongo'
require_relative 'entities/standard_set'
require_relative '../importer/transformers/query_to_standard_set'
require_relative '../lib/standard_hierarchy'
require_relative '../lib/create_standard_set'

module API
  class StandardSets < Grape::API

    namespace "/standard_sets", desc: "Standards grouped by grade level & subject" do

      desc "Fetch a standards set", entity: Entities::StandardSet
      params do
        requires :id, type: String, desc: "ID", default: "49FCDFBD2CF04033A9C347BFA0584DF0_D2604890_grade-01"
      end
      get "/:id" do
        standard_set = $db[:standard_sets].find({
          :_id => params.id
        }).to_a.first

        return {data:{}} if standard_set.nil?

        # Add the ancestor ids to the response. This a read only field
        standard_set["standards"] = StandardHierarchy.add_ancestor_ids(standard_set["standards"])
        standard_set["educationLevels"] ||= []

        present :data, standard_set, with: Entities::StandardSet
      end


      params do
        requires :jurisdiction_id
        requires :subject
        requires :title
        requires :committerName
        requires :committerEmail
      end
      post hidden: true do
        validate_token
          new_set = CreateStandardSet.create(params)
        present :data, new_set, with: Entities::StandardSet
      end


      desc "To preview the results of a standard set query, we call this api."
      post "/from_query", hidden: true do
        validate_token
        standards_doc = $db[:standard_documents].find({
          :_id => params.standardsDocumentId
        }).to_a.first

        QueryToStandardSet.generate(standards_doc, params.query.to_hash)
      end


    end
  end
end
