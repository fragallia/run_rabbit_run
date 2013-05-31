module RRR
  module Loadbalancer
    class WorkerStats

      def initialize
        @consumers = {}
        @stats = Array.new(30, 0)
      end

      def push(number_of_messages)
        @stats << number_of_messages/(number_of_consumers > 0 ? number_of_consumers : 1)
        @stats = @stats[-30,30]

        @stats
      end

      def average
        @stats.inject(0) {|sum,x| sum + x }/30
      end

      def update_number_of_consumers(master_name, count)
        @number_of_consumers[master_name] = count
      end

      def number_of_consumers
        @number_of_consumers.values.inject(0) { |sum, x | sum + x }
      end
    end
  end
end
