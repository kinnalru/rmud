require 'concurrent/promise'

class Caster < Plugin

  Action = Struct.new('Action', :type, :action, :target, :promise) do
    def initialize(*args)
      super
      @created_at = Time.now
    end

    def skill?
      type == :skill
    end

    def spell?
      type == :spell
    end

    def start!
      @started_at = Time.now
    end

    def name
      action[:name]
    end

    def elapsed
      @started_at ? Time.now - @started_at : 0
    end

    def success?(line)
      action[:success]&.any? do |pattern|
        if pattern.is_a?(String)
          line.start_with?(pattern.strip)
        else
          pattern.match(line)
        end
      end
    end

    def failed?(line)
      action[:failure]&.any? do |pattern|
        if pattern.is_a?(String)
          line.start_with?(pattern.strip)
        else
          pattern.match(line)
        end
      end
    end
  end

  def initialize(bot, *args, **kwargs)
    super

    @queue = []
    bot.scheduler.every(1.second) do
      completed(0) if @current && @current.elapsed > 7
    end
  end

  def cast(spell, target = nil)
    s = (@queue << Action.new(:spell, C7i::SPELLS.fetch(spell), target, Concurrent::Promises.resolvable_future)).last
    trynext
    s.promise
  end

  def skill(skill, target = nil)
    s = (@queue << Action.new(:skill, C7i::SKILLS.fetch(skill), target, Concurrent::Promises.resolvable_future)).last
    trynext
    s.promise
  end

  def completed(result = 1)
    @casting = false
    info("completed #{@current.name} on #{@current.target.inspect}")
    @current.promise.fulfill(result)
    @current = nil
    trynext
  end

  def trynext
    return if @casting

    @current = @queue.shift
    return unless @current

    @casting = true
    info("casting #{@current.name} on #{@current.target.inspect}")
    @current.start!
    if @current.skill?
      send("#{@current.name} #{@current.target}".strip)
    elsif @current.spell?
      send("c '#{@current.name}' #{@current.target}".strip)
    else
      error("unknown Action #{@current.type.inspect}")
    end
  end

  def process(line)
    return unless @casting

    if @current.success?(line)
      completed(1)
    elsif @current.failed?(line)
      completed(0)
    end
  rescue StandardError => e
    error("Exception: #{e.inspect}")
  end


end

