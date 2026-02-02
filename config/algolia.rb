require 'algoliasearch'

# Monkey-patch the Algolia::Client to use system CA certificates instead of bundled ones
# This fixes SSL certificate verification issues in containerized environments
module Algolia
  class Client
    # Override only the SSL configuration part to use system certificates
    # This is more maintainable than duplicating the entire method
    alias_method :original_thread_local_hosts, :thread_local_hosts
    
    private
    
    def thread_local_hosts(read, connect_timeout, send_timeout, receive_timeout)
      hosts = original_thread_local_hosts(read, connect_timeout, send_timeout, receive_timeout)
      
      # Configure each HTTP client to use system CA certificates
      # instead of the gem's bundled CA bundle
      hosts.each do |host_info|
        # Clear any previously added CA certificates (including bundled ones)
        # and use the system's default CA certificate paths
        host_info[:session].ssl_config.clear_cert_store
        host_info[:session].ssl_config.set_default_paths
      end
      
      hosts
    end
  end
end

application_id = ENV["ALGOLIA_APPLICATION_ID"] || ''
api_key        = ENV["ALGOLIA_API_KEY"] || ''
Algolia.init :application_id => application_id, :api_key => api_key
