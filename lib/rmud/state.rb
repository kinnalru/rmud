class State < Plugin

    AFFECTS_SPELL_RX_PATTERN = "\\s*(?<spell>[^:,\d]+)\\s+(?<level>\\d+)%,\s+(?<cost>\\d+)"

    REFRESH_SPELL_STATE_EVENT = "refresh_spell_state"
    SPELL_STATE_EVENT = "spell_state"
    SPELL_STATE_FINISHED_EVENT = "spell_state_finished"

    def initialize(bot, *args, **kwargs)
        @spells = {}
        super
        bot.bus.subscribe(REFRESH_SPELL_STATE_EVENT) do |event|
            send('spells')
        end
    end

    def parse_spell_states text
        spell_rx = Regexp.new(AFFECTS_SPELL_RX_PATTERN)
        text.split('mana').map(&:strip).compact.map do |line|
            spell_rx.match(line)
        end.compact.map{|md| md.named_captures.transform_values{|v| v.strip}.symbolize_keys}
    end


    def process(line)
        if (line.empty? || line[0] == '<') && @in_state
            @in_state = nil
            bot.notify(SPELL_STATE_FINISHED_EVENT)
            return
        end

        parse_spell_states(line).each do |state|
            @in_state = true
            st = @spells[state[:spell]] = state
            info("STATE:#{st}")
            bot.notify(SPELL_STATE_EVENT, st)

        end
    end
    
end