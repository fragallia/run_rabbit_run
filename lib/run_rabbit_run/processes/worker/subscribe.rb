module RRR
  module Processes
    module Worker
      module Subscribe
        def subscribe name, options = {}
          raise 'You can subscribe only to one queue' if subscribable?
          @subscribe = { queue: name, options: options }
        end

        def subscribable?
          !!@subscribe
        end

        def subscribed_to
          @subscribe[:queue] if subscribable?
        end
      end
    end
  end
end
