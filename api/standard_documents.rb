require 'grape'
require_relative '../config/mongo'
require_relative 'entities/standard_document'

module API
  class StandardDocuments < Grape::API


    namespace :standard_documents, hidden: true do
      get ":id", hidden: true do
        document = $db[:standard_documents].find({
          :_id => params[:id]
        }).projection(
          "_id" => 1,
          "document" => 1,
          "documentMeta" => 1,
          "standardSetQueries" => 1
        ).to_a.first

        present document, with: Entities::StandardsDocument
      end

    end
  end
end
