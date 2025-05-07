class TrainSpell < Plugin

  SPELLS = {
    armor:      {
      name:    'armor',
      success: ['Hа тебе уже есть магическая защита.', 'Ты чувствуешь, как что-то защищает тебя.']
    },
    cure_light: {
      name:    'cure light',
      success: ['Ты уже здоров, как бык.']
    }
  }


#Ты улучшаешь своё умение cure light.
#Ты теперь в совершенстве знаешь cure light!

  AFFECTS_SPELL_RX_PATTERN = "\\s*(?<spell>SPELL)\\s+(?<level>\\d+)%,\s+(?<cost>\\d+)"
  # AFFECTS

  # EMAIL_RX = URI::MailTo::EMAIL_REGEXP
  # LOGIN_RX = /\A[A-Z0-9_]+\z/i.freeze
  # FULL_RX = /(?<email>#{EMAIL_RX})|(?<login>#{LOGIN_RX})/.freeze

  def initialize(bot, spell, *args, **kwargs)
    @spell = spell.to_s.strip.to_sym
    super

    @current = SPELLS.fetch(@spell)
    @stats = {}

    start
  end

  TEXT = '

Level  1: armor              100%,   1 mana   magic missile      100%,   1 mana
          ventriloquate        1%,   1 mana
Level  2: detect magic         1%,   1 mana
Level  3: cure light         100%,   1 mana   detect invis         1%,   1 mana
Level  4: chill touch         недоступно      floating disc       недоступно   
          shield              недоступно   
Level  5: faerie fire         недоступно      invisibility        недоступно   
Level  6: continual light     недоступно   
Level  7: burning hands       недоступно   
Level  8: bless               недоступно      create water        недоступно   
          cure blindness      недоступно      refresh             недоступно   
          remove splinters    недоступно   
Level  9: detect poison       недоступно      infravision         недоступно   
          locate object       недоступно      recharge            недоступно   
Level 10: create food         недоступно      create rose         недоступно   
          cure serious        недоступно      fly                 недоступно   
          shocking grasp      недоступно      sleep               недоступно   
Level 11: detect alignment    недоступно      giant strength      недоступно   
          protection evil     недоступно      protection good     недоступно  
'

  def parse_all text
    spell_rx = Regexp.new(AFFECTS_SPELL_RX_PATTERN.gsub('SPELL', '[^:,\d]+').strip, Regexp::MULTILINE)
    text.split('mana').map(&:strip).compact.map do |line|
      puts "LINE:#{line.inspect}"
      md = spell_rx.match(line)
      puts md
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
    send('spells')
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
        info('CAST')
        cast
      end
    elsif @current[:success].any?{|s| s.strip == line.strip }
      @waiting = false

      cast
    elsif @waiting && line.strip == 'Ты не смог сосредоточиться.'
      cast
    end
  end

end

