require 'active_support/all'

module RMud
  class EventBus

    def initialize
      @subscribers = {}
    end

    def on event, &block
      @subscribers[event.to_sym] ||= []
      @subscribers[event.to_sym].push(block)
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