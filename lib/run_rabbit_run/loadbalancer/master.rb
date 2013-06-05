module RRR
  module Loadbalancer
    class Master
      attr_accessor :name, :workers, :updated_at

      def initialize name
        @name = name
        @workers = {}
      end

      def update workers
        @updated_at = Time.now.to_i

        @workers = workers
      end

      def number_of_consumers name
        workers.values.inject(0) { | sum, worker | worker['status'] == 'started' && worker['name'] == name ? sum + 1 : sum }
      end

      def capacity
        workers.values.inject(0) { | sum, worker | ['started', 'create'].include?(worker['status']) ? sum + worker['capacity'] : sum }
      end
    end
  end
end
