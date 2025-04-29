module RMud
  class StdConnection < Connection

    attr_reader :instream, :outstream

    def initialize(*args, input:, output:, **kwargs)
      super(*args, **kwargs)

      @instream = input
      @outstream = output
    end

    def do_start
      @reader = start_reader
    end

    def do_stop
      @reader.tap do |reader|
        break unless reader
        @reader = nil

        reader.kill unless reader.join(2)
      end
    end

    def do_write line
      outstream.puts(line.to_s.strip)
      outstream.flush
    end

    def wait
      return if termiated?
      @reader&.join
    end

    def start_reader
      Thread.new do
        until termiated? || instream.closed?
          begin
            while !termiated? && !instream.eof?
              line = instream.gets&.encode("UTF-8")&.rstrip
              next unless line

              File.write('/tmp/rblog', "read line: #{line}\n", mode: 'a+')
              process(line)
              Thread.pass
            end
            instream.close
          rescue StandardError => e
            warn "Reader exception: #{e}. #{e.backtrace}"
            sleep 1
          end
        end
      end
    end

  end
end

