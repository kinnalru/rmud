module RMud
  module Plugin
    class TrainSpell < Base

      SPELLS = RMud::C7i::SPELLS

      AFFECTS_SPELL_RX_PATTERN = "\\s*(?<spell>SPELL)\\s+(?<level>\\d+)%,\s+(?<cost>\\d+)"

      set_deps('State', 'Caster')

      # rmud plugin TrainSpell,cure_light,detect_magic,infravision,detect_magic,detect_invis,continual_light,refresh,cure_blindness,remove_splinters,locate_object,cure_serious,fly
      def initialize(bot, *spells, **kwargs)
        @spells = spells.map(&:to_s).map(&:strip).map(&:to_sym)
        super

        start
      end

      def status
        info(@spells)
      end

      def all_self
        @spells = SPELLS.select do |_name, sp|
          sp.fetch(:tags, []).include?(:self)
        end.map{|name, _sp| name }.map(&:to_sym)

        start
      end

      def start
        bot.bus.subscribe(State::SPELL_STATE_FINISHED_EVENT) do |_event|
          check
        end

        bot.notify(State::REFRESH_SPELL_STATE_EVENT)
      end

      def check
        completed_spells = []
        @spells.select! do |spell|
          full = SPELLS.fetch(spell)
          # info(deps[State].spells)
          if deps[State].spells.fetch(full[:name].to_s)[:level].to_i == 100
            completed_spells << spell
            false
          else
            true
          end
        end

        info("COMPLETED: #{completed_spells}") if completed_spells.any?
        castnext if @spells.any?
      end

      def castnext
        return if @current

        @current_spell = @spells.sample
        @current = SPELLS.fetch(@current_spell)
        @f = f = deps[Caster].cast(@current_spell)
        f.then do |r, *_rest|
          @f = nil if @f == f
          completed(r)
        end.rescue do |ex, *_rest|
          completed(ex)
        end
      end

      def completed(reason)
        @current = nil
        castnext
      end

      def process(line)
        return unless @current

        return unless line.strip == "Ты теперь в совершенстве знаешь #{@current[:name]}!"

        bot.notify(State::REFRESH_SPELL_STATE_EVENT)
      end

    end
  end
end

