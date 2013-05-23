module RRR
  module Utils
    module Callbacks
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def define_callback *names
          names.each do | name |
            define_method name do | &block |
              @callbacks ||= {}
              @callbacks[name.to_sym] ||= []
              @callbacks[name.to_sym] << block
            end
          end
        end
      end

      def call_callback name, *params
        @callbacks[name.to_sym].each { | c | c.call *params } if @callbacks && @callbacks[name.to_sym]
      end
    end
  end
end
