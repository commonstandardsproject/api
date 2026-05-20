defmodule CspApiWeb.Schemas do
  @moduledoc """
  OpenAPI 3.0 schema modules for the CSP API. Used both as response
  shape documentation (rendered at `/api/v1/swagger_doc`) and as
  reusable references from controller `operation/2` declarations.

  The shapes here mirror the JSON returned by the matching
  `CspApiWeb.*JSON` view modules.
  """

  alias OpenApiSpex.Schema

  defmodule Jurisdiction do
    @moduledoc false
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "Jurisdiction",
      description: "A jurisdiction (state, organization, etc.) that owns standards.",
      type: :object,
      properties: %{
        id: %Schema{type: :string, example: "MD"},
        title: %Schema{type: :string, example: "Maryland"},
        type: %Schema{type: :string, enum: ["state", "organization"], example: "state"}
      },
      required: [:id, :title, :type]
    })
  end

  defmodule StandardSetSummary do
    @moduledoc false
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "StandardSetSummary",
      description: "Lightweight reference to a standard set (no nested standards).",
      type: :object,
      properties: %{
        id: %Schema{type: :string, example: "MD_D1_grade-01"},
        title: %Schema{type: :string, example: "Grade 1"},
        subject: %Schema{type: :string, example: "Math"},
        educationLevels: %Schema{type: :array, items: %Schema{type: :string}, example: ["01"]},
        document: %Schema{type: :object, additionalProperties: true}
      },
      required: [:id, :title]
    })
  end

  defmodule Standard do
    @moduledoc false
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "Standard",
      type: :object,
      properties: %{
        id: %Schema{type: :string},
        depth: %Schema{type: :integer},
        position: %Schema{type: :integer},
        description: %Schema{type: :string},
        statementNotation: %Schema{type: :string},
        listId: %Schema{type: :string},
        # Tree structure: nested object map keyed by child id when
        # returned as an object, or omitted/replaced by `children`
        # when `?standardsAsArray=true`.
        children: %Schema{
          type: :array,
          items: %Schema{type: :object, additionalProperties: true}
        }
      },
      required: [:id, :description]
    })
  end

  defmodule StandardSet do
    @moduledoc false
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "StandardSet",
      description: "A full standard set, including its (possibly nested) standards.",
      type: :object,
      properties: %{
        id: %Schema{type: :string},
        title: %Schema{type: :string},
        subject: %Schema{type: :string},
        educationLevels: %Schema{type: :array, items: %Schema{type: :string}},
        document: %Schema{type: :object, additionalProperties: true},
        jurisdiction: Jurisdiction,
        # `standards` is an object keyed by id by default, or a list
        # of `Standard` when `?standardsAsArray=true`.
        standards: %Schema{
          oneOf: [
            %Schema{type: :object, additionalProperties: Standard},
            %Schema{type: :array, items: Standard}
          ]
        }
      },
      required: [:id, :title]
    })
  end

  defmodule StandardDocument do
    @moduledoc false
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "StandardDocument",
      type: :object,
      properties: %{
        id: %Schema{type: :string},
        title: %Schema{type: :string},
        sourceURL: %Schema{type: :string},
        publicationStatus: %Schema{type: :string},
        subject: %Schema{type: :string},
        jurisdiction: Jurisdiction,
        standardSets: %Schema{type: :array, items: StandardSetSummary}
      },
      required: [:id]
    })
  end

  defmodule User do
    @moduledoc false
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "User",
      type: :object,
      properties: %{
        id: %Schema{type: :string},
        email: %Schema{type: :string, format: :email},
        name: %Schema{type: :string},
        isCommitter: %Schema{type: :boolean},
        allowedOrigins: %Schema{type: :array, items: %Schema{type: :string}}
      },
      required: [:id, :email]
    })
  end

  defmodule PullRequestActivity do
    @moduledoc false
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "PullRequestActivity",
      type: :object,
      properties: %{
        type: %Schema{
          type: :string,
          enum: ["created", "forked", "comment", "status-change"]
        },
        title: %Schema{type: :string},
        createdAt: %Schema{type: :string, format: :"date-time"},
        userId: %Schema{type: :string},
        userEmail: %Schema{type: :string}
      },
      required: [:type, :createdAt]
    })
  end

  defmodule PullRequest do
    @moduledoc false
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "PullRequest",
      type: :object,
      properties: %{
        id: %Schema{type: :string},
        submitterId: %Schema{type: :string},
        submitterEmail: %Schema{type: :string, format: :email},
        status: %Schema{
          type: :string,
          enum: ["draft", "approval-requested", "approved", "rejected", "revise-and-resubmit"]
        },
        forkedFromStandardSetId: %Schema{type: :string, nullable: true},
        standardSet: %Schema{type: :object, additionalProperties: true},
        activities: %Schema{type: :array, items: PullRequestActivity}
      },
      required: [:id, :status]
    })
  end

  defmodule Envelope do
    @moduledoc """
    Convenience for `{"data": <T>}`. Used in operation declarations
    via `Envelope.of(MySchema)` so each endpoint gets its own typed
    response.
    """

    def of(inner) do
      %Schema{
        type: :object,
        properties: %{data: inner},
        required: [:data]
      }
    end

    def list_of(inner) do
      %Schema{
        type: :object,
        properties: %{data: %Schema{type: :array, items: inner}},
        required: [:data]
      }
    end
  end

  defmodule Error do
    @moduledoc false
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "Error",
      type: :object,
      properties: %{
        errors: %Schema{type: :object, additionalProperties: true},
        error: %Schema{type: :string}
      }
    })
  end
end
