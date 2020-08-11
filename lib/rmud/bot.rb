require 'colorize'
module RMud
  class Bot
    attr_reader :conn, :scheduler, :api

    CMD_RX = /\Armud[\ ]+(?<cmd>[^\ ]+)[\ ]*(?<args>.*)\Z/

    def initialize(conn, api_class: RMud::Api::TinTin)
      @conn = conn

      o = Output.new(self, name: 'c7i')
      @conn.on_line do |line|
        o.process(line)
      end

      @scheduler = Scheduler.new
      @api = api_class.new(bot: self)

      @conn.on_line do |line|
        puts "process #{line.inspect}"
        File.write("/tmp/full.log", line + "\n", mode: "a")
        process(line)

        "WRITTEN #{line}"
      end
    end

    def start(block: false)
      @conn.start
      @scheduler.after(1.second) do
        api.info("Started")
      end

      @scheduler.every(5.second) do
        api.info("p".light_white + "i".red + "n".light_black + "g".light_red)
      end
      wait if block
    end

    def stop
      @conn.stop
    end

    def stopped?
      @conn.stopped?
    end

    def wait
      @conn.wait
    end

    def process line
      if md = CMD_RX.match(line)
        args = md[:args].split(/\ ;\|/)

        puts "COMMAND: [#{md[:cmd]}], args: #{args.inspect}"
      end
    end



    class Obcast
      attr_reader :bot, :current_spell
      def initialize bot
        @bot = bot
        @spell = {
          stoneskin: ['твоя кожа покрывается', 'каменеет']
        }

        # [:stoneskin, :armor]
        # @current_spell
        @delayed = nil
      end

      def cast spell
        bot.send("cast #{spell}")
      end

      def process line
        if current_data.include?(line)
          current_spell = next1
        elsif line == 'не удалось'
          @delayed = bot.scheduler.after 2.seconds do 
            cast(current_spell)
          end
        end
      end

      def current_data
        spells[current_spell]
      end
    end


  end
end