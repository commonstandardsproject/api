Deprecated
==========

Enumerable#lazy is included in Ruby >= 2.0, so you don't need to install this gem anymore.

see also:

* [http://bugs.ruby-lang.org/issues/4890](Feature #4890 Enumerable#lazy)
* [Ruby 2.0 Enumerable::Lazy | Railsware Blog](http://blog.railsware.com/2012/03/13/ruby-2-0-enumerablelazy/)

enumerable-lazy
===============

This is a sample implementation of Enumerable#lazy
(see #4890 - http://redmine.ruby-lang.org/issues/4890 ).

Enumerable#lazy returns an instance of Enumerable::Lazy,
which is like Enumerator but has 'lazy' version of .map,
.select, etc.

'lazy' version of map and select never returns an array.
Instead, they yields the transformed/filtered elements one by one.
So you can use them for - 

* huge data which cannot be processed at a time, 
* data stream which you want to process in real-time,
* or infinit list, which has no end.

Looking form another view, Enumerable#lazy (and its lazy
version of map and select) provides a way to transform or filter


Requirements
------------

Ruby 1.9.x (for now; it should not be so hard to support 1.8)

Example
-------

This code prints the first 100 primes which is of the form n^2 + 1.

   require 'prime'
   INFINITY = 1.0 / 0

   p (1..INFINITY).lazy.map{|n| n**2+1}.
                        select{|m| m.prime?}.
                        take(100)

see examples/ for more.

When do I need Enumerable#lazy?
-------------------------------

### maping/selecting huge files

Suppose you want to print the first 10 words of a text file:

  File.open(ARGV[0]){|f|
    puts f.lines.flat_map{|l| l.split}.take(10)
  }

Thanks to flat_map, this task is done by really simple code.  But this example
has a problem; when the files is extremely large, flat_map reads the entire
file, where only a few lines are really needed.

Adding '.lazy' resolves this problem:

  require 'enumerable/lazy'
  
  File.open(ARGV[0]){|f|
    puts f.lines.lazy.flat_map{|l| l.split}.take(10)
    #            ~~~~
  }

The 'lazy' version of flat_map yields the result one by one, instead of 
creating the entire array at first.

Enumerable#lazy is also useful when all the lines are important.
The following code counts the number of words of a (possible big) file.

  File.open(ARGV[0]){|f|
    p f.lines.lazy.flat_map{|l| l.split}.count
  }

Without '.lazy', flat_map loads the entire file into memory.

This example prints the length of the longest line of the file.
With '.lazy', it consumes far less memory than using normal map.

  File.open(ARGV[0]){|f|
    p f.lines.lazy.map{|l| l.size}.max
  }

### maping//selecting infinite list

Another fun of lazy evaluation is to manipulate infinit lists.
With Enumerable#lazy, you can apply map(=transform) or select(=filter) to them.

This is the exmaple shown above. Without '.lazy', map tries to
create an array with infinit length.

    require 'prime'
    INFINITY = 1.0 / 0

    p (1..INFINITY)
      .lazy
      .map{|n| n**2+1}.
      select{|m| m.prime?}.
      take(100)

Another example is finding first ten 'Fridays the 13th'
with infinit list of dates starts from 1 Jan 2011.

    require 'date'
    
    puts (Date.new(2011)..Date.new(9999))
      .lazy
      .select{|d| d.day == 13 and d.friday?}
      .take(10)

This program otherwise written with each and a counter variable:

    require 'date'
    
    n = 0
    (Date.new(2011)..Date.new(9999)).each do |d|
      if d.day == 13 and d.friday?
        puts d
        n += 1
        exit if n >= 10
      end
    end

mapping/selecting infinit lists provide another (and often simpler
and cleaner) algorithm to solve the same problem.

### maping/selecting for stream

lazy map and lazy select are considered as transformation and
filterling for streams.

So Enumerable#lazy can be used to transform/filter data stream, like
data coming from network.

Methods
-------

Enumerable::Lazy is a subclass of Enumerator. It overrides
the following methods as 'lazy' version.

* Methods which transform the element:
  * map(collect)
  * flat_map(collect_concat)
  * zip
* Methods which filters the element:
  * select(find_all)
  * grep
  * take_while
  * reject
  * drop
  * drop_while

These lazy methods returns an instance of Enumerable::Lazy,
where the 'normal' version returns an Array (and goes into infinite loop).
It means that calling these methods does not generate any result.
Actual values are generated when you call the methods like these
on Enumerable::Lazy.

* take
* first
* find(detect)

Example:

  irb> ary = (1..100).to_a
  irb> _.lazy
   => #<Enumerable::Lazy: #<Enumerator::Generator:0x000001010f3988>:each>
  irb> _.map{|n| n*n}
   => #<Enumerable::Lazy: #<Enumerator::Generator:0x000001010b5b38>:each>
  irb> _.select{|n| n.to_s[-1] == "9"}
   => #<Enumerable::Lazy: #<Enumerator::Generator:0x000001010848f8>:each>
  irb> _.take(3)
   => [9, 49, 169] 

### Methods not redefined

(FYI) Enumerable::Lazy does not override these methods:

* chunk cycle slice_before each_(cons|entry|slice|with_index|with_object)
  * They return an Enumerator. In other words, they are already lazy.

* any? include? take detect find_index first
  * They never cause an infinit loop, because they need only finite number of elements

* inject count all? none? one? max(_by) min(_by) minmax(_by)
  * They need all elements to define the return value, and they are smart enough not to store all the element on the memory.

* entries group_by partition sort(_by)
  * Size of their return value is linear to the input size.

* reverse_each
  * It needs the last element first.

Implementation note
===================

* Current implementation is not built for speed.

* zip does not need to be lazy if one of the array is finite
  (because zip terminates execution when an end is found),
  but it must be lazy for the case all the arrays are infinite. 

Contact
=======

http://github.com/yhara/enumerable-lazy

License
=======

MIT
