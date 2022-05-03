require 'guard'
require 'guard/plugin'
require 'spoon'
require 'socket'
require 'timeout'

module Guard
  class Shotgun < Plugin
    VALID_ARGS = %w{server host port env daemonize pid option}

    require 'guard/shotgun/notifier'
    attr_accessor :pid

    STARTUP_TIMEOUT = 10 # seconds

    def initialize(options={})
      super
      @options = {
        host: 'localhost',
        port: 9292,
        server: "WEBrick"
      }.update(options) { |key, oldval, newval| (newval.nil? || newval.empty?) ? oldval : newval }
      @reloaded = false
    end

    # =================
    # = Guard methods =
    # =================

    # Call once when guard starts
    def start
      UI.info "Starting up Rack..."
      if running?
        UI.error "Another instance of Rack is running."
        false
      else
        @pid = Spoon.spawnp 'rackup', *(options_array << (config_file if config_file)).reject(&:nil?)
      end
      wait_for_port
      if running?
        Notifier.notify(@reloaded ? 'reloaded' : 'up')
        @reloaded = false
      else
        UI.info "Rack failed to start."
        Notifier.notify('failed')
      end
    end

    # Call with Ctrl-C signal (when Guard quit)
    def stop
      UI.info "Shutting down Rack..."
      Process.kill("TERM", @pid)
      Process.wait(@pid)
      @pid = nil
      true
    end

    def stop_without_waiting
      UI.info "Shutting down Rack without waiting..."
      Process.kill("KILL", @pid)
      Process.wait(@pid)
      @pid = nil
      true
    end

    # Call with Ctrl-Z signal
    def reload
      @reloaded = true
      restart
    end

    # Call on file(s) modifications
    def run_on_change(paths = {})
      @reloaded = true
      restart_without_waiting
    end

    private

    def config_file
      @options.fetch :config, 'config.ru'
    end

    def options_array
      @options.each_with_object([]) do |(key, val), array|
        key = key.to_s.downcase
        if VALID_ARGS.include? key
          array << "--#{key}" << val.to_s
        end
      end
    end

    def restart_without_waiting
      UI.info "Restarting Rack without waiting..."
      stop_without_waiting
      start
    end

    def restart
      UI.info "Restarting Rack..."
      stop
      start
    end

    def running?
      begin
        if @pid
          Process.getpgid @pid
          true
        else
          false
        end
      rescue Errno::ESRCH
        false
      end
    end

    def wait_for_port
      timeout_time = Time.now + STARTUP_TIMEOUT
      while Time.now < timeout_time do
        sleep 0.2
        break if port_open?(@options[:host], @options[:port])
      end
    end

    # thanks to: http://bit.ly/bVN5AQ
    def port_open?(addr, port)
      begin
        Timeout::timeout(1) do
          begin
            s = TCPSocket.new(addr, port)
            s.close
            return true
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            return false
          end
        end
      rescue Timeout::Error
      end

      return false
    end
  end
end
