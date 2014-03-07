require "rubygems"
require "bundler"
Bundler.setup(:default)
require "certified"
require "faraday"
require "yajl"

require "wonkavision_client/version"
require "wonkavision_client/context"
require "wonkavision_client/extensions"
require "wonkavision_client/member_reference"
require "wonkavision_client/member_filter"
require "wonkavision_client/query"
require "wonkavision_client/dimension_query"
require "wonkavision_client/cellset/cell"
require "wonkavision_client/cellset/axis"
require "wonkavision_client/cellset/measure"
require "wonkavision_client/cellset/dimension"
require "wonkavision_client/cellset/member"
require "wonkavision_client/cellset"
require "wonkavision_client/paginated"

module Wonkavision
  class Client
    attr_reader :verbose, :connection, :adapter, :url, :username, :password

    def initialize(options={})
      @url = options[:url]
      @secure = options[:secure] || options[:ssl]
      @verbose = options[:verbose] || false
      @adapter = options[:adapter] || Faraday.default_adapter
      @username = options[:username]
      @password = options[:password]

      @connection = Faraday.new(:url => self.url) do |builder|
        builder.request :url_encoded
        builder.response :logger if @verbose
        builder.adapter @adapter
        builder.basic_auth(username, password) if username
      end
    end

    def query(options = {}, &block)
      new_query = Query.new(self, options)
      if block_given?
        if block.arity > 0
          yield new_query
        else
          new_query.instance_eval(&block)
        end
      end
      new_query
    end

    def dimension_query(options={},&block)
      new_query = DimensionQuery.new(self, options)
      if block_given?
        if block.arity > 0
          yield new_query
        else
          new_query.instance_eval(&block)
        end
      end
      new_query
    end

    #http methods
    def self.default_adapter
      Faraday.default_adapter
    end

    def self.default_adapter=(new_adapter)
      Faraday.default_adapter = new_adapter
    end

    def get(path, parameters={})
      raw = parameters.delete(:raw)
      response = @connection.get(path) do |r|
        r.params.update parameters
        r.headers['Accept'] = 'application/json'    
      end

      raw ? response.body : decode(response.body)
    end

    #helpers
    def decode(json = nil)
      json ? Yajl::Parser.new.parse(json) : {}
    end

    def prepare_filters(filters, apply_global_filters=true)
      filters = (filters + Wonkavision::Client.context.global_filters) if apply_global_filters
      filters.compact.uniq.map{|f|f.to_s}.join(Query::LIST_DELIMITER)  
    end

  end
end
