module Guard
  class Shotgun < Plugin
    class Notifier

      def self.notify(result)
        message = guard_message(result)
        options = {
          title: 'guard-shotgun',
          image: guard_image(result)
        }

        ::Guard::Notifier.notify(message, options)
      end

      def self.guard_message(result)
        case result
        when 'up'
          "Sinatra up and running"
        when 'reloaded'
          "Sinatra reloaded"
        when 'failed'
          'Sinatra failed to start'
        end
      end

      # failed | success
      def self.guard_image(result)
        case result
        when 'reloaded', 'up'
          :success
        when 'failed'
          :failed
        end
      end

    end
  end
end
