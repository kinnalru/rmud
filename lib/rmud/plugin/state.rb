module RMud
  module Plugin
    class State < Base

      AFFECTS_SPELL_RX_PATTERN = /\s*(?<spell>[^:,\d]+)\s+(?<level>\d+)%,\s+(?<cost>\d+)/

      REFRESH_SPELL_STATE_EVENT = 'refresh_spell_state'
      SPELL_STATE_EVENT = 'spell_state'
      SPELL_STATE_FINISHED_EVENT = 'spell_state_finished'

      STATE_HP_CRIT_EVENT = 'state_hp_crit'
      STATE_HP_LOW_EVENT = 'state_hp_low'
      STATE_HP_NORMAL_EVENT = 'state_hp_normal'

      STATE_PROMPT_EVENT = 'state_prompt'

      STATE_BATTLE_EVENT = 'state_battle'
      STATE_BATTLE_FINISHED_EVENT = 'state_battle_finished'

      HP_RX = %r{(?<hp>\d+)/(?<hpmax>\d+)hp}
      MP_RX = %r{(?<mp>\d+)/(?<mpmax>\d+)mp}
      MV_RX = %r{(?<mv>\d+)/(?<mvmax>\d+)mv}
      BATTLE_RX = /(?<battle>\(БОЙ\))?\s*(?<shock>\(ШОК\))?\s*/
      TARGET_RX = /TARGET:\((?<target>.*)\)/
      ROOM_RX = /R:\((?<room>.*)\)/
      PROMPT_RX = %r{^<#{HP_RX}\s#{MP_RX}\s#{MV_RX}\s+EXP:\d+/\d+>\s*#{BATTLE_RX}\s*#{TARGET_RX}\s+#{ROOM_RX}\s+E:\(.*\)>.*$}

      set_deps

      class NumericState

        STATE_NORMAL = :normal
        STATE_LOW = :low
        STATE_CRIT = :critical
        STATES = [STATE_NORMAL, STATE_LOW, STATE_CRIT]

        attr_accessor :current, :max, :current_state

        def initialize(current, max, current_state = nil, **_kwargs)
          @current = current
          @max = max
          @current_state = current_state || state
        end

        def inspect
          "#{NumericState}<@current=#{@current} @max=#{@max} @state=#{@current_state} @value=#{value}>"
        end

        def to_s
          inspect
        end

        def stat
          "#{value}(#{current_state}) (#{((max / 100.0) * 40).round}/#{((max / 100.0) * 80).round})"
        end

        def value
          ((current.to_f / max.to_f) * 100).round
        end

        def low?(v = value)
          v <= 80
        end

        def critical?(v = value)
          v <= 40
        end

        def clone
          self.class.new(current, max, current_state)
        end

        def ==(other)
          self.current_state == other.current_state
        end

        def update(raw, max)
          return if current == raw && self.max == max

          prev = clone
          self.current = raw
          self.max = max
          self.current_state = state

          return if self == prev

          [prev, self]
        end

        def state(v = value)
          if critical?(v)
            STATE_CRIT
          elsif low?(v)
            STATE_LOW
          else
            STATE_NORMAL
          end
        end

      end

      attr_reader :hp, :spells

      def initialize(bot, *args, **kwargs)
        @spells = {}
        super
        bot.bus.subscribe(REFRESH_SPELL_STATE_EVENT) do |_event|
          send('spells')
        end

        @hp = NumericState.new(100, 100, nil)
      end

      def battle?
        @battle
      end

      def hp_changed(prev, cur)
        if cur.critical?
          danger('Critical HP: '.light_red + "#{cur.stat}")
          notify(STATE_HP_CRIT_EVENT, { prev: prev, current: cur })
        elsif cur.low?
          warn('Low HP: '.light_yellow + "#{cur.stat}")
          notify(STATE_HP_LOW_EVENT, { prev: prev, current: cur })
        else
          notify(STATE_HP_NORMAL_EVENT, { prev: prev, current: cur })
        end
      end

      def parse_spell_states(text)
        spell_rx = AFFECTS_SPELL_RX_PATTERN
        # info(text)
        text.split('mana').map(&:strip).compact.map do |line|
          # info(line)
          # info(line.inspect)
          md = spell_rx.match(line)
          # info(md.inspect)
          md
        end.compact.map{|md| md.named_captures.transform_values{|v| v.strip }.symbolize_keys }
      end

      def process(line)
        if (md = PROMPT_RX.match(line))
          if (changed = hp.update(md[:hp].to_i, md[:hpmax].to_i))
            hp_changed(*changed)
          end

          if @battle != !!md[:battle]
            if (@battle = !!md[:battle])
              notify(STATE_BATTLE_EVENT)
            else
              notify(STATE_BATTLE_FINISHED_EVENT)
            end
          end


          bot.notify(STATE_PROMPT_EVENT)
        end

        if (line.empty? || line[0] == '<') && @in_state
          @in_state = nil
          bot.notify(SPELL_STATE_FINISHED_EVENT)
          return
        end

        parse_spell_states(line).each do |state|
          @in_state = true
          st = @spells[state[:spell]] = state
          # info("STATE:#{st}")
          bot.notify(SPELL_STATE_EVENT, st)
        end
      end


    end
  end
end

