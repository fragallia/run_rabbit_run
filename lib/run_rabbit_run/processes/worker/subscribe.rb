module RRR
  module Processes
    module Worker
      module Subscribe
        def subscribe name, options = {}
          raise 'You can subscribe only to one queue' if @subscribe
          @subscribe = { queue: name, options: options }
        end

        def subscribed_queue_name
          @subscribe[:queue] if @subscribe
        end
      end
    end
  end
end
