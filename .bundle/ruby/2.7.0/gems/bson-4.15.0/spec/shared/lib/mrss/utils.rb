# frozen_string_literal: true
# encoding: utf-8

module Mrss
  module Utils

    module_function def print_backtrace(dest=STDERR)
      begin
        hello world
      rescue => e
        dest.puts e.backtrace.join("\n")
      end
    end
  end
end
