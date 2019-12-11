# Buffer is used to wrap the logger's logdev to accomplish buffering.
# For the purposes of the Logger class a LogDevice only needs to implement
# #write and #close. We add #buffered as well.
module BufferingLogger
  class Buffer
    def initialize(logdev)
      @logdev = logdev
      @mutex = Mutex.new
    end

    # buffers during the block and then flushes.
    # returns the value of the block.
    def buffered(transform: nil)
      @buffering = true
      yield
    ensure
      @buffering = false
      flush(transform: transform)
    end

    def write(msg)
      if @buffering
        (buffer || create_buffer).write(msg)
      else
        logdev_write(msg)
      end
    end

    def close
      logdev_close
    end

    private

    def flush(transform: nil)
      if buffer && buffer.length > 0
        msg = buffer.string
        msg = transform.call(msg) if transform
        logdev_write(msg)
      end
    ensure
      unset_buffer if buffer
    end

    def logdev_write(msg)
      @mutex.synchronize do
        @logdev.write(msg)
      end
    end

    def logdev_close
      @mutex.synchronize do
        @logdev.close
      end
    end

    def buffer
      Thread.current[buffer_id]
    end

    def create_buffer
      Thread.current[buffer_id] = StringIO.new
    end

    def unset_buffer
      Thread.current[buffer_id] = nil
    end

    def buffer_id
      "buffering_logger_#{object_id}_buffer"
    end

  end
end
