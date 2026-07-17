require 'grape'
require_relative '../config/mongo'
require_relative 'entities/standard_set'
require_relative '../importer/transformers/query_to_standard_set'
require_relative '../lib/standard_hierarchy'

module API
  class StandardSets < Grape::API

    namespace "/standard_sets", desc: "Standards grouped by grade level & subject" do

      desc "Fetch a standards set", entity: Entities::StandardSet
      params do
        requires :id, type: String, desc: "ID", default: "49FCDFBD2CF04033A9C347BFA0584DF0_D2604890_grade-01"
        optional :standardsAsArray, type: Boolean, desc: "Send back standards as an array instead of a dictionary", default: false
      end
      get "/:id" do
        standard_set = $db[:standard_sets].find({
          :_id => params.id
        }).to_a.first

        return {data:{}} if standard_set.nil?

        # Add the ancestor ids to the response. This a read only field
        standard_set["standards"] = StandardHierarchy.add_ancestor_ids(standard_set["standards"])
        if params[:standardsAsArray]
          standard_set["standards"] = standard_set["standards"].values
        end
        standard_set["educationLevels"] ||= []
        standard_set["id"] = standard_set["_id"]

        present :data, standard_set, with: Entities::StandardSet
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
