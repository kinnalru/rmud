module RMud
  module Plugin
    class TrainBattle < Base

      set_deps('State', 'Caster', 'Assist')

      def initialize(bot, *args, **kwargs)
        @features = {}
        @battle = false

        super
        bot.scheduler.every(10.seconds) do
          refresh
          battle!
        rescue StandardError => e
          error(e.inspect)
        end

        bot.scheduler.every(20.seconds) do
          # send("wear #{['spear', 'axe', 'sword', 'глефа', 'flail', 'whip'].shuffle.first}")
          send("wear #{['whip'].sample}")
        end
      end

      def refresh
        return if @refresh

        return unless !battle? && @battle

        @refresh = true
        @battle = false
        warn('battle finished')

        # send("c 'create water' water")
        send('stop')
        # send("c 'create food'")
        # send("c 'create food'")
        # send("c 'create food'")
        # send("c 'create food'")
        # send("take all*mush")
        deps[Caster].cast(:shield)
        deps[Caster].cast(:armor)
        deps[Caster].cast(:bless).then do |_r|
          @refresh = false
        end
      end

      def battle!
        @battle = true if battle? && !@battle
        return if @battle || @refresh

        # send("c 'inv'")
        # send("hide")
        # send("hide")
        send('hide')
        send("kill '#{@targets.sample}'")
        send('rescue eriden')
      end

      def battle?
        deps[State].battle?
      end

      def low_hp?
        deps[State].hp.low?
      end

      def critical_hp?
        deps[State].hp.critical?
      end

      def process(line); end

      def enable_all(*features)
        features.each do |f|
          self.__send__("enable_#{f}")
        end
      end

      def targets(*targets)
        @targets = targets
      end

      def enable(feature, *)
        self.__send__("enable_#{feature}", *)
      end

      def disable(feature, *)
        self.__send__("disable_#{feature}", *)
      end

      def enable_trip *args
        @features[:trip] = args
        @targets = args
        deps[Assist].enable_trip
      end

      def enable_kick *args
        @features[:kick] = args
        @targets = args
        deps[Assist].enable_kick
      end

      def enable_bash *args
        @features[:bash] = args
        @targets = args
        deps[Assist].enable_bash
      end

      def enable_dirt *args
        @features[:dirt] = args
        @targets = args
        deps[Assist].enable_dirt
      end




    end
  end
end

