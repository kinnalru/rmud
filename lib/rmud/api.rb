module RMud
  module Api
    class TinTin

      def initialize(bot: bot)
        @bot = bot
      end

      def echo(msg)
        @bot.conn.write "#showme {rmud#{msg}}"
      end

      def info(msg)
        echo("[#{'INFO'.cyan}] #{msg}")
      end

      def error(msg)
        echo("[#{'ERROR'.red}] #{msg}")
      end

    end

    class Mudlet
      def initialize(bot: bot)
        @bot = bot
      end

      def transmit(line)
        @bot.conn.write "#{line};"
        @bot.conn.write "" 
      end

      def init
        transmit('')
        script = "
if exists('rmud', 'trigger') == 0 then
  permGroup('rmud', 'trigger');
end

if exists('rmud_capture', 'trigger') == 0 then
  permRegexTrigger('rmud_capture', 'rmud', {'(.*)'}, [[rmud.send(matches[1] .. '\\n');]]);
end

if exists('rmud', 'alias') == 0 then
  permGroup('rmud', 'alias');
end

if exists('rmud_cmd', 'alias') == 0 then
  permAlias('rmud_cmd', 'rmud', '^rmud (.*)$', [[rmud.send(matches[1] .. '\\n');]]);
end
"
        info("Initializing objects...")
        transmit "#{script}"
        info("Initialized")
      end

      def echo(msg)
        transmit "decho(ansi2decho('rmud#{msg}\\n'))"
      end

      def info(msg)
        echo("[#{'INFO'.cyan}] #{msg}")
      end

      def error(msg)
        echo("[#{'ERROR'.red}] #{msg}")
      end


    end
  end
end

