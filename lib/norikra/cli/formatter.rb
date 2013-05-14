module Norikra::Client::CLIUtil
  def formatter(format, *args)
    format ||= 'json'
    case format
    when /^json$/i
      require 'json'
      Formatter::JSON.new(*args)
    when /^ltsv$/i
      require 'ltsv'
      Formatter::LTSV.new(*args)
    else
      raise ArgumentError, "unknown format name: #{format}"
    end
  end

  module Formatter
    class JSON
      def initialize(*args)
        require 'json'
      end
      def format(obj)
        ::JSON.dump(obj)
      end
    end

    class LTSV
      def initialize(*args)
        require 'ltsv'
      end
      def format(obj)
        ::LTSV.dump(obj)
      end
    end
  end
end
