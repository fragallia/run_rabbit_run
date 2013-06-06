module RRR
  module Processes
    module Worker
      module Processes
        def processes options = {}
          @processes ||= { max: 1, min: 1, desirable: 1 }
          unless options.empty?
            @processes = @processes.merge(options)

            @processes[:max]       = @processes[:min] if !options[:max] && options[:min]
            @processes[:desirable] = @processes[:min] if !options[:desirable] && options[:min]

            validate_processes
          end

          @processes
        end

      private

        def validate_processes
          raise 'Max processes count cannot be smaller than min' if @processes[:max] < @processes[:min]
          raise 'Desirable processes cannot be bigger than max'  if @processes[:desirable] > @processes[:max]
          raise 'Desirable processes cannot be smaller than min' if @processes[:desirable] < @processes[:min]
        end
      end
    end
  end
end
