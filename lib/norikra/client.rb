require "norikra/client/version"

require 'msgpack-rpc-over-http-jruby'

module Norikra
  module RPC
    class ClientError < MessagePack::RPCOverHTTP::RemoteError; end
    class ServerError < MessagePack::RPCOverHTTP::RemoteError; end
  end

  class Client
    RPC_DEFAULT_PORT = 26571
    TIMEOUT_OPTIONS = [:connect_timeout, :send_timeout, :receive_timeout]

    def initialize(host='localhost', port=RPC_DEFAULT_PORT, opts={})
      @client = MessagePack::RPCOverHTTP::Client.new("http://#{host}:#{port}/")

      @client.connect_timeout = opts[:connect_timeout] if opts.has_key?(:connect_timeout) && @client.respond_to?('connect_timeout='.to_sym)
      @client.send_timeout    = opts[:send_timeout]    if opts.has_key?(:send_timeout)    && @client.respond_to?('send_timeout='.to_sym)
      @client.receive_timeout = opts[:receive_timeout] if opts.has_key?(:receive_timeout) && @client.respond_to?('receive_timeout='.to_sym)
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
