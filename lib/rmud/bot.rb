require 'colorize'
module RMud

  class Log

    def initialize(id)
      @log = File.open("./#{id}.log", 'w+')
      @log.sync = true

      @botlog = File.open("./#{id}.bot.log", 'w+')
      @botlog.sync = true
    end

    def input(string)
      write(@log, string, 'INPUT')
      string
    end

    def output(string)
      write(@log, string, 'OUTPUT')
      string
    end

    def info(string)
      write(@log, string, 'INFO')
      @botlog.puts string
      string
    end

    def write io, msg, *tags
      t = tags.map{|t| "[#{t}]" }.join
      io.puts("[#{Time.now}]#{t}: #{msg}")
    end

  end

  class Bot

    attr_reader :conn, :log, :scheduler, :api, :bus

    CMD_RX = /\Armud[\ ]+(?<cmd>[^\ ]+)[\ ]*(?<args>.*)\Z/

    def initialize(conn, log:, api_class: RMud::Api::TinTin)
      @conn = conn
      @log = log
      @bus = ActiveSupport::Notifications

      o = Output.new(self, file: "#{conn.id}_tells.log")
      @conn.on_line do |line|
        o.process(line)
      end

      @plugins = {}
      @scheduler = Scheduler.new
      @api = api_class.new(bot: self)

      @conn.on_line do |line|
        File.write('/tmp/full.log', line + "\n", mode: 'a')
        process(line)
      end
    end

    def notify(event, payload = nil)
      log.info("NOTIFY:#{event}")
      bus.instrument(event, payload)
    end

    def start(block: false)
      log.info('Starting...')
      @conn.start
      @scheduler.after(1.second) do
        api.init
      end
      @scheduler.every(5.second) do
        # api.info("p".light_white + "i".red + "n".light_black + "g".light_red)
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

    def plugin_command!(cmd, *args)
      api.info(cmd)
      if (p = @plugins[find_plugin(cmd).to_s])
        api.info("#{p}.send(#{args})")
        p.__send__(*args)
        true
      end
    end

    def process(line)
      if (md = CMD_RX.match(line))
        cmd = md[:cmd].strip
        args = md[:args].split(/[\ ,;\|]/).select(&:present?)
        log.info "COMMAND: [#{cmd}], args: #{args.inspect}"

        return if plugin_command!(cmd, *args)

        begin
          log.info "send #{cmd}, #{args}"
          self.__send__(cmd, *args)
        rescue NoMethodError => e
          api.error "unknown command #{cmd}(#{args.join(',')}): #{e}"
        end
      end
    rescue StandardError => e
      api.error(e.inspect)
      log.info(e.backtrace)
    end

    def status *_args
      api.info('rmud is active')
    end

    def find_plugin(name)
      name = name.classify
      [name, "RMud::#{name}", "RMud::Bot::#{name}"].find{|n| n.safe_constantize }.safe_constantize
    end

    def plugin name, *params
      klass = find_plugin(name)
      log.info "Start plugin #{name}#{params}: #{klass}"

      raise "Unknown plugin #{name}" unless klass

      return p if @plugins[klass.to_s]

      klass.new(self, *params).tap do |p|
        @plugins[klass.to_s] = p
        @conn.on_line do |line|
          p.process(line)
        end
        api.info("Plugin [#{klass}] started")
      end
    end

    class Obcast

      attr_reader :bot, :current_spell

      def initialize(bot)
        @bot = bot
        @spell = {
          stoneskin: ['твоя кожа покрывается', 'каменеет'],
          armor:     ['Ты чувствуешь, как что-то защищает тебя.', '']
        }

        # [:stoneskin, :armor]
        @current_spell = nil
        @delayed = nil

        bot.scheduler.every(10.seconds) do
          # bot.api.send('affects')
        end

        @current_spell = :armor
        bot.api.send('cast armor')
      end

      def cast(spell)
        bot.send("cast #{spell}")
      end

      def process(line)
        return unless line.include?(@spell[current_spell].first)

        api.info("OBCATS: #{current_spell} ok")
      end

      def process1(line)
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

