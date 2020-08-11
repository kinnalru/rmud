module RMud
  class StdConnection < Connection

    attr_reader :instream, :outstream

    def initialize(instream:, outstream:)
      super()
      @instream = instream
      @outstream = outstream
    end

    def do_start
      @reader = start_reader
    end

    def wait
      return if termiated?
      @reader&.join
    end

    def do_stop
      @reader.tap do |reader|
        break unless reader
        @reader = nil

        reader.kill unless reader.join(2)
      end
    end

    def do_write line
      outstream.puts(line.to_s)
      outstream.flush
    end

    def start_reader
      Thread.new do
        until termiated? || instream.closed?
          begin
            while !termiated? && !instream.eof?
              line = instream.gets
              conv = line.encode("UTF-8")
              File.write('/tmp/rblog', "read line: #{conv.rstrip}\n", mode: 'a+')
              process(conv.rstrip)
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

