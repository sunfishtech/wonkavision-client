module Wonkavision
  class Client
    class DimensionQuery
      
      attr_reader :attributes, :order, :filters

      def initialize(client, options={})
        @client = client
        @filters = []
        @order = []
        @attributes =[]
        @from = nil
        from_params(options[:params]) if options[:params]
      end

      def from(dimension_name=nil)
        return @from unless dimension_name
        @from = dimension_name.to_s
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


      def add_filter(member_filter)
        @filters << member_filter
        self
      end

      def execute(opts={})
        @client.get("dimension_query", self.to_params.merge!(opts))
      end

       def to_h
        self.to_params
      end

      def to_params
        query = {"from" => @from}
        query["filters"] = @client.prepare_filters(@filters, false)
        query["attributes"] = @attributes.map(&:to_s).join(Query::LIST_DELIMITER) if @attributes.length > 0
        query["order"] = @order.map(&:to_s).join(Query::LIST_DELIMITER) if @order.length > 0
        query
      end

      def from_params(params)
        from params["from"] if params["from"]
        filter_by params["filters"].split(Query::LIST_DELIMITER).map{|f|MemberFilter.parse(f)} if params["filters"]
        attributes params["attributes"].split(Query::LIST_DELIMITER).map{|f|MemberReference.parse(f)} if params["attributes"]
        order params["order"].split(Query::LIST_DELIMITER).map{|f|MemberReference.parse(f)} if params["order"]
        self
      end

      def to_s
        to_h.inspect
      end

      def inspect
        to_s
      end

      private

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
