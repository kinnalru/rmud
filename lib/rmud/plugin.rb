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

  def status(*args)
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
    @subscriptions << bot.bus.subscribe(event, &)
  end

end

