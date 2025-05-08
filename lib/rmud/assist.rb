class Assist < Plugin

  def initialize(bot, *args, **kwargs)
    @features = {}
    super
    bot.scheduler.every(3.second) do
      check_health rescue nil
      trip rescue nil
    end

    subscribe(State::STATE_HP_LOW_EVENT) do
      check_health
    end
  end

  def battle?
    deps[State].battle?
  end

  def low_hp?
    deps[State].hp.low?
  end

  def critical_hp?
    deps[State].hp.critical?
  end

  set_deps('State', 'Caster')

  def process(line); end

  def enable(feature, *)
    self.__send__("enable_#{feature}", *)
  end

  def disable(feature, *)
    self.__send__("disable_#{feature}", *)
  end

  def enable_trip *_args
    info('enable tripe')
    @features[:trip] = true
  end

  def disable_trip *_args
    @features[:trip] = false
  end

  def trip
    #info("Tripping...#{@features} #{@features[:trip]} #{battle?} #{!low_hp?}")
    return if !@features[:trip] || !battle? || low_hp?
    return if @triping ||  @healing

    info("Feaures:#{@features}. B[#{battle?}] L[#{low_hp?}]")

    @triping = true
    deps[Caster].skill(:trip).then do |_r|
      @triping = false
    end
  end

  def check_health
    if deps[State].hp.value <= 90
      #info("HP <= 90 HEAL")
      heal 
    else
      #info("...HP > 90 skip...")
    end
  end

  def heal
    return if @healing

    @healing = true

    deps[Caster].cast(:cure_light).then do |_r|
      @healing = false
    end
  end

end

