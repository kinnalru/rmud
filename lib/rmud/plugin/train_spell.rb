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

      def all(*tags)
        tags = [:self, :weapon] if tags.empty?
        tags = tags.map(&:to_sym)

        @spells = SPELLS.select do |_name, sp|
          (sp.fetch(:tags, []) & tags).any?
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
        @f = f = deps[Caster].cast(@current_spell, @current[:default_target])
        f.then do |r, *_rest|
          @f = nil if @f == f
          completed(r)
        end.rescue do |ex, *_rest|
          completed(ex)
        end
      end

      def completed(_reason)
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

TEST=%{
Объект 'kris white pawn крис белой пешки weapon оружие'
Тип: weapon, материал: камень, доп. флаги: antievil.
Вес: 1.0, стоит: 750, уровень: 10, использование: take, wield.
Класс оружия: кинжал (dagger).
Среднее повреждение от этого оружия: 7.3.
В твоих руках: надень и узнаешь.
Тип удара: колющий удар (pierce), что соответствует 'уязвимости к pierce' и 'AC от укола'.
Добыто тобой 1 год назад.
}