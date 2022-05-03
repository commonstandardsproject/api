# = Enumerable#lazy example implementation
#
# Enumerable#lazy returns an instance of Enumerable::Lazy.
# You can use it just like as normal Enumerable object,
# except these methods act as 'lazy':
#
#   - map       collect
#   - select    find_all
#   - reject
#   - grep
#   - drop
#   - drop_while
#   - take_while
#   - flat_map  collect_concat
#   - zip
#
# == Example
#
# This code prints the first 100 primes.
#
#   require 'prime'
#   INFINITY = 1.0 / 0
#   p (1..INFINITY).lazy.select{|m| m.prime?}.take(100)
#
# == Acknowledgements
#
#   Inspired by https://github.com/antimon2/enumerable_lz
#   http://jp.rubyist.net/magazine/?0034-Enumerable_lz (ja)

module Enumerable
  def lazy
    Lazy.new(self)
  end

  class Lazy < Enumerator
    def initialize(obj, &block)
      super(){|yielder|
        begin
          obj.each{|x|
            if block
              block.call(yielder, x)
            else
              yielder << x
            end
          }
        rescue StopIteration
        end
      }
    end

    def map(&block)
      Lazy.new(self){|yielder, val|
        yielder << block.call(val)
      }
    end
    alias collect map

    def select(&block)
      Lazy.new(self){|yielder, val|
        if block.call(val)
          yielder << val
        end
      }
    end
    alias find_all select

    def reject(&block)
      Lazy.new(self){|yielder, val|
        if not block.call(val)
          yielder << val
        end
      }
    end

    def grep(pattern)
      Lazy.new(self){|yielder, val|
        if pattern === val
          yielder << val
        end
      }
    end

    def drop(n)
      dropped = 0
      Lazy.new(self){|yielder, val|
        if dropped < n
          dropped += 1
        else
          yielder << val
        end
      }
    end

    def drop_while(&block)
      dropping = true
      Lazy.new(self){|yielder, val|
        if dropping
          if not block.call(val)
            yielder << val
            dropping = false
          end
        else
          yielder << val
        end
      }
    end
    
    def take(n)
      taken = 0
      Lazy.new(self){|yielder, val|
        if taken < n
          yielder << val
          taken += 1
        else
          raise StopIteration
        end
      }
    end

    def take_while(&block)
      Lazy.new(self){|yielder, val|
        if block.call(val)
          yielder << val
        else
          raise StopIteration
        end
      }
    end

    def flat_map(&block)
      Lazy.new(self){|yielder, val|
        ary = block.call(val)
        # TODO: check ary is an Array
        ary.each{|x|
          yielder << x
        }
      }
    end
    alias collect_concat flat_map

    def zip(*args, &block)
      enums = [self] + args
      Lazy.new(self){|yielder, val|
        ary = enums.map{|e| e.next}
        if block
          yielder << block.call(ary)
        else
          yielder << ary
        end
      }
    end

    # def chunk
    # def slice_before
    #
    # There methods are already implemented with Enumerator.

  end
end

# Example

# -- Print the first 100 primes
#require 'prime'
#p (1..1.0/0).lazy.select{|m|m.prime?}.first(100)

#p (1..1.0/0).lazy.find{|n| n*n*Math::PI>10000}

# -- Print the first 10 word from a text file
#File.open("english.txt"){|f|
#  p f.lines.lazy.flat_map{|line| line.split}.take(10)
#}

# -- Example of cycle and zip
#e1 = [1, 2, 3].cycle
#e2 = [:a, :b].cycle
#p e1.lazy.zip(e2).take(10)

# -- Example of chunk and take_while
#p Enumerator.new{|y|
#  loop do
#    y << rand(100)
#  end
#}.chunk{|n| n.even?}.
#  lazy.map{|even, ns| ns}.
#  take_while{|ns| ns.length <= 5}.to_a

