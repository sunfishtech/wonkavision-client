require "spec_helper"
Query = Wonkavision::Client::Query

describe Wonkavision::Client::Query do
  before :each do
    @client = mock(:client, :prepare_filters => "dimension::a::key::eq::'d'")
    @query = Query.new(@client)
  end

  describe "class methods" do
    describe "axis_ordinal" do
      it "should convert nil or empty string to axis zero" do
        Query.axis_ordinal(nil).should == 0
        Query.axis_ordinal("").should == 0
      end
      it "should convert string integers into real integers" do
        Query.axis_ordinal("3").should == 3
      end
      it "should correctly interpret named axes" do
        ["Columns", :rows, :PAGES, "chapters", "SECTIONS"].each_with_index do |item,idx|
        Query.axis_ordinal(item).should == idx
        end
      end
    end
  end

  describe "select" do
    it "should associate dimensions with the default axis (columns)" do
        @query.select :hi, :there
        @query.axes[0].should == [:hi, :there]
    end
    it "should associate dimensions with the specified axis" do
      @query.select :hi, :there, :on => :rows
      @query.axes[1].should == [:hi, :there]
    end
    it "should proxy to select with an appropiate axis-method" do
      Query.axis_names.each_with_index do |axis_name, ordinal|
        @query.send(axis_name, :hi, :there)
        @query.axes[ordinal].should == [:hi,:there]
      end
    end
  end

  describe "where" do
    it "should convert a symbol to a MemberFilter" do
      @query.where :a=>:b
      @query.filters[0].should be_a_kind_of Wonkavision::Client::MemberFilter
    end

    it "should append filters to the filters array" do
      @query.where :a=>:b, :c=>:d
      @query.filters.length.should == 2
    end

    it "should set the member filters value from the hash" do
      @query.where :a=>:b
      @query.filters[0].value.should == :b
    end   
  end

  describe "filter_by" do
     it "should convert a symbol to a MemberFilter" do
      @query.filter_by :a
      @query.filters[0].should be_a_kind_of Wonkavision::Client::MemberFilter
    end

    it "should append filters to the filters array" do
      @query.filter_by :dimensions.a.eq(:b), :dimensions.c.eq(:d)
      @query.filters.length.should == 2
    end
  end

  describe "from" do
    it "should set and read the from aggregation" do
      @query.from "Abc"
      @query.from.should == "Abc"
    end
  end

  describe "measures" do
    it "should set and read measures" do
      @query.measures("a","b","c")
      @query.measures.should == ["a","b","c"]
    end
  end

  describe "to_h" do
    before :each do 
      @query.from "the top"
      @query.measures "a","b","c"
      @query.where :dimensions.a => "d"
      @query.columns "e"
      @query.rows "f","g"
      @query.attributes :measures.m
      @query.order :dimensions.d.caption.desc
      @query.top 5, "topdim", {
        :measure=>"topm", :exclude=>["topex1","topex2"], :where=>{"happy"=>"sad"}
      }
      @hash = @query.to_h
    end
    it "should include the from aggregation" do
      @hash["from"].should == "the top"
    end
    it "should include measures" do
      @hash["measures"].should == "a|b|c"
    end
    it "Should include filters" do
      @hash["filters"].should == "dimension::a::key::eq::'d'"
    end
    it "should include specified axes" do
      @hash["columns"].should == "e"
      @hash["rows"].should == "f|g"
    end
    it "should not include non-specified axes" do
      Query.axis_names[2..-1].each do |axis_name|
        @hash.keys.should_not include axis_name
      end
    end
    it "should include the attributes" do
      @hash["attributes"].should == "measure::m::count::asc"
    end
    it "should include the sort" do
      @hash["order"].should == "dimension::d::caption::desc"
    end
    it "should include top filter params" do
      @hash["top_filter_count"].should == 5
      @hash["top_filter_dimension"].should == "topdim"
      @hash["top_filter_measure"].should == "topm"
      @hash["top_filter_exclude"].should == "topex1|topex2"
      @hash["top_filter_filters"] = "dimension::happy::key::eq::'sad'"
    end
  end

  describe "from_params" do
    before :each do 
      @query.from "the top"
      @query.measures "a","b","c"
      @query.where :dimensions.a => "d"
      @query.columns "e"
      @query.rows "f","g"
      @query.attributes :measures.m
      @query.order :dimensions.d.caption.desc
      @query.top 5, "topdim", {
        :measure=>"topm", :exclude=>["topex1","topex2"], :where=>{"happy"=>"sad"}
      }
      @hash = @query.to_h
      @query2 = Query.new(@client)
      @query2.from_params(@hash)
    end
    it "should read from" do
      @query2.from.should == "the top"
    end
    it "should read measures" do
      @query2.measures.should == %w(a b c)
    end
    it "should read filters" do
      @query2.filters.length.should == @query.filters.length
      @query2.filters.should == @query.filters
    end
    it "should read attributes" do
      @query2.attributes.should == @query.attributes
    end
    it "should read order" do
      @query2.order.should == @query.order
    end
    it "should read columns" do
      @query2.axes[0].should == @query.axes[0]
    end
    it "should read rows" do
     @query2.axes[0].should == @query.axes[0]
    end
    it "should read top filter" do
      @query2.top_filter.should == {
        :count => 5,
        :measure => "topm",
        :dimension => :topdim,
        :exclude => [:topex1,:topex2],
        :filters => [:dimensions.happy.key.eq("sad")]
      }
    end
  end

  describe "to_s" do
    it "should inspect the results of to_h" do
      @query.to_s.should == @query.to_h.inspect
    end
  end

  describe "execute" do
    it "should call get on the client with an appropriate url and params" do
      @client.should_receive("get").with("query", {"from"=>"me", "filters"=>"dimension::a::key::eq::'d'", "columns"=>"a"}).and_return({})
      @query.columns "a"
      @query.from "me"
      @query.execute
    end
    it "should wrap the results in a cellset" do
      @client.should_receive("get").with("query", {"from"=>"me","filters"=>"dimension::a::key::eq::'d'", "columns"=>"a"}).and_return({})
      @query.columns "a"
      @query.from "me"
      @query.execute.should be_a_kind_of Wonkavision::Client::Cellset
    end
    it "should return raw json when 'raw' is an option" do
      @client.should_receive("get").with("query", {"from"=>"me","filters"=>"dimension::a::key::eq::'d'", "columns"=>"a"}).and_return("pretend this is json")
      @query.columns "a"
      @query.from "me"
      @query.execute(:raw => true).should == "pretend this is json"
    end
  end

  describe "execute_facts" do
    it "should call get on the client with an appropriate url and params" do
      @client.should_receive("get").with("facts", {"from"=>"me", "filters"=>"dimension::a::key::eq::'d'", "columns"=>"a"}).and_return({})
      @query.columns "a"
      @query.from "me"
      @query.execute_facts
    end
  end

end