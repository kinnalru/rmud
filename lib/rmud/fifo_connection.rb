module RMud
  class FifoConnection < Connection

    attr_reader :infile, :outfile, :queue

    def initialize(dir:, id:)
      super()
      @infile = "#{dir}/#{id}.cmd"
      @outfile = "#{dir}/#{id}.result"
      @queue = []
    end

    def do_start
      clean
      File.mkfifo(@infile)
      File.mkfifo(@outfile)
      @reader = start_reader
      @writer = start_writer
    end

    def wait
      return if termiated?
      @reader&.join
      return if termiated?
      @writer&.join
    end
    
    def do_stop
      @reader.tap do |reader|
        break unless reader
        @reader = nil

        # force unblock fifo reader thread
        File.open(infile, mode: File::RDWR | File::NONBLOCK) do |f|
          f.write_nonblock('') rescue nil

          reader.kill unless reader.join(2)
          File.remove(infile) rescue nil
          File.unlink(infile) rescue nil
        end
      end

      @writer.tap do |writer|
        break unless writer
        @writer = nil

        # force unblock fifo writer thread
        File.open(outfile, mode: File::RDWR | File::NONBLOCK) do |f|
          f.read_nonblock(1) rescue nil

          writer.kill unless writer.join(2)
          File.remove(outfile) rescue nil
          File.unlink(outfile) rescue nil
        end
      end

      clean
    end

    def do_write line
      queue.push line
    end

    def clean
      File.remove(infile) rescue nil
      File.unlink(infile) rescue nil
      File.remove(outfile) rescue nil
      File.unlink(outfile) rescue nil
    end

    def start_reader
      Thread.new(infile) do |fn|
        until termiated?
          begin
            File.open(fn, 'r') do |read|
              break if termiated?

              while line = read.gets
                conv = line.encode("UTF-8")
                File.write('/tmp/rblog', "read line: #{conv.rstrip}\n", mode: 'a+')
                process(conv.rstrip)
              end
              Thread.pass
            end
          rescue StandardError => e
            warn "Reader exception: #{e}. #{e.backtrace}"
            sleep 1
          end
        end
      end
    end

    def start_writer
      Thread.new(outfile) do |fn|
        until termiated?
          begin
            File.open(fn, 'a') do |write|
              mx.synchronize do
                while line = queue.shift
                  File.write('/tmp/rblog', "write line: #{line.rstrip}\n", mode: 'a+')
                  write.puts line.rstrip
                end
              end
            end
          rescue StandardError => e
            warn "Writer exception: #{e}"
            sleep 1
          end
        end
      end
    end

  end
end

