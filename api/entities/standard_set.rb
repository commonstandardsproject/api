require 'bundler/setup'
require 'grape-entity'

module API
  module Entities
    class StandardSet < Grape::Entity
      expose :_id, as: :id
      expose :title, documentation: {desc: "Title of the set"}
      expose :subject, documentation: {desc: "The subject"}
      expose :educationLevels, documentation: {desc: "An array of education levels", values: [
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
      expose :license
      expose :document
      expose :jurisdiction

      expose :standards, documentation: {desc: "A map of standards"}
    end
  end
end
