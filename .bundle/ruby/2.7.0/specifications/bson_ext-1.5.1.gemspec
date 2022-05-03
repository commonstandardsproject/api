# -*- encoding: utf-8 -*-
# stub: bson_ext 1.5.1 ruby ext
# stub: ext/cbson/extconf.rb

Gem::Specification.new do |s|
  s.name = "bson_ext".freeze
  s.version = "1.5.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["ext".freeze]
  s.authors = ["Mike Dirolf".freeze]
  s.date = "2011-11-29"
  s.description = "C extensions to accelerate the Ruby BSON serialization. For more information about BSON, see http://bsonspec.org.  For information about MongoDB, see http://www.mongodb.org.".freeze
  s.email = "mongodb-dev@googlegroups.com".freeze
  s.extensions = ["ext/cbson/extconf.rb".freeze]
  s.files = ["Rakefile".freeze, "bson_ext.gemspec".freeze, "ext/cbson/bson_buffer.c".freeze, "ext/cbson/bson_buffer.h".freeze, "ext/cbson/cbson.c".freeze, "ext/cbson/encoding_helpers.c".freeze, "ext/cbson/encoding_helpers.h".freeze, "ext/cbson/extconf.rb".freeze, "ext/cbson/version.h".freeze, "ext/cmongo/c-driver/src/bson.c".freeze, "ext/cmongo/c-driver/src/bson.h".freeze, "ext/cmongo/c-driver/src/gridfs.c".freeze, "ext/cmongo/c-driver/src/gridfs.h".freeze, "ext/cmongo/c-driver/src/md5.c".freeze, "ext/cmongo/c-driver/src/md5.h".freeze, "ext/cmongo/c-driver/src/mongo.c".freeze, "ext/cmongo/c-driver/src/mongo.h".freeze, "ext/cmongo/c-driver/src/mongo_except.h".freeze, "ext/cmongo/c-driver/src/numbers.c".freeze, "ext/cmongo/c-driver/src/platform_hacks.h".freeze, "ext/cmongo/c-driver/test/all_types.c".freeze, "ext/cmongo/c-driver/test/auth.c".freeze, "ext/cmongo/c-driver/test/benchmark.c".freeze, "ext/cmongo/c-driver/test/count_delete.c".freeze, "ext/cmongo/c-driver/test/endian_swap.c".freeze, "ext/cmongo/c-driver/test/errors.c".freeze, "ext/cmongo/c-driver/test/examples.c".freeze, "ext/cmongo/c-driver/test/gridfs.c".freeze, "ext/cmongo/c-driver/test/json.c".freeze, "ext/cmongo/c-driver/test/pair.c".freeze, "ext/cmongo/c-driver/test/replica_set.c".freeze, "ext/cmongo/c-driver/test/resize.c".freeze, "ext/cmongo/c-driver/test/simple.c".freeze, "ext/cmongo/c-driver/test/sizes.c".freeze, "ext/cmongo/c-driver/test/test.h".freeze, "ext/cmongo/c-driver/test/update.c".freeze]
  s.homepage = "http://www.mongodb.org".freeze
  s.rubygems_version = "3.3.12".freeze
  s.summary = "C extensions for Ruby BSON.".freeze
end

