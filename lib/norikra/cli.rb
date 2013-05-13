require 'thor'
require 'norikra/client'

module Norikra
  module CLIUtil
    def client(options)
      Norikra::Client.new(options[:host], options[:port])
    end
  end

  class Table < Thor
    desc "list", "show list of tables"
    option :s, :type => :boolean, :default => false, :desc => "suppress count of tables"
    def list
      tables = client(parent_options).tables
      p tables.join("\n")
      p "#{tables.size} tables found." unless options[:s]
    end
  end

  class Query < Thor
    desc "list", "show list of queries"
    option :s, :type => :boolean, :default => false, :desc => "suppress count of queries"
    def list
      p "TABLES\tQUERY_NAME\tQUERY"
      queries = client(parent_options).queries
      queries.sort{|a,b| (a['tablename'] <=> b['tablename']).nonzero? || a['name'] <=> b['name']}.each do |q|
        p "#{q['tablename']}\t#{q['name']}\t#{q['expression']}"
      end
      p "#{queries.size} queries found." unless options[:s]
    end

    desc "add TABLE_NAME QUERY_NAME QUERY_EXPRESSION", "register a query"
    def add(table_name, query_name, expression)
      client(parent_options).add_query(table_name, query_name, expression)
    end
  end

  class Event < Thor
    desc "send TABLE_NAME", "send data into table"
    option :format, :type => :string, :default => 'json', :desc => "format of input data per line of stdin [json(default), csv, tsv]"
    def send(tablename)
      #TODO: get data from stdin and parse
      data = []
      client(parent_options).send(tablename, data)
    end

    desc "fetch QUERY_NAME", "fetch events from specified query"
    option :format, :type => :string, :default => 'json', :desc => "format of output data per line of stdout [json(default), csv, tsv]"
    def fetch(query_name)
      events = client(parent_options).event(query_name)
      #TODO: format events and print
    end

    desc "sweep", "fetch all output events of all queries"
    option :format, :type => :string, :default => 'json', :desc => "format of output data per line of stdout [json(default), csv, tsv]"
    def sweep
      events = client(parent_options).sweep
      #TODO: format events and print
    end
  end

  class CLI < Thor
    class_option :host, :type => :string, :default => 'localhost'
    class_option :port, :type => :numeric, :default => 26571

    desc "table CMD ...ARGS", "manage tables"
    subcommand "table", Table

    desc "query CMD ...ARGS", "manage queries"
    subcommand "query", Query

    desc "event CMD ...ARGS", "send/fetch events"
    subcommand "event", Event

    # def typedefs; end
    # def add_typedefs; end
  end
end
