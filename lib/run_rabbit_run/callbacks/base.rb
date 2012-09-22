module RunRabbitRun
  module Callbacks
    module Base
      def on_success(&block)
        @on_complete ||= []
        @on_complete << block if block_given?
        @on_complete
      end

      def on_failure(&block)
        @on_failure ||= []
        @on_failure << block if block_given?
        @on_failure
      end

      def on_complete(&block)
        @on_complete ||= []
        @on_complete << block if block_given?
        @on_complete
      end

      def execute_callbacks
        callbacks = on_complete
        if @response && @response.success?
          callbacks += on_success
        elsif response
          callbacks += on_failure
        end

        callbacks.map{ |callback| callback.call(self.response) }
      end
    end
  end
end
