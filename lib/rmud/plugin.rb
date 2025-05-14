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

  def subscribe(_event, &)
    @subscriptions << bot.bus.subscribe do |e|
      yield(e)
    rescue StandardError => e
      error(e.inspect)
    end
    @subscriptions.last
  end

  def unsubscribe(s)
    bot.bus.unsubscribe(s)
    @subscriptions.delete(s)
  end

  def subscribe_once(event)
    subscribe(event) do |*args, **kwargs|
      unsubscribe(s)
      yield(*args, **kwargs)
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
          unsubscribe(s)
          promise.fulfill([id, true, *args])
        end
      end
      bot.scheduler.after duration do
        unsubscribe(s)
        promise.reject([id, false, *args], false)
      end
      yield
      send("gtel #{id}:completed")
    end
  end

  def await_line name, rxs, *args, duration: 60.seconds
    Concurrent::Promises.resolvable_future.tap do |promise|
      lines = ''
      s = nil
      a = await_action(name, duration: duration) do
        s = subscribe(::RMud::Bot::LINE_EVENT) do |event|
          line = event.payload.to_s
          lines << line << "\n"
          if event.payload && (md = match(line, rxs))
            unsubscribe(s)
            promise.fulfill([true, lines, md, *args])
          end
        end
        yield
      end

      a.then do |id, *rest|
        unsubscribe(s)
        next if promise.resolved?

        warn("await_line action[#{id}] rejected: #{rest.inspect}")
        promise.fulfill([false, lines, nil, *args], false)
      rescue StandardError => e
        error("Exception in action result: #{e.inspect}")
      end

      a.rescue do |e, *rest|
        unsubscribe(s)
        next if promise.resolved?

        error("await_line action[#{e}] failed: #{rest.inspect}")
        promise.reject([false, lines, nil, *args], false)
      rescue StandardError => e
        error("Exception in action rescuing: #{e.inspect}")
      end
    end
  end

  def safe_execute(&block)
    block.call
  rescue StandardError => e
    error "Exception: #{e.inspect}"
  end

end

