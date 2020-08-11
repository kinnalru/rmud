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

    class Mudler
      def initialize(bot: bot)
        @bot = bot
      end

      def echo(msg)
        @bot.conn.write "decho(ansi2decho('rmud#{msg}'));"
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

