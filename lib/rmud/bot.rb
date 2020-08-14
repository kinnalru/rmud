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

      @plugins = {}
      @scheduler = Scheduler.new
      @api = api_class.new(bot: self)

      @conn.on_line do |line|
        puts "process #{line.inspect}"
        File.write("/tmp/full.log", line + "\n", mode: "a")
        process(line)
      end
    end

    def start(block: false)
      @conn.start
      @scheduler.after(1.second) do
        api.init()
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
        cmd = md[:cmd]
        args = md[:args].split(/[\ ,;\|]/).select(&:present?)
        puts "COMMAND: [#{cmd}], args: #{args.inspect}"

        if cmd == 'plugin'
          plugin(args.shift, args)
        end
      end
    rescue => e
      api.error(e.inspect)
    end

    def plugin name, params
      class_name = name.classify
      if klass = class_name.safe_constantize || "RMud::#{class_name}".safe_constantize
        if p = @plugins[klass.to_s + params.to_s]
          raise "Plugin [#{klass.to_s}] already started with #{params.to_s}"
        else
          klass.new(self, *params).tap do |p|
            @plugins[klass.to_s + params.to_s] = p
            @conn.on_line do |line|
              p.process(line)
            end
          end
          api.info("Plugin [#{klass.to_s}] started")
        end

      else
        raise "Unknown plugin #{name}"
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