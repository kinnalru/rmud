module RMud
  module Plugin
    class Assist < Base

      set_deps('State', 'Caster')

      def self.feature(name, &block)
        define_method("enable_#{name}") do |*args|
          @features[name.to_sym] = args + [true]
          info("enabled: #{@features}")
          return unless block_given?

          instance_exec(*args, &block)
        end

        define_method("disable_#{name}") do
          @features[name.to_sym] = false
        end
      end

      feature(:trip)
      feature(:kick)
      feature(:bash)
      feature(:dirt)

      def initialize(bot, *args, **kwargs)
        @features = {}
        @actives = {}
        super


        bot.scheduler.every(3.second) do
          heal

          @features.to_a.shuffle.each do |f, enabled|
            __send__(f) if enabled
          rescue StandardError => e
            error(e.inspect)
            error(e.backtrace)
          end
        end

        subscribe(State::STATE_HP_LOW_EVENT) do
          heal
        end
      end

      def feature?(name)
        @features[name.to_sym]
      end

      def active?(name = nil)
        if name
          @actives[name.to_sym]
        else
          @actives.values.any?
        end
      end

      def activate(name)
        @actives[name.to_sym] = true
      end

      def deactivate(name)
        @actives[name.to_sym] = false
      end

      def heal
        return if active?(:heal)
        return if deps[State].hp.value > 90

        activate(:heal)
        deps[Caster].cast(:cure_serious).then do |_r|
          deactivate(:heal)
        end
      end

      def trip
        return if !feature?(:trip) || !battle? || low_hp?
        return if active?

        activate(:trip)
        deps[Caster].skill(:trip).then do |_r|
          deactivate(:trip)
        end
      end

      def kick
        return if !feature?(:kick) || !battle? || low_hp?
        return if active?

        activate(:kick)
        deps[Caster].skill(:kick).then do |_r|
          deactivate(:kick)
        end
      end

      def bash
        return if !feature?(:bash) || !battle? || low_hp?
        return if active?

        activate(:bash)
        deps[Caster].skill(:bash).then do |_r|
          deactivate(:bash)
        end
      end

      def dirt
        return if !feature?(:dirt) || !battle? || low_hp?
        return if active?

        activate(:dirt)
        deps[Caster].skill(:dirt).then do |_r|
          deactivate(:dirt)
        end
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

      def enable(feature, *)
        self.__send__("enable_#{feature}", *)
      end

      def disable(feature, *)
        self.__send__("disable_#{feature}", *)
      end




    end
  end
end

