class Standard
  include Virtus.model

  attribute :id, String
  attribute :asnIdentifier, String
  attribute :position, Integer
  attribute :depth, Integer
  attribute :statementNotation, String
  attribute :statementLabel, String
  attribute :description, String

end
