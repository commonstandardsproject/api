require 'grape'
require_relative '../importer/transformers/query_to_standard_set'
require_relative '../lib/update_standard_set'

module API
  class StandardSetImport < Grape::API

    post "standard_set_import", hidden: true do
      validate_token

      standards_doc = $db[:standard_documents].find({
        :_id => params.standardsDocumentId
      }).to_a.first

      set = QueryToStandardSet.generate(standards_doc, params.query.to_hash)
      UpdateStandardSet.update(set)

      add_swagger_documentation
    end
  end
end
