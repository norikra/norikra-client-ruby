module Norikra::Client::CLIUtil
  def parser(format, *args)
    format ||= 'json'
    case format
    when /^json$/i
      require 'json'
      Parser::JSON.new(*args)
    when /^ltsv$/i
      require 'ltsv'
      Parser::LTSV.new(*args)
    else
      raise ArgumentError, "unknown format name: #{format}"
    end
  end

  module Parser
    class JSON
      def initialize(*args)
        require 'json'
      end
      def parse(line)
        ::JSON.parse(line.chop)
      end
    end

    class LTSV
      def initialize(*args)
        require 'ltsv'
      end
      def parse(line)
        ::LTSV.parse_line(line.chop, {:symbolize_keys => false})
      end
    end
  end
end
