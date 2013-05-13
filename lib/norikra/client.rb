require "norikra/client/version"

require 'msgpack-rpc-over-http'

module Norikra
  class Client
    RPC_DEFAULT_PORT = 26571

    def initialize(host='localhost', port=RPC_DEFAULT_PORT)
      @client = MessagePack::RPCOverHTTP::Client.new("http://#{host}:#{port}/")
    end

    def tables
      @client.call(:tables)
    end

    def queries
      @client.call(:queries)
    end

    def add_query(table_name, query_name, query_expression)
      @client.call(:add_query, query)
    end

    # def typedefs; end
    # def add_typedefs; end

    def send(tablename, events)
      @client.call(:sendevents, tablename, events)
    end

    # [ [time, event], ... ]
    def event(query_name)
      @client.call(:event, query_name)
    end

    # {'query_name' => [ [time, event], ... ]}
    def sweep
      @client.call(:sweep)
    end
  end
end
