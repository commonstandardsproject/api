require 'virtus'

class Standard
  include Virtus.model

  attribute :id, String
  attribute :asnIdentifier, String
  attribute :position, Integer
  attribute :depth, Integer
  attribute :listId, String
  attribute :statementNotation, String
  attribute :altStatementNotation, String
  attribute :statementLabel, String
  attribute :description, String
  attribute :comments, Array[String]

end
