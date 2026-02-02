require 'spec_helper'

describe "Algolia Configuration" do
  it "should load algolia configuration without errors" do
    expect { require_relative '../../config/algolia' }.not_to raise_error
  end

  it "should override thread_local_hosts method" do
    # Verify the monkey patch is applied
    expect(Algolia::Client.private_instance_methods).to include(:thread_local_hosts)
    expect(Algolia::Client.private_instance_methods).to include(:original_thread_local_hosts)
  end
end
