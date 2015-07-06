require 'grape'
require_relative '../config/mongo'
require_relative 'entities/standard_set'
require_relative '../importer/transformers/query_to_standard_set'

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

        present :data, standard_set, with: Entities::StandardSet
      end


      post "/", hidden: true do
        validate_token
        standards_doc = $db[:standard_documents].find({
          :_id => params.standardsDocumentId
        }).to_a.first

        QueryToStandardSet.generate(standards_doc, params.query.to_hash)
      end


    end
  end
end
