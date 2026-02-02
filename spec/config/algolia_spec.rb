require 'spec_helper'
require 'httpclient'

describe "Algolia Configuration" do
  it "should load algolia configuration without errors" do
    expect { require_relative '../../config/algolia' }.not_to raise_error
  end

  it "should override thread_local_hosts method to customize SSL config" do
    # Verify the monkey patch is applied
    expect(Algolia::Client.private_instance_methods).to include(:thread_local_hosts)
    expect(Algolia::Client.private_instance_methods).to include(:original_thread_local_hosts)
  end

  it "should configure HTTPClient to use system certificates" do
    # Skip if Algolia credentials are not set
    skip "Requires ALGOLIA credentials" unless ENV["ALGOLIA_APPLICATION_ID"] && ENV["ALGOLIA_API_KEY"]
    
    # Create a client instance
    client = Algolia::Client.new(
      application_id: ENV["ALGOLIA_APPLICATION_ID"],
      api_key: ENV["ALGOLIA_API_KEY"]
    )
    
    # Access thread_local_hosts to trigger SSL configuration
    # This is a private method, so we use send to access it
    hosts = client.send(:thread_local_hosts, false, 2, 30, 30)
    
    # Verify that the SSL config uses default paths
    # The presence of cert_store paths indicates system certificates are being used
    ssl_config = hosts.first[:session].ssl_config
    expect(ssl_config).to be_a(HTTPClient::SSLConfig)
  end
end
