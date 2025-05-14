class Quest < Plugin

  set_deps('State', 'Caster', 'Assist')

  def initialize(bot, *args, **kwargs)
    super
    # bot.scheduler.every(3.second) do
    # end
  end

  def status
    info("Quest:\n#{@quest.to_s.light_white}")
    info("Target:#{@target.to_s.light_red} Target2:#{@target2.to_s.red} Area:#{@area.to_s.light_yellow}")
  end

  def begin_kill(questor)
    @questor = questor
    warn("begin_kill[#{@questor}]")

    @kill_start = true
    @quest = ''
    @target = nil
    @target2 = nil

    collector = subscribe(::RMud::Bot::LINE_EVENT) do |event|
      @quest += "#{event.payload}\n" if @kill_start
    end

    subscribe_once(State::STATE_PROMPT_EVENT) do
      warn("begin_kill[#{@questor}] prompt once")
      unsubscribe(collector)
      end_kill(@quest) if @kill_start
    end
  end

  def end_kill(text)
    return unless @kill_start

    @kill_start = false

    if (md = match(text, KILL_TARGET_RX))
      @target = md[:target][0..-2]
    end

    if (md = match(text, KILL_AREA_RX))
      @area = md[:area]
    end

    status
    send('quest info')
  end

  KILL_QUEST_RX = [/^Мастер (?<questor>.*) говорит тебе очень тихо:$/].freeze
  KILL_TARGET_RX = [
    /Может быть, ты (.*) про (?<target>.*)\?/m,
    /Надеюсь, (?<target>.*) не относится/m,
    /Есть так(.+)\.\.\.\s(?<target>[^.,'-?:]+)\..*/m,
    /Я говорю о\s+(?<target>)\./m
  ].freeze

  KILL_TARGET2_RX = [
    /\d+\. (.*) готов заплатить за голову нек[^\ ]+(?<target>.*)/
  ].freeze

  KILL_AREA_RX = [
    /Это где-то в .*'(?<area>.*)'/m,
    /Советую поискать в '(?<area>)'К/m
  ].freeze

  # Очень похож на степного волка, о котором говорил мастер гильдии Воинов.

  def process(line)
    if (md = match(line, KILL_QUEST_RX))
      begin_kill(md[:questor])
    elsif (md = match(line, KILL_TARGET2_RX))
      info(md)
      @target2 = md[:target][0..-2]
      status
    end
  rescue StandardError => e
    error(e.inspect)
  end


  AREAS = {
    'Zoo of Midgaard' => {
      run:   '6sesws',
      # run: 'sn',
      track: 's;e;e(Вход в детскую секцию);e;n;s;e;n(В вольере)[D];n;w;e;s;s;s(Конюшня)[D]'
    }
  }


  DEFINITION_RX = /(?<direction>.)(\((?<name>.*)\))?(\[(?<door>D)*(?<lock>L)*\])?/
  Step = Struct.new('Step', :definition, :door, :lock, :name) do
    attr_reader :dir

    def initialize(definition, *args)
      super
      @definition = definition
      md = DEFINITION_RX.match(@definition)
      @dir = md[:direction]
      self.door = true if md[:door] || md[:lock]
      self.lock = true if md[:lock]
      self.name = md[:name]
    end

    def lock?
      lock
    end

    def door?
      door
    end
  end

  def run(area)
    @area = AREAS[area]
    send("run #{@area[:run]}")
  end

  def track
    @num = 0
    @track = @area[:track].split(';')
    if @track.empty?
      info 'Empty track'
      return
    end
    do_step(Step.new(@track.shift))
  end

  def do_step(step)
    @num += 1
    @current = step
    action = await_action("step_#{@current.dir}_#{@num}") do
      send("pick #{@current.dir}") if @current.lock?
      send("unlock #{@current.dir}") if @current.lock?
      send("open #{@current.dir}") if @current.door?
      send("#{@current.dir}")
    end

    action.then do |_id, _success, *_args|
      if @current.name
        safe_execute do
          do_control.then do |success, *_rest|
            raise "Control #{@current.name} failed" unless success

            safe_execute{ do_observe }
          end.rescue do |*args|
            error "track failed: #{args}"
          end
        end
      else
        safe_execute{ do_observe }
      end
    end.rescue do |*args|
      info("do_step[#{step}] failed: #{args}")
    end
  end

  def do_control
    await_line("control_#{@current.dir}_#{@num}", /#{@current.name}/, duration: 5.seconds) do
      send('look')
    end
  end

  def do_observe
    action = await_line("observe_#{@current.dir}_#{@num}", /разные подковы и кожаные снасти крепко/,
      duration: 5.seconds) do
      send('look')
    end

    action.then do |success, _lines, md, _args|
      if success
        info("COMPLETED: #{md}")
      else
        do_step(Step.new(@track.shift))
      end
    end.rescue do |*args|
      info("do_observe failed: #{args}")
    end
  end


  # Ты даёшь мозги гориллы мастеру гильдии Воинов.
  # Мастер гильдии Воинов говорит тебе 'горилла мертва? Давно бы так...'

  # За успешно выполненное задание ты получаешь награду:
  # 8 квестовых очков, 11 золотых.
  # 86 очков опыта.

  # Ты даёшь внутренности лягушки мастеру гильдии Воинов.
  # Мастер гильдии Воинов говорит тебе 'О покойниках - или хорошо, или ничего. Почтим
  # лягушку минутой молчания!'

  # За успешно выполненное задание ты получаешь награду:
  # 15 квестовых очков, 18 золотых.
  # 55 очков опыта.



  TEST = [
    %(
    # # Ты здороваешься с мастером гильдии Воинов.
    # Мастер гильдии Воинов говорит тебе очень тихо:
    # - Кое-кому не суждено прожить долгую жизнь. Надеюсь, горилла не относится к числу
    # твоих друзей? Она выглядит так,- у тебя в голове вдруг появляется яркий образ,-
    # Это где-то в 'Zoology museum'. Кое-кто будет рад получить доказательства её
    # смерти.
    ),
    %(
    # # Ты здороваешься с мастером гильдии Воинов.
    # Мастер гильдии Воинов говорит тебе очень тихо:
    # - Ищешь работу, не так ли? Надеюсь, слон не относится к числу твоих друзей? Особые
    # приметы..., - перечисляет их. -  Это где-то в районе 'Zoo of Midgaard'. Было бы
    # весьма отрадно узнать о его смерти. Правда, на слово я не поверю.
    ),
    %(
  # # Ты здороваешься с мастером гильдии Воинов.
  # Мастер гильдии Воинов говорит тебе очень тихо:
  # - Кое-кто крайне... крайне недоволен кое-кем. Есть такой... неандерталец. Особые
  # приметы..., - перечисляет их. -  Это где-то в 'Firetop Mountain'. Было бы весьма
  # отрадно узнать о его смерти. Правда, на слово я не поверю.
    ),
    %(
    # Ты здороваешься с мастером гильдии Воинов.
    Мастер гильдии Воинов говорит тебе очень тихо:
    - Кое-кому не суждено прожить долгую жизнь. Надеюсь, детёныш подземной куницы не
    относится к числу твоих друзей? Особые приметы..., - перечисляет их. -  Попробуй
    поспрашивать в 'Deepearth'. Было бы весьма отрадно узнать о его смерти. Правда, на
    слово я не поверю.
    ),
    %{
# Ты здороваешься с мастером гильдии Воинов.
Мастер гильдии Воинов говорит тебе очень тихо:
- Кое-кому не суждено прожить долгую жизнь. Может быть, ты слышал про уродливого
мишку? Не хочу, чтобы ты перепутал,- подробно описывает внешность,-  Это где-то в
'Dwarven Day Care'. По слухам, за его голову (или другое доказательство смерти)
обещают награду.
    },
    %(
Мастер гильдии Воинов говорит тебе очень тихо:
- Кое-кто крайне... крайне недоволен кое-кем. Надеюсь, оживлённый скелет не
относится к числу твоих друзей? Тут у меня случайно завалялся рисунок,-
показывает тебе его и прячет куда-то,-  Советую поискать в 'High Tower of
Sorcery'. Было бы весьма отрадно узнать о его смерти. Правда, на слово я не
поверю.
),
    %{
Мастер гильдии Воинов говорит тебе очень тихо:
- Есть одно дельце для тебя. Есть такая... драчливая рыба. Тут у меня случайно
завалялся рисунок,- показывает тебе его и прячет куда-то,-  Это где-то в 'Southern
Road'. По слухам, за её голову (или другое доказательство смерти) обещают
награду.
}
  ]



end

