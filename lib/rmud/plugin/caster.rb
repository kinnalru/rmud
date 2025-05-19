require 'concurrent/promise'

module RMud
  module Plugin
    class Caster < Base

      Action = Struct.new('Action', :type, :action, :target, :promise) do
        def initialize(*args)
          super
          @created_at = Time.now
          self.promise ||= Concurrent::Promises.resolvable_future
        end

        def id
          "#{type}_#{action[:name]}_#{target}".gsub(/\W+/, '_')
        end

        def skill?
          type == :skill
        end

        def spell?
          type == :spell
        end

        def start!
          @started_at = Time.now
        end

        def name
          action[:name]
        end

        def elapsed
          @started_at ? Time.now - @started_at : 0
        end

        def command
          if skill?
            "#{name} #{target}".strip
          elsif spell?
            "c '#{name}' #{target}".strip
          else
            raise("unknown Action #{type.inspect}")
          end
        end

        def success?(line)
          Plugin::Base.match(line, action[:success] || [])
        end

        def failed?(line)
          Plugin::Base.match(line, action[:failure] || [])
        end
      end

      def initialize(bot, *args, **kwargs)
        super

        @queue = []
        @current = nil
        bot.scheduler.every(1.second) do
          execute_next_action
        end

        bot.scheduler.every(1.second) do
          next if @paused

          if (cmd = commands_queue.shift)
            info "run cmd:#{cmd.name}"
            cmd.run
          end
        end
      end

      def find_in_queue(action)
        @queue.find do |a|
          a.id == action.id
        end
      end

      def cast(spell, target = nil)
        s = Action.new(:spell, C7i::SPELLS.fetch(spell.to_sym), target)

        if (a = find_in_queue(s))
          a.promise
        else
          @queue << s
          execute_next_action
          s.promise
        end
      end

      def skill(skill, target = nil)
        s = Action.new(:skill, C7i::SKILLS.fetch(skill.to_sym), target)

        if (a = find_in_queue(s))
          a.promise
        else
          @queue << s
          execute_next_action
          s.promise
        end
      end

      def execute_next_action
        return if @current || @queue.empty?

        @current = action = @queue.shift

        await_line("cast_#{action.id}", /cast_#{action.id}/, duration: 30.seconds) do |_id, _promise|
          info("Casting[#{action.name.to_s.light_cyan}] on #{action.target.inspect}")
          action.start!
          send(action.command)
        end.then do |_success, lines, md|
          finalize_action(action, lines)
        end.rescue do |ex, *rest|
          finalize_action(action, ex, *rest)
        end
      end

      def finalize_action(action, lines_or_exception, *rest)
        @current = nil
        if lines_or_exception.is_a?(Exception)
          error("Failed[#{action.id}]: #{lines_or_exception}")
          action.promise.reject(lines_or_exception, *rest)
          execute_next_action
        elsif action.success?(lines_or_exception)
          info("#{'Success'.green}[#{action.name.to_s.light_cyan}] on #{action.target.inspect}")
          action.promise.fulfill(1)
          execute_next_action
        elsif action.failed?(lines_or_exception)
          warn("Failed[#{action.name.to_s.light_cyan}] on #{action.target.inspect}")
          action.promise.fulfill(0)
          execute_next_action
        else
          warn("Stupid[#{action.name.to_s.light_cyan}] on #{action.target.inspect}")
          action.promise.fulfill(-1)
        end
      end

      def process(line); end


    end
  end
end

