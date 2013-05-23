module RRR
  module Worker
    module Subscribe
      def subscribe name, options = {}
        raise 'You can subscribe only to one queue' if @subscribe
        @subscribe = { queue: name, options: options }
      end
    end
  end
end
