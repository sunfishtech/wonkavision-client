require "spec_helper"
DimensionQuery = Wonkavision::Client::DimensionQuery

describe Wonkavision::Client::DimensionQuery do
  before :each do
    @client = mock(:client, :prepare_filters => "dimension::a::key::eq::'d'")
    @query = DimensionQuery.new(@client)
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

  describe "to_h" do
    before :each do 
      @query.from "the top"
      @query.where :dimensions.a => "d"
      @query.attributes :measures.m
      @query.order :dimensions.d.caption.desc
      @hash = @query.to_h
    end
    it "should include the from aggregation" do
      @hash["from"].should == "the top"
    end
    it "Should include filters" do
      @hash["filters"].should == "dimension::a::key::eq::'d'"
    end
    it "should include the attributes" do
      @hash["attributes"].should == "measure::m::count::asc"
    end
    it "should include the sort" do
      @hash["order"].should == "dimension::d::caption::desc"
    end
  end

  describe "from_params" do
    before :each do 
      @query.from "the top"
      @query.where :dimensions.a => "d"
      @query.attributes :measures.m
      @query.order :dimensions.d.caption.desc
      @hash = @query.to_h
      @query2 = DimensionQuery.new(@client)
      @query2.from_params(@hash)
    end
    it "should read from" do
      @query2.from.should == "the top"
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
  end

  describe "to_s" do
    it "should inspect the results of to_h" do
      @query.to_s.should == @query.to_h.inspect
    end
  end

  describe "execute" do
    it "should call get on the client with an appropriate url and params" do
      @client.should_receive("get").with("dimension_query", {"from"=>"me", "filters"=>"dimension::a::key::eq::'d'"}).and_return({})
      @query.from "me"
      @query.execute
    end
  end


end