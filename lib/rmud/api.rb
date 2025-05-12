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

      def transmit(msg)
        @bot.conn.write msg
      end

      def echo(msg)
        transmit "#showme {#{msg}}"
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
       
          if exists('rmud', 'script') == 0 then
            permGroup('rmud', 'script');
          end
          
          if exists('rmud_process', 'script') == 0 then
            permScript('rmud_process', 'rmud', [[ ]]);
          end

          setScript('rmud_process', [[
            if rmud then
              rmud.process = function(arg)
                rmud.send(arg .. '\\n')
              end
            end
          ]]);

          if exists('rmud_unescape', 'script') == 0 then
            permScript('rmud_unescape', 'rmud', [[ ]]);
          end

          setScript('rmud_unescape', [[
            if rmud then
              rmud.unescape = function(arg)
                local s = arg;
                s = string.gsub(s, 'pp_pp', "'");
                s = string.gsub(s, 'pp__pp', '"');
                s = string.gsub(s, 'pp___pp', "`");
                return s;
              end
            end
          ]]);
          
          if exists('rmud', 'trigger') == 0 then
            permGroup('rmud', 'trigger');
          end

          if exists('rmud_capture', 'trigger') == 0 then
            permRegexTrigger('rmud_capture', 'rmud', {'(.*)'}, [[
              if rmud and rmud.process then
                rmud.process(matches[1])
              end
            ]]);
          end

         
         
          if exists('rmud', 'alias') == 0 then
            permGroup('rmud', 'alias');
          end

          if exists('rmud_process', 'alias') == 0 then
            permAlias('rmud_process', 'rmud', '^rmud (.*)$', [[
              if rmud and rmud.process then
                rmud.process(matches[1]);
              end
            ]]);
          end
        }
        info("Initializing objects...")
        transmit "#{script}"
        info("Initialized")
      end

      def transmit(msg)
        @bot.conn.write msg
        @bot.conn.write ''
      end

      def send(command)
        esc = Connection.escape(command.to_s.strip) 
        transmit "expandAlias(rmud.unescape(\"#{esc}\"), true);"
      end

      def echo(msg)
        esc = Connection.escape(msg.to_s.strip)
        transmit "decho(ansi2decho(rmud.unescape(\"#{esc}\\n\")));"
      end

      def info(msg)
        echo("[#{'INFO'.cyan}] #{msg}")
      end

      def warn(msg)
        echo("[#{'WARN'.light_yellow}] #{msg}")
      end

      def danger(msg)
        echo("[#{'DANG'.light_red}] #{msg}")
      end

      def error(msg)
        echo("[#{'ERROR'.red}] #{msg}")
      end


    end
  end
end

