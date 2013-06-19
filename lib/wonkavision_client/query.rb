module Wonkavision
  class Client
    class Query
      LIST_DELIMITER = "|"

      attr_reader :axes, :filters, :client, :top_filter

      def initialize(client, options = {})
        @client = client
        @axes = []
        @filters = []
        @measures = []
        @order =[]
        @attributes = []
        @from = nil
        @top_filter = nil
        from_params(options[:params]) if options[:params]
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

      def order(*attributes)
        return @order unless attributes.length > 0
        attributes.flatten.each do |order|
          @order << to_ref(order)
        end
        self
      end

      def attributes(*attributes)
        return @attributes unless attributes.length > 0
        attributes.flatten.each do |attribute|
          @attributes << to_ref(attribute)
        end
        self
      end

      def where(criteria_hash = {})
        criteria_hash.each_pair do |filter,value|
          member_filter = to_filter(filter,value)
          @filters << member_filter
        end
        self
      end  

      def filter_by(*filters)
        @filters.concat filters.flatten.map{|f|to_filter(f)}
      end

      def top(num, dimension, options={})
        filters = options[:filters].map{|f|to_filter(f)} if options[:filters]
        filters ||= (options[:where] || {}).map{|f,v| to_filter(f,v)}
        @top_filter = {
          :count => num,
          :dimension => dimension.to_sym,
          :measure => options[:by] || options[:measure],
          :exclude => [options[:exclude]].flatten.compact.map{|d|d.to_sym},
          :filters => filters
        }
      end

      def to_h
        self.to_params
      end

      def to_params
        query = {"from" => @from}
        query["measures"] = @measures.join(LIST_DELIMITER) if @measures.length > 0
        query["filters"] = @client.prepare_filters(@filters)
        query["attributes"] = @attributes.map(&:to_s).join(LIST_DELIMITER) if @attributes.length > 0
        query["order"] = @order.map(&:to_s).join(LIST_DELIMITER) if @order.length > 0
        axes.each_with_index do |axis, index|
          query[self.class.axis_name(index)] = axis.map{|dim|dim.to_s}.join(LIST_DELIMITER)
        end
        if top_filter
          query["top_filter_count"] = top_filter[:count]
          query["top_filter_dimension"] = top_filter[:dimension].to_s
          query["top_filter_measure"] = top_filter[:measure].to_s if top_filter[:measure]
          query["top_filter_exclude"] = (top_filter[:exclude] || []).map(&:to_s).join(LIST_DELIMITER)
          query["top_filter_filters"] = (top_filter[:filters] || []).map(&:to_s).join(LIST_DELIMITER)
        end
        query
      end

      def from_params(params)
        from params["from"] if params["from"]
        measures params["measures"].split(LIST_DELIMITER) if params["measures"]
        filter_by params["filters"].split(LIST_DELIMITER).map{|f|MemberFilter.parse(f)} if params["filters"]
        attributes params["attributes"].split(LIST_DELIMITER).map{|f|MemberReference.parse(f)} if params["attributes"]
        order params["order"].split(LIST_DELIMITER).map{|f|MemberReference.parse(f)} if params["order"]
        self.class.axis_names.each do |axis_name|
          if params[axis_name]
            dims = params[axis_name].split(LIST_DELIMITER)
            select *dims, :on => axis_name
          end
        end
        if params["top_filter_count"] && params["top_filter_dimension"]
          top params["top_filter_count"].to_i, params["top_filter_dimension"], {
            :measure => params["top_filter_measure"],
            :exclude => (params["top_filter_exclude"] || "").split(LIST_DELIMITER),
            :filters => (params["top_filter_filters"] || "").split(LIST_DELIMITER).map{|f|MemberFilter.parse(f)}
          }
        end
        self
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
        Paginated.apply(data["data"], data["pagination"]) if data["pagination"]
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

      def to_ref(ref_or_string, default_type = :dimension)
        return nil if ref_or_string.nil?
        ref_or_string.kind_of?(MemberReference) ? ref_or_string : MemberReference.new(ref_or_string, :member_type => default_type)
      end

      def to_filter(filter_or_string, value = nil)
        return nil if filter_or_string.nil?
        filter = filter_or_string.kind_of?(MemberFilter) ? filter_or_string : MemberFilter.new(filter_or_string)
        filter.value = value unless value.nil?
        filter
      end

    end
  end
end