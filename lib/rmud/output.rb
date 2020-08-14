module RMud
  class Output

    class Matcher

      class Rule
        attr_reader :rule, :block
        def initialize(s, rule:, &block)
          @s = s
          @rule = rule
          @block = block
        end

        def ==(other)
          self.rule == other.rule && self.block == other.block
        end

        def call(*args)
          block.call(*args)
        end
        
        def cancel
          @s.cancel(self)
        end
      end



      def initialize
        @rules = []
      end

      def on rule, &block
        @rules.push(Rule.new(self, rule: rule, &block))
      end

      def remove value
        @rules.delete(value)
      end

      alias_method :delete, :remove
      alias_method :cancel, :remove

      def match(line)
        @rules.each do |r|
          if r.rule.is_a? Regexp
            if md = r.rule.match(line)
              return r.call(md)
            end
          end
        end
        return nil
      end
    end




    attr_reader :bot, :name
    def initialize bot, name, *args
      @bot = bot
      @name = name

      @file = "/tmp/#{name}.log"

      @m = Matcher.new.tap do |m|
        m.on  /\A# \[OOC\] (?<sender>.*): (?<text>.*)\Z/ do |md|
          "# " + '['.light_black + "OOC".red + ']'.light_black  + " " + md[:sender].light_white + ": " + md[:text].green
        end

        m.on  /\A# (?<sender>Ты) произносишь [']?(?<text>.*)[']?\Z/ do |md|
          "# " + "Ты".light_white  + " произносишь: " +  md[:text].green
        end

        m.on  /\A# (?<sender>Ты) говоришь клану [']?(?<text>.*)[']?\Z/ do |md|
          "# " + "Ты".light_white  + " говоришь клану: " +  md[:text].cyan
        end

      end
    end

    OOC_RX=/\A# \[OOC\] (?<sender>.*): (?<text>.*)\Z/
    YOUR_RX=/\A# (?<sender>Ты) произносишь [']?(?<text>.*)[']?\Z/

    # Ты произносишь 'test'


    def process line
      l = @m.match(line)
      log(l) if l
    end

    def log line
      puts "WRITE: #{line}"
      puts "WRITE E: #{line.encoding}"
      File.write(@file, line + "\n", mode: "a")
    end


  end
end

