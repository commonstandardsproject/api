BSON Changelog
==============

## 3.2.6

### Bug Fixes

* [#44](https://github.com/mongodb/bson-ruby/pull/44) Fixed regexp deserialization in
  conjunction with SSL io. (Niels Ganser)

## 3.2.5

### Bug Fixes

* [RUBY-1024](https://jira.mongodb.org/browse/RUBY-1024) Fixed Hash#merge only to yield when keys
  exist in both hashes. (Agis Anastasopoulos)

## 3.2.4

### Bug Fixes

* [RUBY-1019](https://jira.mongodb.org/browse/RUBY-1019) Performace improvements on deserialization.

## 3.2.3

### Bug Fixes

* [#41](https://github.com/mongodb/bson-ruby/pull/41) Normalizing arrays does not mutate. (Agis Anastasopoulos)

* [#40](https://github.com/mongodb/bson-ruby/pull/40) Added big endian support. (Jeff Blight)

## 3.2.1

### Bug Fixes

[#39](https://github.com/mongodb/bson-ruby/pull/39) Fixed MD5 hashing of hostname in c extension.
  (James Hudon)

## 3.2.0

### Bug Fixes

* [RUBY-950](https://jira.mongodb.org/browse/RUBY-950) Don't encode to UTF-8 in Binary#to_bson, only force BINARY encoding.

### New features

* Add `BSON.ObjectId` constructor for instantiating an ObjectId from a String. Update ObjectId#inspect to print out a string that can be evaluated into the corresponding ObjectId. (Tony Ta)

## 3.1.2

### Bug Fixes

* [RUBY-950](https://jira.mongodb.org/browse/RUBY-950) Encode to UTF-8 then force
  BINARY encoding in Binary#to_bson.

## 3.1.1

### Bug Fixes

* Fixed argument errors when delegating to regex objects. (Tom Scott)

## 3.1.0

### New Features

* `BSON::Regexp::Raw` now behaves like a regular `Regexp` by delegating to the compiled and
  wrapped regex. (Tom Scott)

### Bug Fixes

* Fixed `inspect` on `BSON::Binary` to handle ASCII characters. (Jérémy Carlier)

## 3.0.4

### Bug Fixes

* Fixed `BSON::ObjectId.legal?` regular expression to properly check beginning and end of strings.

## 3.0.3

### Bug Fixes

* [#31](https://github.com/mongodb/bson-ruby/pull/31) Fix Int64 decode from strings.
  (Nobuyoshi Nakada)

## 3.0.2

### Bug Fixes

* [RUBY-898](https://jira.mongodb.org/browse/RUBY-898) Compensated for different
  return values of Socket#readbyte and OpenSSL::SSL::SSLSocket#readbyte.

## 3.0.1

### Bug Fixes

* Fixed installation on latest Rubygems which requires `'date'` to be required.

## 3.0.0

### Backwards Incompatible Changes

* [RUBY-852](https://jira.mongodb.org/browse/RUBY-852) Regular expressions that
  are deserialized now return a `BSON::Regexp::Raw` instead of a `Regexp` object.
  In order to get the regular expression compiled, call `#compile` on the returned object.

    raw.compile

### New Features

* `BSON::Binary` now implements `#inspect` with a truncated view of the data for
  better readability.

### Bug Fixes

* The native object id generation was fixed to match the raw Ruby. (Conrad Irwin)

* [#23](http://github.com/mongodb/bson-ruby/pull/23):
  `BSON::Binary` types can be now used as hash keys. (Adam Wróbel)

## 2.2.3

### Bug Fixes

* Fixed native C encoding of strings and performace on Rubinius.

## 2.2.2

### Bug Fixes

* [#17](http://github.com/mongodb/bson-ruby/pull/17):
  Fixed `BSON::ObjectId` counter increment on Ruby 2.1.0 since method names
  can no longer override Ruby keywords.

* [#16](http://github.com/mongodb/bson-ruby/pull/16):
  Fixed serialization of times when microseconds are causing `to_f` on time to
  be 1 microsecond inaccurate. (Francois Bernier)

## 2.2.1

### Bug Fixes

* [#15](http://github.com/mongodb/bson-ruby/pull/15):
  `Date` and `DateTime` instances now return the `Time` value for the BSON
  type, so that they can be serialized inside hashes and arrays. (Michael Sell)

## 2.2.0

### Dependency Changes

* Ruby 1.8 interpreters are no longer supported.

## 2.1.2

### Bug Fixes

* [#14](http://github.com/mongodb/bson-ruby/pull/14):
  Fixed all 1.8 errors related to `DateTime` serialization.

## 2.1.1

### Bug Fixes

* [#13](http://github.com/mongodb/bson-ruby/pull/13) /
  [RUBY-714](http://jira.mongodb.org/browse/RUBY-714):
  Require time in `DateTime` modules when using outside of
  environments that don't already have time included.

## 2.1.0

### New Features

* `Date` and `DateTime` objects in Ruby can now be serialized into BSON. `Date` is
  converted to a UTC `Time` at midnight and serialized, while `DateTime` is simply
  converted to the identical `Time` before serialization. Note that these objects
  will be deserialized into `Time` objects.

## 2.0.0

### Backwards Incompatible Changes

* `BSON::DEFAULT_MAX_BSON_SIZE` has been removed, as the BSON specification does not
  provide an upper limit on how large BSON documents can be.

* `BSON.serialize` is no longer the entry point to serialize a BSON document into its
  raw bytes.

      For Ruby runtimes that support ordered hashes, you may simply call `to_bson` on
      the hash instance (Alternatively a `BSON::Document` is also a hash:

        { key: "value" }.to_bson
        BSON::Document[:key, "value"].to_bson

      For Ruby runtimes that do not support ordered hashes, then you must instantiate
      an instance of a `BSON::Document` (which is a subclass of hash) and call `to_bson`
      on that, since the BSON specification guarantees order of the fields:

        BSON::Document[:key, "value"].to_bson

* `BSON.deserialize` is no longer the entry point for raw byte deserialization into
  a document.

      For Ruby runtimes that support ordered hashes, you may simply call `from_bson` on
      the `Hash` class if you want a `Hash` instance, or on `BSON::Document` if you
      want an instance of that. The input must be a `StringIO` object:

        Hash.from_bson(stringio)
        BSON::Document.from_bson(stringio)

      For Ruby runtimes that do not support ordered hashes, then `from_bson` must be
      called on `BSON::Document` in order to guarantee order:

        BSON::Document.from_bson(stringio)

* Calling `to_json` on custom BSON objects now outputs different results from before, and
  conforms the BSON specification:

    - `BSON::Binary`: `{ "$binary" : "\x01", "$type" : "md5" }`
    - `BSON::Code`: `{ "$code" : "this.v = 5 }`
    - `BSON::CodeWithScope`: `{ "$code" : "this.v = value", "$scope" : { v => 5 }}`
    - `BSON::MaxKey`: `{ "$maxKey" : 1 }`
    - `BSON::MinKey`: `{ "$minKey" : 1 }`
    - `BSON::ObjectId`: `{ "$oid" : "4e4d66343b39b68407000001" }`
    - `BSON::Timestamp`: `{ "t" : 5, "i" : 30 }`
    - `Regexp`: `{ "$regex" : "[abc]", "$options" : "i" }`

### New Features

* All Ruby objects that have a corresponding object defined in the BSON specification
  can now have `to_bson` called on them to get the raw BSON bytes. These objects include:

    - `Array`
    - `FalseClass`
    - `Float`
    - `Hash`
    - `Integer`
    - `NilClass`
    - `Regexp`
    - `String`
    - `Symbol` (deprecated)
    - `Time`
    - `TrueClass`

* Custom types specific to the BSON specification that have Ruby objects defined for them
  may also have `to_bson` called on them to get the raw bytes. These types are:

    - `BSON::Binary`
    - `BSON::Code`
    - `BSON::CodeWithScope`
    - `BSON::MaxKey`
    - `BSON::MinKey`
    - `BSON::ObjectId`
    - `BSON::Timestamp`
    - `BSON::Undefined`
