class Plugin

  self.instance_variable_set('@deps', [])

  class << self

    attr_accessor :deps

    def inherited(derived)
      super
      derived.instance_variable_set('@deps', self.deps.deep_dup)
    end

    def set_deps(*deps)
      self.deps = deps
    end

  end

  attr_reader :bot, :args, :deps, :kwargs

  def initialize(bot, *args, **kwargs)
    @bot = bot
    @args = args
    @kwargs = kwargs
    @subscriptions = []

    @deps = {}

    self.class.deps.each do |d|
      p = bot.plugin(d)
      @deps[p.class] = p
    end
    info('activated')
  end

  def terminate
    @subscriptions.each do |s|
      bot.bus.subscribe(s)
    end
  end

  def process(_line)
    raise NotImplementedError.new("#{self.class}##{__method__}")
  end

  def status(*_args)
    info('active')
  end

  def send(command)
    bot.api.send(command)
  end

  def info(msg)
    bot.api.info("[#{self.class}]: #{msg}")
  end

  def warn(msg)
    bot.api.warn("[#{self.class}]: #{msg}")
  end

  def danger(msg)
    bot.api.danger("[#{self.class}]: #{msg}")
  end

  def error(msg)
    bot.api.error("[#{self.class}]: #{msg}")
  end

  def notify(event, payload = nil)
    bot.notify(event, payload)
  end

  def subscribe(event, &)
    s = nil
    s = bot.bus.subscribe(event) do |ev|
      ev.instance_variable_set('@__subscription', s)
      ev.instance_eval do
        def subscription
          @__subscription
        end
      end

      yield(ev)
    rescue StandardError => ex
      STDERR.puts ex.backtrace
      error(ex.inspect)
    end
    s.instance_variable_set('@__plugin', self)
    @subscriptions << s
    
    s.instance_eval do
      def unsubscribe
        instance_variable_get('@__plugin').unsubscribe(self)
      end
    end

    s
  end

  def unsubscribe(s)
    bot.bus.unsubscribe(s)
    @subscriptions.delete(s)
  end

  def subscribe_once(event)
    subscribe(event) do |event|
      event.subscription.unsubscribe
      yield(event)
    end
  end

  def match(line, rxs)
    line = [line].flatten.join(' ')
    line = line.split("\n").join(' ').gsub(/\s+/, ' ').strip

    rxs = [rxs].flatten
    rxs.each do |rx|
      if (md = rx.match(line))
        return md
      end
    end
    nil
  end

  def await_action name, *args, duration: 60.seconds
    Concurrent::Promises.resolvable_future.tap do |promise|
      id = "action[#{name}]:#{rand(10_000)}"
      s = subscribe(::RMud::Bot::LINE_EVENT) do |event|
        if event.payload && event.payload["#{id}:completed"]
          event.subscription.unsubscribe
          promise.fulfill([id, true, *args])
        end
      end

      bot.scheduler.after duration do
        s.unsubscribe
        promise.reject([StandardError.new("action[#{name}] timeout!"), *args], false)
      end

      yield
      send("help #{id}:completed")
    end
  end

  def await_line name, rxs, *args, duration: 60.seconds
    Concurrent::Promises.resolvable_future.tap do |promise|
      lines = ''
      s = nil
      action = await_action(name, duration: duration) do
        s = subscribe(::RMud::Bot::LINE_EVENT) do |event|
          line = event.payload.to_s
          lines << line << "\n"
          if event.payload && (md = match(line, rxs))
            event.subscription.unsubscribe
            promise.fulfill([true, lines, md, *args])
          end
        end
        yield
      end

      action.then do |id, success, *rest|
        s.unsubscribe
        next if promise.resolved?

        raise StandardError.new("action[#{name}] completed without result")
      end.rescue do |e, *rest|
        s.unsubscribe
        next if promise.resolved?

        promise.reject([e, *rest], false)
      end
    end
  end

  def safe_execute(&block)
    block.call
  rescue StandardError => e
    error "Exception: #{e.inspect}"
  end

end

