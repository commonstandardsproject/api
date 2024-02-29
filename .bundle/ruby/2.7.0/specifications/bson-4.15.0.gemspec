# -*- encoding: utf-8 -*-
# stub: bson 4.15.0 ruby lib
# stub: ext/bson/extconf.rb

Gem::Specification.new do |s|
  s.name = "bson".freeze
  s.version = "4.15.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://jira.mongodb.org/projects/RUBY", "changelog_uri" => "https://github.com/mongodb/bson-ruby/releases", "documentation_uri" => "https://docs.mongodb.com/ruby-driver/current/tutorials/bson-v4/", "homepage_uri" => "https://docs.mongodb.com/ruby-driver/current/tutorials/bson-v4/", "source_code_uri" => "https://github.com/mongodb/bson-ruby" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Tyler Brock".freeze, "Durran Jordan".freeze, "Brandon Black".freeze, "Emily Stolfo".freeze, "Gary Murakami".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDfDCCAmSgAwIBAgIBATANBgkqhkiG9w0BAQUFADBCMRQwEgYDVQQDDAtkcml2\nZXItcnVieTEVMBMGCgmSJomT8ixkARkWBTEwZ2VuMRMwEQYKCZImiZPyLGQBGRYD\nY29tMB4XDTIyMDMzMDE5MTcwMloXDTIzMDMzMDE5MTcwMlowQjEUMBIGA1UEAwwL\nZHJpdmVyLXJ1YnkxFTATBgoJkiaJk/IsZAEZFgUxMGdlbjETMBEGCgmSJomT8ixk\nARkWA2NvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANFdSAa8fRm1\nbAM9za6Z0fAH4g02bqM1NGnw8zJQrE/PFrFfY6IFCT2AsLfOwr1maVm7iU1+kdVI\nIQ+iI/9+E+ArJ+rbGV3dDPQ+SLl3mLT+vXjfjcxMqI2IW6UuVtt2U3Rxd4QU0kdT\nJxmcPYs5fDN6BgYc6XXgUjy3m+Kwha2pGctdciUOwEfOZ4RmNRlEZKCMLRHdFP8j\n4WTnJSGfXDiuoXICJb5yOPOZPuaapPSNXp93QkUdsqdKC32I+KMpKKYGBQ6yisfA\n5MyVPPCzLR1lP5qXVGJPnOqUAkvEUfCahg7EP9tI20qxiXrR6TSEraYhIFXL0EGY\nu8KAcPHm5KkCAwEAAaN9MHswCQYDVR0TBAIwADALBgNVHQ8EBAMCBLAwHQYDVR0O\nBBYEFFt3WbF+9JpUjAoj62cQBgNb8HzXMCAGA1UdEQQZMBeBFWRyaXZlci1ydWJ5\nQDEwZ2VuLmNvbTAgBgNVHRIEGTAXgRVkcml2ZXItcnVieUAxMGdlbi5jb20wDQYJ\nKoZIhvcNAQEFBQADggEBAM0s7jz2IGD8Ms035b1tMnbNP2CBPq3pen3KQj7IkGF7\nx8LPDdOqUj4pUMLeefntX/PkSvwROo677TnWK6+GLayGm5xLHrZH3svybC6QtqTR\nmVOLUoZ4TgUmtnMUa/ZvgrIsOeiCysjSf4WECuw7g+LE6jcpLepgYTLk2u1+5SgH\nJVENj0BMkdeZIKkc2G97DSx3Zrmz7QWAaH+99XlajJbfcgvhDso+ffQkTBlOgLBg\n+WyKQ+QTIdtDiyf2LQmxWnxt/W1CmScjdLS7/yXGkkB/D9Uy+sJD747O/B9P238Q\nXnerrtyOu04RsWDvaZkCwSDVzoqfICh4CP1mlde73Ts=\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2022-04-21"
  s.description = "A fully featured BSON specification implementation in Ruby".freeze
  s.extensions = ["ext/bson/extconf.rb".freeze]
  s.files = ["ext/bson/extconf.rb".freeze]
  s.homepage = "https://docs.mongodb.com/ruby-driver/current/tutorials/bson-v4/".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Ruby implementation of the BSON specification".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version
end
