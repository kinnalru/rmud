class Plugin

  attr_reader :bot, :args, :kwargs

  def initialize(bot, *args, **kwargs)
    @bot = bot
    @args = args
    @kwargs = kwargs
    info('activated')
  end

  def process(_line)
    raise NotImplementedError.new("#{self.class}##{__method__}")
  end

  def send(command)
    bot.api.send(command)
  end

  def info(msg)
    bot.api.info("[#{self.class}]: #{msg}")
  end

end

