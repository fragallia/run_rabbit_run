module RRR
  module Processes
    module Worker
      module AddDependency
        def add_dependency name, *args
          @dependencies ||= {}
          @dependencies[name] = args

          @dependencies
        end

        def dependencies
          @dependencies
        end
      end
    end
  end
end
