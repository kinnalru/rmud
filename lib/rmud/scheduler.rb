require 'active_support/all'

module RMud
  class Scheduler
    attr_accessor :tick

    class SortedArray
      include Enumerable

      def initialize(*array)
        @array = array.flatten.sort
      end

      def split value
        left = SortedArray.new
        while v = @array.first
          if v < value
            left.add @array.shift
          else
            break
          end
        end
        [left, self]
      end

      def to_a
        @array
      end

      def add value
        idx = @array.find_index {|e| e > value}
        if idx
          @array.insert(idx, value)
        else
          @array.push(value)
        end
        value
      end

      alias_method :<<, :add

      def remove value
        @array.delete(value)
      end

      alias_method :delete, :remove

      def each &block
        @array.each(&block)
      end

    end

    class Event
      include Comparable

      attr_accessor :at
      attr_reader :block, :repeat
      def initialize(s, at:, repeat: nil, &block)
        @s = s
        @at = at
        @repeat = repeat
        @block = block
      end

      def <=> other
        at <=> (other.respond_to?(:at) ? other.at : other)
      end

      def ==(other)
        self.repeat == other.repeat && self.block == other.block
      end

      def call(*args)
        block.call(*args)
      end
      
      def cancel
        @s.cancel(self)
      end
    end


    def initialize tick: 1
      @tick = tick
      @timers = SortedArray.new

      @thread = Thread.new(self) do |s|
        loop do
          s.run
          sleep s.tick
        end
      end
    end

    def in duraion, &block
      @timers.add Event.new(self, at: duraion.since, &block)
    end

    alias_method :after, :in

    def at time, &block
      @timers.add Event.new(self, at: time, &block)
    end

    def every duraion, &block
      @timers.add Event.new(self, at: duraion.since, repeat: duraion, &block)
    end

    def remove e
      @timers.remove(e)
    end

    alias_method :cancel, :remove

    def run
      now = Time.now
      past, @timers = @timers.split(Time.now)
      past.each do |e|
        e.call
      ensure
        if e.repeat
          e.at = e.repeat.since
          @timers.add e
        end
      end
    end

  end
end