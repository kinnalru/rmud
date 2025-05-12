class Quest < Plugin

  set_deps('State', 'Caster', 'Assist')

  def initialize(bot, *args, **kwargs)
    super


    bot.scheduler.every(3.second) do
      
    end

    subscribe(State::STATE_PROMPT_EVENT) do
      if @kill_start
        end_kill
      end
    end
  end

  def begin_kill
    @kill_start = true
    @quest = ""
  end

  text = "
# Ты здороваешься с мастером гильдии Воинов.
Мастер гильдии Воинов говорит тебе очень тихо: 
- Ищешь работу, не так ли? Может быть, ты слышал про лягушку? Тут у меня случайно
завалялся рисунок,- показывает тебе его и прячет куда-то,-  Это где-то в районе
'Delta'. У меня есть мечта: посмотреть на того, кто её замочит... и подтвердит это
чем-нибудь.
"

  RX1 = /Может быть, ты (.*) про (?<target>.*)\?/m
  RX1_1 = /Есть одно дельце для тебя\. Я говорю о (target?<>.*)\. /
  RX2 = /Это где-то в районе.*'(?<area>.*)'.*/m
  RX2_1 = /Это где-то в .*'(?<area>.*)'.*/m

  def collect_kill line
    return unless @kill_start

    @quest += "#{line}\n"
  end

  def end_kill
    return unless @kill_start

    @kill_start = false
    if md = RX1.match(line)
      info(md)
      @target = md[:target][0..-2]
    end
    if md = RX2.match(line)
      info(md)
      @area = md[:area]
    end

    info "QUEST: kill #{@target}(#{@target2}) from #{@area}"
    send('q info')
  end

  RX_Q=/\d+\. (.*) готов заплатить за голову некой (?<target>.*)/

# # Ты здороваешься с мастером гильдии Воинов.
# Мастер гильдии Воинов говорит тебе очень тихо: 
# - Есть одно дельце для тебя. Я говорю о моряке. Тут у меня случайно завалялся
# рисунок,- показывает тебе его и прячет куда-то,-  Это где-то в 'The City of Anon'.
# Было бы весьма отрадно узнать о его смерти. Правда, на слово я не поверю.

#                                   .
#Твой колющий удар сильно ранит лягушку!
#Твой колющий удар сильно задевает лягушку.
#Ты получаешь 99 очков опыта.
#Брызги крови лягушки попадают на тебя.
#Кишки лягушки вываливаются наружу.
#Лягушка падает... и УМИРАЕТ.

# Ты даёшь внутренности лягушки мастеру гильдии Воинов.
# Мастер гильдии Воинов говорит тебе 'О покойниках - или хорошо, или ничего. Почтим
# лягушку минутой молчания!'

# За успешно выполненное задание ты получаешь награду:
# 15 квестовых очков, 18 золотых.
# 55 очков опыта.

  def process(line)
    if line == 'Мастер гильдии Воинов говорит тебе очень тихо:'
      begin_kill
    elsif @kill_start
      collect_kill(line)
    elsif md = RX_Q.match(line)
      info(md)
      @target2 = md[:target][0..-2]
      info "QUEST2: kill #{@target}(#{@target2}) from #{@area}"
    end
  end






end

