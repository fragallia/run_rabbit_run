module RRR
  module Loadbalancer
    class WorkerStats

      def initialize
        @stats = Array.new(30, 0)
      end

      def push(number_of_messages)
        @stats << number_of_messages
        @stats = @stats[-30,30]

        @stats
      end

      def average
        @stats.inject(0) {|sum,x| sum + x }/30
      end
    end
  end
end
