module RRR
  module Processes
    module Worker
      module Settings
        def settings options = {}
          @settings ||= { queue_size: 250, capacity: 10, prefetch: 10 }
          unless options.empty?
            @settings = @settings.merge(options)

            validate_settings
          end

          @settings
        end

      private

        def validate_settings
          raise 'Capacity can\'t be zero or less'     if @settings[:capacity] <= 0
          raise 'Capacity can\'t be bigger than 100'  if @settings[:capacity] > 100
          raise 'Prefetch cannot be smaller than 1'   if @settings[:prefetch] < 1
          raise 'Queue size cannot be smaller than 1' if @settings[:queue_size] < 1
        end
      end
    end
  end
end
