module RMud
class Messages < Plugin


  def initialize(bot, *args, **kwargs)
    super
    init_lua
  end

  def init_lua
    bot.api.transmit('')
    script = %{
    
      display(1)      
      if exists('rmud_messages', 'script') == 0 then
        permScript('rmud_messages', 'rmud', [[ ]]);
      end
 
      setScript('rmud_messages', [[
        if rmud then
          rmud.messages = Geyser.UserWindow:new({
            name = "messages",
            titleText = 'messages';
            height = '25%',
            docked = true,
            dockPosition = "top",
            autoWrap = true 
          });
          rmud.messages:setFontSize(getFontSize()-1);
          rmud.echo_messages = function(text)
            rmud.messages:echo(text .. "\\n")
          end;
        end
      ]]);
    }
    info("Initializing objects...")
    bot.api.transmit "#{script}"
    info("Initialized")
  end

  SAY_RX=/^.*Ты произносишь '(.*)'$/
  SKILL_RX=/^Ты улучшаешь своё умение (.*).*$/
  SKILL2_RX=/^Осознав свои ошибки, ты становишься более искусным в (.*).*$/
  OOC_RX=/^.*\[OOC\](.*):(.*)/
  ALL_RX=/говорят|говорит|отвечает|спрашивает/

  def process(line)
    if md = SAY_RX.match(line)
      post(line.sub(md[1], md[1].light_green))
    elsif md = (SKILL_RX.match(line) || SKILL2_RX.match(line))
        post(line.sub(md[1], md[1].light_white))
    elsif md = OOC_RX.match(line)
        post("[#{'OOC'.light_yellow}] #{md[1].strip.light_white}:#{md[2].strip.light_green}")
    elsif ALL_RX.match(line)
        post(line)
    end
  end

  def post(msg)
    esc = Connection.escape("[#{Time.now}] #{msg.to_s}".strip)
    bot.api.transmit "rmud.messages:decho(ansi2decho(rmud.unescape(\"#{esc}\\n\")));"
  end


end

end