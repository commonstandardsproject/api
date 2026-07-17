require 'bundler/setup'
require 'grape-entity'

module API
  module Entities
    class StandardSetSummary < Grape::Entity
      expose :_id, as: :id, documentation: {desc: "ID"}
      expose :title, documentation: {desc: "The name of the set"}
      expose :subject, documentation: {desc: "The subject"}
      expose :educationLevels, documentation: {desc: "The education levels", values: [
        "Pre-K",
        "K",
        "01",
        "02",
        "03",
        "04",
        "05",
        "06",
        "07",
        "08",
        "09",
        "10",
        "11",
        "12",
        "VocationalTraining",
        "ProfessionalEducation-Development",
        "Graduate",
        "HigherEducation",
        "Undergraduate-UpperDivision",
        "Undergraduate-LowerDivision",
        "AdultEducation",
        "LifeLongLearning",
      ]}
      expose :document
      # expose :documentTitle
    end
  end
end
