class Quest < Plugin

  set_deps('State', 'Caster', 'Assist')

  attr_reader :target_area

  def initialize(bot, *args, **kwargs)
    super
    # bot.scheduler.every(3.second) do
    # end
    @commands = []

    subscribe(State::STATE_BATTLE_EVENT) do
      @paused = true
    end

    subscribe(State::STATE_BATTLE_FINISHED_EVENT) do
      @paused = false
    end

    bot.scheduler.every(1.second) do
      next if @paused || deps[State].battle?

      if cmd = @commands.shift
        info "run cmd:#{cmd.name}"
        cmd.run
      end
    end
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

  KILL_QUEST_READY = 'kill_quest_ready'

  KILL_QUEST_RX = [/^Мастер (?<questor>.*) говорит тебе очень тихо:$/].freeze
  KILL_TARGET_RX = [
    /Может быть, ты (.*) про (?<target>[^.,'-?:]+)\?/m,
    /Надеюсь, (?<target>[^.,'-?:]+) не относится/m,
    /Есть так(.+)\.\.\.\s(?<target>[^.,'-?:]+)\..*/m,
    /Я говорю о\s+(?<target>[^.,'-?:]+)\./m
  ].freeze

  KILL_OBSERVE_RX = [
    /Тут есть только (?<next>\d+)?\ /,
    /Тут этого не видно(?<next>\d+)?/,
    /тот самый (.*), о котором говорил (.*)\!/,
    /ты нашёл (.*), (.*) искал по описанию (.*)/,
    /Очень похож на (.*), о (.*) говорил (,*)/
  ]

  KILL_TARGET2_RX = [
    /\d+\. (.*) готов заплатить за голову нек[^\ ]+(?<target>.*)/
  ].freeze

  KILL_AREA_RX = [
    /Это где-то в .*'(?<area>.*)'/m,
    /Советую поискать в '(?<area>.*)'/m,
    /Попробуй поспрашивать в '(?<area>.*)'/m
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
    #'Zoo of Midgaard' => {
    'zoo' => {
      run:   '6sesws',
      names: ['zoo', 'Zoo of Midgaard'],
      #run: '',
      track: 's;e;e(Вход в детскую секцию);e;n;s;e;n(В вольере)[D];n;w;e;s;s;s(Конюшня)[D]'
      #track: 'n;n;n'
    },
    'w' => {
      run:   '6e4s2es2ede',
      # run: 'sn',
      track: 'e;n;n;n;n;n;w;w;n;s;s;n;w;n;s;s;n;w;w'
      #track: 'w'
    },
    'b' => {
    run: '11w3s2e11s',
    track: 's;s;w;w;w;s;s;s;w'   
    },
    'nt' => {
      run: '16e',
      track: 'e;e;e;e;e;n;n;n;n;w;w;w;w;n;n[D];d[D];e[D];n[DL];s[DL];s[DL];n[DL];e;n[DL];s[DL];s[DL];n[DL];e;n[DL];s[DL];s[DL];n[DL];'
    },
    'anon' => {
      names: ['anon'],
      #run: '7w2s2w2s4w25s',
      run: '',
      track: 'w;w;s;s;e;e;e;e;e;n;n;w;n;w;e;s;e;e;e;n;n;d;u;s;s;e;e;e;e;e;n;n;d;u;s;s;w;w;w;w;w;w;w;s;s;s;s;w;w;w;s;s;e;'
    },
    'dn' => {
      names: ['dn'],
      #run: '7w2s2w2s4w25s',
      run: '',
      track: 'e;e;e;e;e;e;e;s;w;w;w;s;e;s;w;w;n;w;n;w;n;e;e;s;s;s;e;s;e;e;e;n;n;n'
    }
  }

  AREAS.instance_eval do
    def get name
      self.fetch(name.to_s) do
        n, _ = self.find do |k, area|
          area.fetch(:names, []).include?(name.to_s)
        end
        fetch(n || name.to_s)
      end
    end
  end

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

  Current = Struct.new('Current', :type, :area, :targets, :num) do
    def path
      self.area[:run]
    end

    def track
      self.area[:track]
    end

    def num!
      self.num += 1
    end
  end

  def kill area, target=@target, target2=@target2
    @target = target
    @target2 = target2
    run(area)
  end

  def kill2 area, target=@target, target2=@target2
    @target = target
    @target2 = target2
    run2(Current.new(:kill, AREAS.get(area), [target, target2], 0))
  end

  class Concurrent::Promises::ResolvableFuture
    def force p
      if p.is_a?(Concurrent::Promises::AbstractEventFuture)
        p.then{|a, *rest| puts "then:#{a}"; self.fulfill([a, *rest])}
        p.rescue{|a, *rest| puts "rescue:#{a}", self.reject([a, *rest])}
      else
        self.resolve(p)
      end
    end

    def attach future
      future.then{|a, *rest| self.fulfill([a, *rest], false)}
      future.rescue{|a, *rest| self.reject([a, *rest], false)}
      self
    end
  end

  def run2(current)
    runner = Concurrent::Promises.resolvable_future

    #сначала доходим до арии
    katka = runner.then do |current|
      post_command(:run) do |cmd|
        await_action("run_#{current.path.inspect}", duration: 30.seconds) do
          send("run #{current.path}")
        end
      end.promise
    end.flat

    # теперь выслеживаем моба
    katka = katka.then do
      post_command(:track) do |cmd|
        track_mob(current)
      end.promise
    end.flat

    katka = katka.then do |mob, *rest|
      info "ATACK:#{mob}.#{target}"
    end

    katka.rescue do |e, *rest|
      warn "Area failed: #{e.inspect} #{rest}"
    end

    runner.fulfill(current)
  end


  def track_mob(current)
    Concurrent::Promises.resolvable_future.tap do |promise|
      @track = current.track.split(';').map(&:strip).select(&:presence)
      make_next_step(current, promise)
    end
  end

  def make_next_step current, promise
    if @track.empty?
      return promise.reject(StandardError.new("Track is empty!"))
    end
    make_step(current, Step.new(@track.shift), promise)
  rescue => e
    error e.inspect
  end

  def make_step(current, step, promise)
    num = current.num!
    action = post_command("move_#{num}") do |cmd|
      await_action("step_#{step.dir}_#{num}") do
        send("pick #{step.dir}") if step.lock?
        send("unlock #{step.dir}") if step.lock?
        send("open #{step.dir}") if step.door?
        send("#{step.dir}")
      end.tap do |a|
        a.rescue do |ex,*rest|
          warn("make_step[#{step}] failed1: #{ex} #{args}")
        end
      end
    end


    action = action.then_cmd(:control) do |cmd|
      if step.name
        do_control(step) 
      else
        Concurrent::Promises.fulfilled_future(step)
      end
    end

    action = action.then_cmd(:observe) do |cmd|
      @target = current.targets.first
      @target2 = current.targets.last
      do_observe_kill
    end


    action = action.then_cmd(:decision) do |cmd, mob, *rest|
      if mob
        promise.fulfill([mob, *rest])
      else
        info "There is no target"
        make_next_step(current, promise)
      end
    end

    promise.attach(action.promise)
  end
  






  def run(area)
    @area = AREAS[area]
    await_action("run_#{@area[:run].inspect}", duration: 30.seconds) do
      send("run #{@area[:run]}")
    end.then do |id, success, *rest|
      start_track
    end.flat.then do |mob, *rest|
      info "ATACK:#{mob}.#{target}"
    end.rescue do |e, *rest|
      warn "Area failed: #{e.inspect}"
    end
  end

  def start_track
    Concurrent::Promises.resolvable_future.tap do |promise|
      @num = 0
      @track = @area[:track].split(';').map(&:strip).select(&:presence)
      next_step(promise)
    end
  end

  def next_step promise
    if @track.empty?
      return promise.reject(StandardError.new("Track is empty!"))
    end
    do_step(Step.new(@track.shift), promise)
  end

  def do_step(step, promise)
    @num += 1
    @current = step
    action = await_action("step_#{@current.dir}_#{@num}") do
      send("pick #{@current.dir}") if @current.lock?
      send("unlock #{@current.dir}") if @current.lock?
      send("open #{@current.dir}") if @current.door?
      send("#{@current.dir}")
    end.rescue do |ex,*rest|
      warn("do_step[#{step}] failed1: #{ex} #{args}")
    end

    action.then do |id, success, *rest|
      if @current.name
        do_control(step) 
      else
        Concurrent::Promises.fulfilled_future(step)
      end
    end.flat.then do
      do_observe_kill
    end.flat.then do |mob, *rest|
      if mob
        promise.fulfill(mob, *rest)
      else
        next_step(promise)
      end
    end.rescue do |ex, *rest|
      warn("do_step[#{step}] failed2: #{ex.inspect} #{rest}")
      promise.reject([StandardError.new("do_step[#{step}] failed2: #{ex.inspect}"), *rest])
    end
  end

  def do_control step
    await_line("control_#{step.dir}_#{@num}", /#{step.name}/, duration: 5.seconds) do
      send('look')
    end.then do
      step
    end.rescue do |ex, *rest|
      raise StandardError.new("do_control[#{step}] failed: #{ex.inspect} #{rest}")
    end
  end

  def do_observe_kill
    iterate_mobs(1, KILL_OBSERVE_RX).then do |mob, *rest|
      info("Kill Target observed: #{mob}.#{target}") if mob
      mob
    end
  end

  def iterate_mobs mob = 1, rxs
    Concurrent::Promises.resolvable_future.tap do |promise|
      if mob >= 6
        promise.fulfill(false)
        return promise 
      end

      action = await_line("look_mob_#{mob}", rxs) do
        send("look #{mob}.#{target}" )
      end
      
      action.rescue do |ex, *rest|
        iterate_mobs(mob + 1, rxs)
      end.flat.then do |a, *rest|
        promise.fulfill([a, *rest])
      end
      
      action.then do |success, _lines, md, args|
        if md && md.named_captures.has_key?('next')
          promise.fulfill(false)
        else
          promise.fulfill(mob)
        end
      end
    end
  end

  class Command
    attr_accessor :promise, :name, :block
    def initialize(name, commands:, promise: Concurrent::Promises.resolvable_future, &block)
      @name = name
      @promise = promise
      @block = block
      @commands = commands
    end

    def run
      @block.call(self).tap do |result|
        if result.is_a?(Concurrent::Promises::AbstractEventFuture)
          promise.attach(result)
        end
      end
    end

    def then &block
      promise.then(&block)
    end

    def rescue &block
      promise.rescue(&block)
    end

    def then_cmd(name, &block)
      Command.new(name, commands: @commands).tap do |cmd|
        self.then do |a, *rest|
          cmd.block = Proc.new do |cmd|
            block.call(cmd, a, *rest)
          end
          @commands << cmd
        end
      end
    end 

    def rescue_cmd(*args, &block)
      Command.new(name, commands: @commands).tap do |cmd|
        self.rescue do |a, *rest|
          cmd.block = Proc.new do |cmd|
            block.call(cmd, a, *rest)
          end
          @commands << cmd
        end
      end
    end 
  end

  def post_command name
    Command.new(name, commands: @commands) do |cmd|
      yield(cmd)
    end.tap{ |cmd| @commands << cmd }
  end

  
  def target
    @target.presence || @target2.presence || 'mob'
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
},
%{
# Ты здороваешься с мастером гильдии Воинов.
Мастер гильдии Воинов говорит тебе очень тихо: 
- Есть одно дельце для тебя. Я говорю о вожде кентавров. Не хочу, чтобы ты
перепутал,- подробно описывает внешность,-  Попробуй поспрашивать в 'Wyvern's
Tower'. По слухам, за его голову (или другое доказательство смерти) обещают
награду.
}
  ]



end

