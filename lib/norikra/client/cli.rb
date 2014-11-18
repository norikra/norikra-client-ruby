require 'thor'
require 'norikra/client'

require 'norikra/client/cli/parser'
require 'norikra/client/cli/formatter'

class Norikra::Client
  module CLIUtil
    def client(options)
      Norikra::Client.new(options[:host], options[:port])
    end
    def wrap
      begin
        yield
      rescue Norikra::RPC::ClientError => e
        puts "Failed: " + e.message
      rescue Norikra::RPC::ServerError => e
        puts "ERROR on norikra server: " + e.message
        puts " For more details, see norikra server's logs"
      end
    end
  end

  class Target < Thor
    include Norikra::Client::CLIUtil

    desc "list", "show list of targets"
    option :simple, :type => :boolean, :default => false, :desc => "suppress header/footer", :aliases => "-s"
    def list
      wrap do
        puts ["TARGET","AUTO_FIELD"].join("\t") unless options[:simple]
        targets = client(parent_options).targets
        targets.each do |t|
          puts [t['name'], t['auto_field']].join("\t")
        end
        puts "#{targets.size} targets found." unless options[:simple]
      end
    end

    desc "open TARGET [fieldname1:type1 [fieldname2:type2 [fieldname3:type3] ...]]", "create new target (and define its fields)"
    option :suppress_auto_field, :type => :boolean, :default => false, :desc => "suppress to define fields automatically", :aliases => "-x"
    def open(target, *field_defs)
      fields = nil
      if field_defs.size > 0
        fields = {}
        field_defs.each do |str|
          fname,ftype = str.split(':')
          fields[fname] = ftype
        end
      end
      auto_field = (not options[:suppress_auto_field])

      wrap do
        client(parent_options).open(target, fields, auto_field)
      end
    end

    desc "close TARGET", "close existing target and all its queries"
    def close(target)
      wrap do
        client(parent_options).close(target)
      end
    end

    desc "modify TARGET BOOL_VALUE", "modify target to do define fields automatically or not"
    def modify(target, val)
      auto_field = ['yes','true','auto'].include?(val.downcase)
      wrap do
        client(parent_options).modify(target, auto_field)
      end
    end
  end

  class Query < Thor
    include Norikra::Client::CLIUtil

    desc "list", "show list of queries"
    option :simple, :type => :boolean, :default => false, :desc => "suppress header/footer", :aliases => "-s"
    def list
      wrap do
        puts ["NAME", "GROUP", "TARGETS", "SUSPENDED", "QUERY"].join("\t") unless options[:simple]
        queries = client(parent_options).queries
        queries.sort{|a,b| (a['targets'].first <=> b['targets'].first).nonzero? || a['name'] <=> b['name']}.each do |q|
          puts [
            q['name'],
            (q['group'] || 'default'),
            q['targets'].join(','),
            q['suspended'].to_s,
            q['expression'].split("\n").map(&:strip).join(" ")
          ].join("\t")
        end
        puts "#{queries.size} queries found." unless options[:simple]
      end
    end

    desc "add QUERY_NAME QUERY_EXPRESSION", "register a query"
    option :group, :type => :string, :default => nil, :desc => "query group for sweep/listen (default: null)", :aliases => "-g"
    def add(query_name, expression)
      wrap do
        client(parent_options).register(query_name, options[:group], expression)
      end
    end

    desc "remove QUERY_NAME", "deregister a query"
    def remove(query_name)
      wrap do
        client(parent_options).deregister(query_name)
      end
    end

    desc "suspend QUERY_NAME", "specify to stop (but not removed)"
    def suspend(query_name)
      wrap do
        client(parent_options).suspend(query_name)
      end
    end

    desc "resume QUERY_NAME", "specify to re-run query suspended before"
    def resume(query_name)
      wrap do
        client(parent_options).resume(query_name)
      end
    end
  end

  class Field < Thor
    include Norikra::Client::CLIUtil

    desc "list TARGET", "show list of field definitions of specified target"
    option :simple, :type => :boolean, :default => false, :desc => "suppress header/footer", :aliases => "-s"
    def list(target)
      wrap do
        puts "FIELD\tTYPE\tOPTIONAL" unless options[:simple]
        fields = client(parent_options).fields(target)
        fields.each do |f|
          puts "#{f['name']}\t#{f['type']}\t#{f['optional']}"
        end
        puts "#{fields.size} fields found." unless options[:simple]
      end
    end

    desc "add TARGET FIELDNAME TYPE", "reserve fieldname and its type of target"
    def add(target, field, type)
      wrap do
        client(parent_options).reserve(target, field, type)
      end
    end
  end

  class Event < Thor
    include Norikra::Client::CLIUtil

    desc "send TARGET", "send data into targets"
    option :format, :type => :string, :default => 'json', :desc => "format of input data per line of stdin [json(default), ltsv]"
    option :batch_size, :type => :numeric, :default => 10000, :desc => "records sent in once transferring (default: 10000)"
    def send(target)
      client = client(parent_options)
      parser = parser(options[:format])
      buffer = []
      $stdin.each_line do |line|
        buffer.push(parser.parse(line))
        if buffer.size >= options[:batch_size]
          client.send(target, buffer)
          buffer = []
        end
      end

      wrap do
        client.send(target, buffer) if buffer.size > 0
      end
    end

    desc "fetch QUERY_NAME", "fetch events from specified query"
    option :format, :type => :string, :default => 'json', :desc => "format of output data per line of stdout [json(default), ltsv]"
    option :time_key, :type => :string, :default => 'time', :desc => "output key name for event time (default: time)"
    option :time_format, :type => :string, :default => '%Y/%m/%d %H:%M:%S', :desc => "output time format (default: '2013/05/14 17:57:59')"
    def fetch(query_name)
      formatter = formatter(options[:format])
      time_formatter = lambda{|t| Time.at(t).strftime(options[:time_format])}

      wrap do
        client(parent_options).event(query_name).each do |time,event|
          event = {options[:time_key] => Time.at(time).strftime(options[:time_format])}.merge(event)
          puts formatter.format(event)
        end
      end
    end

    desc "see QUERY_NAME", "see events of specified query, but not delete"
    option :format, :type => :string, :default => 'json', :desc => "format of output data per line of stdout [json(default), ltsv]"
    option :time_key, :type => :string, :default => 'time', :desc => "output key name for event time (default: time)"
    option :time_format, :type => :string, :default => '%Y/%m/%d %H:%M:%S', :desc => "output time format (default: '2013/05/14 17:57:59')"
    def see(query_name)
      formatter = formatter(options[:format])
      time_formatter = lambda{|t| Time.at(t).strftime(options[:time_format])}

      wrap do
        client(parent_options).see(query_name).each do |time,event|
          event = {options[:time_key] => Time.at(time).strftime(options[:time_format])}.merge(event)
          puts formatter.format(event)
        end
      end
    end

    desc "sweep [query_group_name]", "fetch all output events of all queries of default (or specified) query group"
    option :format, :type => :string, :default => 'json', :desc => "format of output data per line of stdout [json(default), ltsv]"
    option :query_name_key, :type => :string, :default => 'query', :desc => "output key name for query name (default: query)"
    option :time_key, :type => :string, :default => 'time', :desc => "output key name for event time (default: time)"
    option :time_format, :type => :string, :default => '%Y/%m/%d %H:%M:%S', :desc => "output time format (default: '2013/05/14 17:57:59')"
    def sweep(query_group=nil)
      wrap do
        formatter = formatter(options[:format])
        time_formatter = lambda{|t| Time.at(t).strftime(options[:time_format])}

        data = client(parent_options).sweep(query_group)

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
  end

  class Admin < Thor
    include Norikra::Client::CLIUtil

    desc "stats", "dump stats json: same with norikra server's --stats option"
    def stats
      opt = parent_options
      client = client(parent_options)

      targets = []
      queries = []

      wrap do
        queries = client.queries()

        client.targets().each do |t|
          fields = {}
          client.fields(t['name']).each do |f|
            next if f['type'] == 'hash' || f['type'] == 'array'
            fields[f['name']] = f
          end
          targets.push( { "name" => t['name'], "fields" => fields, "auto_field" => t['auto_field'] } )
        end
      end

      require 'json'

      puts JSON.pretty_generate({
          "threads" => {
            "engine" => { "inbound" => {}, "outbound" => {}, "route_exec" => {}, "timer_exec" => {} },
            "rpc" => {},
            "web" => {},
          },
          "log" => {},
          "targets" => targets,
          "queries" => queries,
        })
    end

    desc "logs", "get and print Norikra server logs"
    def logs
      opt = parent_options
      client = client(parent_options)
      wrap do
        client.logs().each do |time, level, line|
          puts "#{time} [#{level}] #{line}"
        end
      end
    end
  end

  class CLI < Thor
    include Norikra::Client::CLIUtil

    class_option :host, :type => :string, :default => 'localhost'
    class_option :port, :type => :numeric, :default => 26571

    desc "target CMD ...ARGS", "manage targets"
    subcommand "target", Target

    desc "field CMD ...ARGS", "manage target field/datatype definitions"
    subcommand "field", Field

    desc "query CMD ...ARGS", "manage queries"
    subcommand "query", Query

    desc "event CMD ...ARGS", "send/fetch events"
    subcommand "event", Event

    desc "admin CMD ...ARGS", "norikra server administrations"
    subcommand "admin", Admin
  end
end
