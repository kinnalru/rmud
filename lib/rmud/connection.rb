module RMud
  class Connection

    attr_reader :id, :handlers, :mx

    REPLACING = {
      'pp_pp' => "'",
      'pp__pp' => "\"",
      'pp___pp' => "`",
    }

    def initialize(id:)
      @id = id
      
      @mx = Monitor.new
      @termiated = false
      @started = false

      @handlers = []
    end

    def synchronize &block
      mx.synchronize(&block)
    end

    def self.unescape line
      REPLACING.each {|(from, to)|  line.gsub!(from, to) } if line
      line
    end

    def self.readline io
      unescape(io.gets&.encode("UTF-8")&.rstrip)
    end

    def start(*args)
      return if @termiated

      do_start(*args).tap do
        @started = true
      end
    end

    def do_start(*_args)
      raise NotImplementedError.new("#{self.class}##{__method__}")
    end

    def started?
      @started
    end

    def stopped?
      !!@termiated
    end

    def termiated?
      !!@termiated
    end

    def stop(*args)
      @termiated = true

      synchronize{do_stop(*args)}
    end

    def on_line(&block)
      @handlers.push block
    end

    def write(line)
      synchronize{ do_write(line) } if line
    end

    def wait
      raise NotImplementedError.new("#{self.class}##{__method__}")
    end

    def do_stop(*_args)
      raise NotImplementedError.new("#{self.class}##{__method__}")
    end

    def do_write(_line)
      raise NotImplementedError.new("#{self.class}##{__method__}")
    end

    def process(line)
      return if line.strip.empty?

      handlers.each do |h|
        begin
          [h.call(line)].flatten
        rescue StandardError => e
          warn "Handler exception: #{e}. #{e.backtrace}"
          return []
        end
      end
    end

  end
end

