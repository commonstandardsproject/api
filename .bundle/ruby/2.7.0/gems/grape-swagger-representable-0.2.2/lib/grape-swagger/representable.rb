# frozen_string_literal: true

require 'grape-swagger'
require 'representable'

require 'grape-swagger/representable/version'
require 'grape-swagger/representable/parser'

module GrapeSwagger
  module Representable
  end
end

GrapeSwagger.model_parsers.register(::GrapeSwagger::Representable::Parser, ::Representable::Decorator)
