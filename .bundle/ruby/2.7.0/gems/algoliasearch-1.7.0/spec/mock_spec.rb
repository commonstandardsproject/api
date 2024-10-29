require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

require 'algolia/webmock'
WebMock.disable!

describe 'With a mocked client' do

  before(:each) do
    WebMock.enable!
    Thread.current[:algolia_hosts] = Thread.current[:algolia_search_hosts] = nil # reset session objects
  end

  it "should add a simple object" do
    index = Algolia::Index.new("friends")
    index.add_object!({ :name => "John Doe", :email => "john@doe.org" })
    index.search('').should == { "hits" => [ { "objectID" => 42 } ], "page" => 1, "hitsPerPage" => 1 } # mocked
    index.list_user_keys
    index.browse
    index.clear
    index.delete
  end

  after(:each) do
    WebMock.disable!
  end

end
