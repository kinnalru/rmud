module RMud
  class Connection

    attr_reader :handlers, :mx

    def initialize()
      @mx = Monitor.new
      @termiated = false
      @started = false

      @handlers = []
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

    def wait
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

      do_stop(*args)
    end

    def do_stop(*_args)
      raise NotImplementedError.new("#{self.class}##{__method__}")
    end

    def on_line(&block)
      @handlers.push block
    end

    def write(line)
      mx.synchronize{ do_write(line) }
    end

    def do_write(_line)
      raise NotImplementedError.new("#{self.class}##{__method__}")
    end

    def process(line)
      return if line.strip.empty?

      results = handlers.map do |h|
        begin
          [h.call(line)].flatten
        rescue StandardError => e
          warn "Handler exception: #{e}. #{e.backtrace}"
          return []
        end
      end
      mx.synchronize do
        results.flatten.each do |l|
          do_write(l)
        end
      end
    end

  end
end

