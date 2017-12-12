require "norikra/client/version"

require 'msgpack-rpc-over-http'

module Norikra
  module RPC
    class ClientError < MessagePack::RPCOverHTTP::RemoteError; end
    class ServerError < MessagePack::RPCOverHTTP::RemoteError; end
    class ServiceUnavailableError < MessagePack::RPCOverHTTP::RemoteError; end
  end

  class Client
    RPC_DEFAULT_PORT = 26571

    def initialize(host='localhost', port=RPC_DEFAULT_PORT, connect_timeout: nil, send_timeout: nil, receive_timeout: nil)
      @client = MessagePack::RPCOverHTTP::Client.new("http://#{host}:#{port}/")

      @client.connect_timeout = connect_timeout if connect_timeout
      @client.send_timeout = send_timeout if send_timeout
      @client.receive_timeout = receive_timeout if receive_timeout
    end

    def targets
      @client.call(:targets) #=> {:name => "name", :auto_field => true}
    end

    def open(target, fields=nil, auto_field=true)
      @client.call(:open, target, fields, auto_field)
    end

    def close(target)
      @client.call(:close, target)
    end

    def modify(target, auto_field)
      @client.call(:modify, target, auto_field)
    end

    def queries
      @client.call(:queries)
    end

    def register(query_name, query_group, query_expression)
      @client.call(:register, query_name, query_group, query_expression)
    end

    def deregister(query_name)
      @client.call(:deregister, query_name)
    end

    def suspend(query_name)
      @client.call(:suspend, query_name)
    end

    def resume(query_name)
      @client.call(:resume, query_name)
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

    # [ [time, event], ... ]
    def see(query_name)
      @client.call(:see, query_name)
    end

    # {'query_name' => [ [time, event], ... ]}
    def sweep(query_group=nil)
      @client.call(:sweep, query_group)
    end

    def logs
      @client.call(:logs)
    end
  end
end
