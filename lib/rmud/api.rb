module RMud
  module Api
    class TinTin

      # Настрока работы с TinTin
      def self.script(infile:, outfile:)
        %{
          #split
          #ACTION {%*}     {
            #variable {outline} {%0};
            #replace  {outline} {\'} {pp_pp};
            #replace  {outline} {\"} {pp__pp};
            #replace  {outline} {\`} {pp___pp};
            #script   {flock '#{infile}' -c \"echo '$outline' >> '#{infile}'\" &> /dev/null };  
          }
          #TICKER bot      {#script { flock '#{outfile}' -c \"cat '#{outfile}'; > '#{outfile}'\" }} {0.1}
          #ALIAS {rmud %*} {
            #variable {rmud_outline} {%0};
            #replace  {rmud_outline} {\'} {pp_pp};
            #replace  {rmud_outline} {\"} {pp__pp};
            #replace  {rmud_outline} {\`} {pp___pp};
            #script { flock '#{infile}' -c \"echo '$rmud_outline' >> '#{infile}'\" &> /dev/null}
          }

          #showme 
          #showme Initializing RMUD bot connection...
          #showme    Input  Stream: #{outfile}
          #showme    Output Stream: #{infile}
        }.strip
      end

      def initialize(bot: nil)
        @bot = bot
      end

      def init
      end

      def send(msg)
        @bot.conn.write msg
      end

      def echo(msg)
        send "#showme {#{msg}}"
      end

      def info(msg)
        echo("[#{'INFO'.cyan}] #{msg}")
      end

      def error(msg)
        echo("[#{'ERROR'.red}] #{msg}")
      end

    end

    class Mudlet
      def initialize(bot: nil)
        @bot = bot
      end

      def transmit(line)
        @bot.conn.write "#{line};"
        @bot.conn.write "" 
      end

      def init
        transmit('')
        script = %{
          if exists('rmud', 'trigger') == 0 then
            permGroup('rmud', 'trigger');
          end

          if exists('rmud', 'script') == 0 then
            permGroup('rmud', 'script');
          end

          display(11111);
          if exists('rmud_process', 'script') == 0 then
            permScript('rmud_process', 'rmud', [[
              rmud_process = function(arg)
                rmud.send(arg .. '\\n')
              end
            ]]);
          end
          display(22222);

          if exists('rmud_capture', 'trigger') == 0 then
            permRegexTrigger('rmud_capture', 'rmud', {'(.*)'}, [[rmud.send(matches[1] .. '\\n');]]);
          end

          # display(rmud)
          # rmud.rmud_process = function(arg)
          #   rmud.send(arg .. '\n')
          # end

          # if exists('rmud', 'alias') == 0 then

          # end

          # if exists('rmud', 'alias') == 0 then
          #   permGroup('rmud', 'alias');
          # end

          # if exists('rmud_cmd', 'alias') == 0 then
          #   permAlias('rmud_cmd', 'rmud', '^rmud (.*)$', [[rmud.send(matches[1] .. '\\n');]]);
          # end
        }
        info("Initializing objects...")
        send "#{script}"
        info("Initialized")
      end

      def send(msg)
        puts msg
        @bot.conn.write msg
        @bot.conn.write ''
      end

      def echo(msg)
        send "decho(ansi2decho(\"#{msg.to_s}\\n\"))"
      end

      def info(msg)
        echo("[#{'INFO'.cyan}] #{msg}")
      end

      def error(msg)
        echo("[#{'ERROR'.red}] #{msg}")
      end


    end
  end
end

