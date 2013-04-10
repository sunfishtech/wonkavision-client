module Wonkavision
  class Client
    class Query
      LIST_DELIMITER = "|"

      attr_reader :axes, :filters, :client

      def initialize(client, options = {})
        @client = client
        @axes = []
        @filters = []
        @measures = []
      end

      def from(cube_name=nil)
        return @from unless cube_name
        @from = cube_name
        self
      end

      def select(*dimensions)
        options = dimensions.last.is_a?(::Hash) ? dimensions.pop : {}
        axis = options[:axis] || options[:on]
        axis_ordinal = self.class.axis_ordinal(axis)
        @axes[axis_ordinal] = dimensions
        self
      end
     
      def measures(*measures)
        return @measures if measures.length < 1
        @measures.concat measures.flatten
        self
      end

      def where(criteria_hash = {})
        criteria_hash.each_pair do |filter,value|
          member_filter = filter.kind_of?(MemberFilter) ? filter :
            MemberFilter.new(filter)
          member_filter.value = value
          @filters << member_filter
        end
        self
      end  

      def to_h
        self.to_params
      end

      def to_params
        query = {"from" => @from}
        query["measures"] = @measures.join(LIST_DELIMITER) if @measures.length > 0
        query["filters"] = @client.prepare_filters(@filters)
        axes.each_with_index do |axis, index|
          query[self.class.axis_name(index)] = axis.map{|dim|dim.to_s}.join(LIST_DELIMITER)
        end
        query
      end

      def to_s
        to_h.inspect
      end

      def inspect
        to_s
      end

      def execute(opts={})
        raw = opts.delete(:raw)
        cellset_data = @client.get("query", self.to_params.merge!(opts))
        return cellset_data if raw
        cs = Cellset.new(cellset_data)
        raise cellset_data["error"] if cellset_data["error"]
        Cellset.new(cellset_data)  
      end

      def execute_facts(opts={})
        raw = opts.delete(:raw)
        data = @client.get("facts", self.to_params.merge!(opts))
        return data if raw
        raise data["error"] if data["error"]
        data
      end

      def self.axis_names
        ["columns","rows","pages","chapters","sections"]
      end
      
      #add methods for each axis
      #ex: Query.new.columns("col a", "col b").rows("col c", "col d")
      self.axis_names.each do |axis|
        eval "def #{axis}(*args);add_options(args, :axis=>#{axis.inspect});select(*args);end"
      end

      def self.axis_ordinal(axis_def)
        axis_name = axis_def.to_s.strip.downcase.to_s
        axis_names.index(axis_name) || axis_def.to_i
      end

      def self.axis_name(axis_ordinal)
        axis_names[axis_ordinal]
      end
      
      private
      def add_options(args, new_options)
        opts = args.last.is_a?(::Hash) ? args.pop : {}
        opts.merge!(new_options)
        args.push opts
        self
      end

      

    end
  end
end