require 'mongo'
require 'securerandom'
require 'pp'
require 'active_support/core_ext/hash/slice'

logger = Logger.new(STDOUT)
logger.level = Logger::WARN
Mongo::Logger.logger = logger
$db = $db || Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'standards')



class CacheStandardsSet

  def self.cache(standardsSet)
    # loop through standards set
    # add the ancestors
    # add the jurisdiction
    # format:
    # {
    #   id: "",
    #   jurisdiction: {
    #     title: "",
    #     id: "",
    #   },
    #   document: {
    #     title: "",
    #     url: ""
    #   },
    #   standardSet: {
    #     title: "",
    #     id: "",
    #     subject: "",
    #     educationLevels: [],
    #   },
    #   standard: {
    #     listId: "", statementNotation: "", description: "", comments: "", depth: 1
    #   },
    #   ancestorStandards: [
    #     {listId: "", statementNotation: "", description: "", comments: "", depth: 1}
    #   ]
    # }

    # different
    # {
    #   id: "",
    #   jurisdiction: {
    #     title: "",
    #     id: "",
    #   },
    #
    #   document: {
    #     title: "",
    #     url: ""
    #   },
    #
    #   standardSet: {
    #     title: "",
    #     id: "",
    #   },
    #
    #   listId: "",
    #   statementNotation: "",
    #   description: "",
    #   comments: "",
    #   depth: 1,
    #
    #   subject: "",
    #   educationLevels: "",
    #
    #   ancestorStandards: [
    #     {listId: "", statementNotation: "", description: "", comments: "", depth: 1}
    #   ]
    # }
    # {
    #   data: {
    #     type: "standard",
    #     id: 1,
    #     attributes: {
    #       statementNotation: "",
    #       description: "",
    #       comments: [],
    #       listId: "",
    #       depth: "",
    #     }
    #   },
    #   relationships: {
    #     ancestorStatements: {
    #       data: [
    #         { type: "standard", id: "123123" }
    #         { type: "standard", id: "123" }
    #       ]
    #     },
    #     jurisdiction: {
    #       data: {
    #         type: "jurisdiction", id: "123"
    #       }
    #     },
    #     standardSet: {
    #       data: {
    #         type: "jurisdiction", id: "123"
    #       }
    #     }
    #   },
    #   included: [
    #     {
    #       type: "standard",
    #       id: "123123",
    #       attributes: {
    #         listId: "",
    #         statementNotation: "",
    #         comments: [""],
    #         depth: "",
    #       }
    #     },
    #     {
    #       type: "jurisdiction",
    #       id: "123",
    #       attributes: {
    #
    #       }
    #     }
    #   ]
    # }
  end

end
