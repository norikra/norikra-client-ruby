require 'thor'
require 'norikra/client'

require 'norikra/client/cli/parser'
require 'norikra/client/cli/formatter'

class Norikra::Client
  module CLIUtil
    def client(options)
      Norikra::Client.new(options[:host], options[:port])
    end
  end

  class Table < Thor
    include Norikra::Client::CLIUtil

    desc "list", "show list of tables"
    option :simple, :type => :boolean, :default => false, :desc => "suppress header/footer", :aliases => "-s"
    def list
      puts "TABLENAME" unless options[:simple]
      tables = client(parent_options).tables
      tables.each do |t|
        puts t
      end
      puts "#{tables.size} tables found." unless options[:simple]
    end
  end

  class Typedef < Thor
    include Norikra::Client::CLIUtil

    desc "list", "show list of field definitions"
    def list
      defs = client(parent_options).typedefs
      require 'pp'
      pp defs
    end
  end

  class Query < Thor
    include Norikra::Client::CLIUtil

    desc "list", "show list of queries"
    option :simple, :type => :boolean, :default => false, :desc => "suppress header/footer", :aliases => "-s"
    def list
      puts "TABLES\tQUERY_NAME\tQUERY" unless options[:simple]
      queries = client(parent_options).queries
      queries.sort{|a,b| (a['tablename'] <=> b['tablename']).nonzero? || a['name'] <=> b['name']}.each do |q|
        puts "#{q['tablename']}\t#{q['name']}\t#{q['expression']}"
      end
      puts "#{queries.size} queries found." unless options[:simple]
    end

    desc "add TABLE_NAME QUERY_NAME QUERY_EXPRESSION", "register a query"
    def add(table_name, query_name, expression)
      client(parent_options).add_query(table_name, query_name, expression)
    end
  end

  class Event < Thor
    include Norikra::Client::CLIUtil

    desc "send TABLE_NAME", "send data into table"
    option :format, :type => :string, :default => 'json', :desc => "format of input data per line of stdin [json(default), ltsv]"
    option :batch_size, :type => :numeric, :default => 10000, :desc => "records sent in once transferring (default: 10000)"
    def send(tablename)
      client = client(parent_options)
      parser = parser(options[:format])
      buffer = []
      $stdin.each_line do |line|
        buffer.push(parser.parse(line))
        if buffer.size >= options[:batch_size]
          client.send(tablename, buffer)
          buffer = []
        end
      end
      client.send(tablename, buffer) if buffer.size > 0
    end

    desc "fetch QUERY_NAME", "fetch events from specified query"
    option :format, :type => :string, :default => 'json', :desc => "format of output data per line of stdout [json(default), ltsv]"
    option :time_key, :type => :string, :default => 'time', :desc => "output key name for event time (default: time)"
    option :time_format, :type => :string, :default => '%Y/%m/%d %H:%M:%S', :desc => "output time format (default: '2013/05/14 17:57:59')"
    def fetch(query_name)
      formatter = formatter(options[:format])
      time_formatter = lambda{|t| Time.at(t).strftime(options[:time_format])}

      client(parent_options).event(query_name).each do |time,event|
        event = {options[:time_key] => Time.at(time).strftime(options[:time_format])}.merge(event)
        puts formatter.format(event)
      end
    end

    desc "sweep", "fetch all output events of all queries"
    option :format, :type => :string, :default => 'json', :desc => "format of output data per line of stdout [json(default), ltsv]"
    option :query_name_key, :type => :string, :default => 'query', :desc => "output key name for query name (default: query)"
    option :time_key, :type => :string, :default => 'time', :desc => "output key name for event time (default: time)"
    option :time_format, :type => :string, :default => '%Y/%m/%d %H:%M:%S', :desc => "output time format (default: '2013/05/14 17:57:59')"
    def sweep
      formatter = formatter(options[:format])
      time_formatter = lambda{|t| Time.at(t).strftime(options[:time_format])}

      data = client(parent_options).sweep

      data.keys.sort.each do |queryname|
        events = data[queryname]
        events.each do |time,event|
          event = {
            options[:time_key] => Time.at(time).strftime(options[:time_format]),
            options[:query_name_key] => queryname,
          }.merge(event)
          puts formatter.format(event)
        end
      end
    end
  end

  class CLI < Thor
    include Norikra::Client::CLIUtil

    class_option :host, :type => :string, :default => 'localhost'
    class_option :port, :type => :numeric, :default => 26571

    desc "table CMD ...ARGS", "manage tables"
    subcommand "table", Table

    desc "typedef CMD ...ARGS", "manage table field/datatype definitions"
    subcommand "typedef", Typedef

    desc "query CMD ...ARGS", "manage queries"
    subcommand "query", Query

    desc "event CMD ...ARGS", "send/fetch events"
    subcommand "event", Event

    # def typedefs; end
    # def add_typedefs; end
  end
end
