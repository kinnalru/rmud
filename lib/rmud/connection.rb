module RMud
  class Connection

    attr_reader :id, :infile, :outfile, :handlers, :mx, :queue

    def initialize(id:)
      @id = id
      @infile = "/tmp/rmud_#{id}.in"
      @outfile = "/tmp/rmud_#{id}.out"
      @mx = Monitor.new
      @queue = []
      @handlers = []
      puts self.inspect
    end

    def start
      return if @termiated

      clean
      File.mkfifo(@infile)
      File.mkfifo(@outfile)
      @reader = start_reader
      @writer = start_writer
    end

    def wait
      return if @termiated
      @reader&.join
      return if @termiated
      @writer&.join
    end

    def stop
      @termiated = true

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

    def on_line(&block)
      @handlers.push block
    end

    def clean
      File.remove(infile) rescue nil
      File.unlink(infile) rescue nil
      File.remove(outfile) rescue nil
      File.unlink(outfile) rescue nil
    end

    def start_reader
      Thread.new(@infile) do |fn|
        until @termiated
          begin
            File.open(fn, 'r') do |read|
              break if @termiated

              while line = read.gets
                File.write('/tmp/rblog', "read line: #{line}", mode: 'a+')
                process(line.rstrip)
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

    def process(line)
      return if line.strip.empty?

      results = handlers.map do |h|
        begin
          [h.call(line)].flatten
        rescue StandardError => e
          warn "Handler exception: #{e}. #{e.backtrace}"
          return []
        end
      end
      mx.synchronize do
        results.each do |r|
          queue.concat(r)
        end
      end
    end

    def start_writer
      Thread.new(@outfile) do |fn|
        until @termiated
          begin
            File.open(fn, 'a') do |write|
              mx.synchronize do
                while line = queue.shift
                  File.write('/tmp/rblog', "write line: #{line}", mode: 'a+')
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

