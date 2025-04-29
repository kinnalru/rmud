module RMud
  class FileConnection < Connection

    attr_reader :infile, :outfile, :queue

    def initialize(*args, dir:, **kwargs)
      super(*args, **kwargs)
      
      @infile = "#{dir}/#{id}.input"
      @outfile = "#{dir}/#{id}.output"
      @cvmx = Thread::Mutex.new
      @cv  = Thread::ConditionVariable.new
      @queue = []
    end

    def do_start
      clean

      @reader = start_reader
      @writer = start_writer
    end

    def do_stop
      @reader.tap do |reader|
        break unless reader
        @reader = nil

        reader.kill unless reader.join(2)
        File.remove(infile) rescue nil
        File.unlink(infile) rescue nil
      end

      @writer.tap do |writer|
        break unless writer
        @writer = nil

        writer.kill unless writer.join(2)
        File.remove(outfile) rescue nil
        File.unlink(outfile) rescue nil
      end

      clean
    end

    def do_write line
      @cvmx.synchronize do
        queue.push line
        @cv.signal
      end if line
    end

    def wait
      return if termiated?
      @reader&.join
      return if termiated?
      @writer&.join
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
          sleep 0.1
          begin
            with_lock(fn) do |file|
              break if termiated?

              while line = self.class.readline(file)
                File.write('/tmp/rblog', "read line: #{line}\n", mode: 'a+')
                process(line)
              end
              file.truncate(0)
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
        loop do
          break if termiated?

          @cvmx.synchronize do
            @cv.wait(@cvmx, 0.5)
          end

          break if termiated?

          with_lock(fn) do |file|
            break if termiated?

            while line = queue.shift
              File.write('/tmp/rblog', "write line: #{line.rstrip}\n", mode: 'a+')
              file.puts line.rstrip
            end
          end
        rescue StandardError => e
          warn "Writer exception: #{e}"
          warn e.backtrace
          sleep 1
        end
      end
    end

    def with_lock(filepath)
      File.open(filepath, File::RDWR | File::CREAT, 0o644) do |file|
        file.flock(File::LOCK_EX)
        yield(file)
      ensure
        file.flock(File::LOCK_UN)
      end
    end

  end
end

