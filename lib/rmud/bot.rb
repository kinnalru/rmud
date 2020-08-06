module RMud
  class Bot
    attr_reader :conn
    def initialize(conn)
      @conn = conn
      @conn.on_line do |line|
        puts "on line"
        process(line)
      end
    end

  def start
    puts :bot_start
    @conn.start
  end

  def stop
    @conn.stop
  end

  def wait
    @conn.wait
  end

  def process line
    puts "process: #{line}"
    "#echo {NEWLINE: #{line}}"
  end
end
end