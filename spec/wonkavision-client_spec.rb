require "spec_helper"

describe Wonkavision::Client do
  before :each do
    @client = Wonkavision::Client.new :url => "localhost",
                                      :verbose => true,
                                      :adapter => :excon
  end
  describe "initialize" do
    
    it "should take its configuration from the options" do
      @client.url.should == "localhost"
      @client.verbose.should be_true
      @client.adapter.should == :excon
    end
    it "should initialize a Faraday connection appropriately" do
      @client.connection.should_not be_nil
      @client.connection.should be_a_kind_of Faraday::Connection
    end
  end

  describe "get" do
    it "should delegate the request to the connection" do
      @client.connection.should_receive("get").with("a/b").and_return(mock(:response, :body => nil))
      @client.get("a/b")
    end
    it "should decode the response as json" do
      @client.connection.should_receive("get").with("a/b").and_return(mock(:response, :body => Yajl::Encoder.encode({"a"=>"b"})))
      @client.get("a/b").should be_a_kind_of Hash
    end
    it "should return the raw response when requested" do
      @client.connection.should_receive("get").with("a/b").and_return(mock(:response, :body => Yajl::Encoder.encode({"a"=>"b"})))
      @client.get("a/b",:raw=>true).should == Yajl::Encoder.encode({"a"=>"b"})
    end
  end

  it "should decode json" do
    @client.decode(Yajl::Encoder.encode({"a"=>"b"})).should == {"a"=>"b"}  
  end

  describe "prepare_filters" do
    it "should include global filers" do
      Wonkavision::Client.context.filter :hi => 3
      @client.send(:prepare_filters, [:dimensions.ho.eq(1)]).should == [:dimensions.ho.eq(1), :dimensions.hi.eq(3)].map{|f|f.to_s}.join("|")
    end
  end

  describe "query" do
    describe "when a block is given that takes a parameter" do
      it "should yield the query to the block" do
        @client.query do |q|
          q.should be_a_kind_of(Wonkavision::Client::Query)
        end.should be_a_kind_of Wonkavision::Client::Query
      end
    end
    describe "when a block is given with no arity" do
      it "should instance eval the block against the query" do
        q = @client.query do
          columns :a
        end
        q.should be_a_kind_of Wonkavision::Client::Query
        q.axes[0].should == [:a]
      end
    end
    describe "when no block is given" do
      it "should just return the query" do
        @client.query.should be_a_kind_of Wonkavision::Client::Query
      end
    end
  end

   describe "dimension_query" do
    describe "when a block is given that takes a parameter" do
      it "should yield the query to the block" do
        @client.dimension_query do |q|
          q.should be_a_kind_of(Wonkavision::Client::DimensionQuery)
        end.should be_a_kind_of Wonkavision::Client::DimensionQuery
      end
    end
    describe "when a block is given with no arity" do
      it "should instance eval the block against the query" do
        q = @client.dimension_query do
          from :a
        end
        q.should be_a_kind_of Wonkavision::Client::DimensionQuery
        q.from.should == "a"
      end
    end
    describe "when no block is given" do
      it "should just return the query" do
        @client.dimension_query.should be_a_kind_of Wonkavision::Client::DimensionQuery
      end
    end
  end

end