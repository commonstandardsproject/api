require 'mustermann/pattern'
require 'mustermann/simple_match'

module Mustermann
  # Matches strings that are identical to the pattern.
  #
  # @example
  #   Mustermann.new('/*.*', type: :shell) === '/bar' # => false
  #
  # @see Mustermann::Pattern
  # @see file:README.md#shell Syntax description in the README
  class Shell < Pattern
    register :shell

    # @param (see Mustermann::Pattern#initialize)
    # @return (see Mustermann::Pattern#initialize)
    # @see (see Mustermann::Pattern#initialize)
    def initialize(string, options = {})
      @flags = File::FNM_PATHNAME | File::FNM_DOTMATCH
      @flags |= File::FNM_EXTGLOB if defined? File::FNM_EXTGLOB
      super(string, options)
    end

    # @param (see Mustermann::Pattern#===)
    # @return (see Mustermann::Pattern#===)
    # @see (see Mustermann::Pattern#===)
    def ===(string)
      File.fnmatch? @string, unescape(string), @flags
    end

    # @param (see Mustermann::Pattern#peek_size)
    # @return (see Mustermann::Pattern#peek_size)
    # @see (see Mustermann::Pattern#peek_size)
    def peek_size(string)
      @peek_string ||= @string + "{**,/**,/**/*}"
      super if File.fnmatch? @peek_string, unescape(string), @flags
    end
  end
end
