class TrainSpell < Plugin

SPELLS = ::C7i::SPELLS


#Ты улучшаешь своё умение cure light.
#Ты теперь в совершенстве знаешь cure light!

  AFFECTS_SPELL_RX_PATTERN = "\\s*(?<spell>SPELL)\\s+(?<level>\\d+)%,\s+(?<cost>\\d+)"
  # AFFECTS

  # EMAIL_RX = URI::MailTo::EMAIL_REGEXP
  # LOGIN_RX = /\A[A-Z0-9_]+\z/i.freeze
  # FULL_RX = /(?<email>#{EMAIL_RX})|(?<login>#{LOGIN_RX})/.freeze

  set_deps('State')

  def initialize(bot, spell, *args, **kwargs)
    @spell = spell.to_s.strip.to_sym
    super
    info(2)

    @current = SPELLS.fetch(@spell)
    info(3)
    @stats = {}

    info(4)
    start
  end

  TEXT = '


Level  1: armor              100%,   1 mana   magic missile      100%,   1 mana
          ventriloquate        1%,   1 mana
Level  2: detect magic        92%,   1 mana
Level  3: cure light         100%,   1 mana   detect invis         1%,   1 mana
Level  4: chill touch         17%,   1 mana   floating disc        1%,   3 mana
          shield             100%,   1 mana
Level  5: faerie fire        100%,   1 mana   invisibility         1%,   1 mana
Level  6: continual light     57%,   1 mana
Level  7: burning hands       24%,   1 mana
Level  8: bless                7%,   1 mana   create water         1%,   1 mana
          cure blindness       1%,   1 mana   refresh              1%,   1 mana
          remove splinters     1%,   1 mana

'

  def parse_all text
    spell_rx = Regexp.new(AFFECTS_SPELL_RX_PATTERN.gsub('SPELL', '[^:,\d]+').strip, Regexp::MULTILINE)
    text.split('mana').map(&:strip).compact.map do |line|
      puts "LINE:#{line.inspect}"
      md = spell_rx.match(line)
      info(md.inspect)
      md
    end.compact.map{|md| md.named_captures.transform_values{|v| v.strip}}
  end

  def parse(spell, text)
    spell_rx = Regexp.new(AFFECTS_SPELL_RX_PATTERN.gsub('SPELL', spell.to_s.strip).strip)
    line_rx = Regexp.new("#{spell_rx}")
    text.split("\n").map do |line|
      line_rx.match(line)
    end.compact.first
  end

  def start
    info(5)
    bot.bus.subscribe(State::SPELL_STATE_EVENT) do |event|
      if event.payload[:spell] == @current[:name] && event.payload[:level].to_i == 100
        completed
      end
    end

    info(6)
    bot.bus.subscribe(State::SPELL_STATE_FINISHED_EVENT) do |event|
      cast
    end

    bot.notify(State::REFRESH_SPELL_STATE_EVENT)
  end

  def completed
    info("COMPLETED: #{@current}")
    @current = nil
  end

  def cast
    send("cast '#{@current[:name]}'")
    @waiting = true
  rescue StandardError => e
    info("3:#{e}")
  end

  def process(line)
    return unless @current

    if (md = parse(@current[:name], line))
      @waiting = false

      @stats[@current[:name]] ||= {}
      level = @stats[@current[:name]][:level] = md['level'].to_i
      if level == 100
        completed
      else
        cast
      end
    elsif @current[:success].any?{|s| s.strip == line.strip }
      @waiting = false

      cast
    elsif @waiting && line.strip == 'Ты не смог сосредоточиться.'
      cast
    elsif line.strip == "Ты теперь в совершенстве знаешь #{@current[:name]}!"
      completed
    end
  end

end

