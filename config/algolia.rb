require 'algoliasearch'

# Monkey-patch the Algolia::Client to use system CA certificates instead of bundled ones
# This fixes SSL certificate verification issues in containerized environments
module Algolia
  class Client
    alias_method :original_thread_local_hosts, :thread_local_hosts
    
    private
    
    def thread_local_hosts(read, connect_timeout, send_timeout, receive_timeout)
      thread_local_var = read ? :algolia_search_hosts : :algolia_hosts
      Thread.current[thread_local_var] ||= {}
      Thread.current[thread_local_var]["#{self.hash}:#{connect_timeout}-#{send_timeout}-#{receive_timeout}"] ||= (read ? search_hosts : hosts).map do |host|
        client = HTTPClient.new
        client.ssl_config.ssl_version = @ssl_version if @ssl && @ssl_version
        
        # Use system CA certificates instead of the gem's bundled CA bundle
        # This ensures we use up-to-date certificates from the container's OS
        client.ssl_config.set_default_paths
        
        hinfo = {
          :base_url => "http#{@ssl ? 's' : ''}://#{host}",
          :session => client
        }
        hinfo[:session].transparent_gzip_decompression = true
        hinfo[:session].connect_timeout = connect_timeout
        hinfo[:session].send_timeout = send_timeout
        hinfo[:session].receive_timeout = receive_timeout
        hinfo
      end
    end
  end
end

application_id = ENV["ALGOLIA_APPLICATION_ID"] || ''
api_key        = ENV["ALGOLIA_API_KEY"] || ''
Algolia.init :application_id => application_id, :api_key => api_key
