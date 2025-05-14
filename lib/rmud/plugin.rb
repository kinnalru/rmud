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
    @subscriptions << bot.bus.subscribe do |e|
      yield(e)
    rescue => e
      error(e.inspect)
    end
    @subscriptions.last
  end

  def unsubscribe(s)
    bot.bus.unsubscribe(s)
    @subscriptions.delete(s)
  end

  def subscribe_once(event)
    s = subscribe(event) do |*args, **kwargs|
      unsubscribe(s)
      yield(*args, **kwargs)
    end
    s
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

end

