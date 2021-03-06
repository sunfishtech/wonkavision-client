module Wonkavision
  class Client

    def self.context
      @context ||= Context.new
    end

   
    class Context
      def initialize(storage = nil)
        @storage = storage || ThreadContextStorage.new
      end    

      def global_filters
        @storage[:_wonkavision_global_filters] ||= []
      end

      def filter(criteria_hash = {})
        criteria_hash.each_pair do |filter, value|
          global_filter = filter.kind_of?(MemberFilter) ? filter : MemberFilter.new(filter)
          global_filter.value = value
          global_filters << global_filter
        end
      end

      class ThreadContextStorage
        def [](key)
          store[key]
        end
        def []=(key,value)
          store[key] = value
        end

        private
        def store
          Thread.current[:_wonkavision_context] ||= {}
        end
      end

    end
  
  end
end