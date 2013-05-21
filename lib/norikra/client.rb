require "norikra/client/version"

require 'msgpack-rpc-over-http'

module Norikra
  class Client
    RPC_DEFAULT_PORT = 26571

    def initialize(host='localhost', port=RPC_DEFAULT_PORT)
      @client = MessagePack::RPCOverHTTP::Client.new("http://#{host}:#{port}/")
    end

    def targets
      @client.call(:targets)
    end

    def open(target, fields=nil)
      @client.call(:open, target, fields)
    end

    def close(target)
      @client.call(:close, target)
    end

    def queries
      @client.call(:queries)
    end

    def register(query_name, query_expression)
      @client.call(:register, query_name, query_expression)
    end

    def deregister(query_name)
      @client.call(:deregister, query_name)
    end

    def fields(target)
      @client.call(:fields, target)
    end

    def reserve(target, field, type)
      @client.call(:reserve, target, field, type)
    end

    def send(target, events)
      @client.call(:send, target, events)
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
