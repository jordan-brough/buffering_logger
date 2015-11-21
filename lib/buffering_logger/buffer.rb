# Buffer is used to wrap the logger's logdev to accomplish buffering.
# For the purposes of the Logger class a LogDevice only needs to implement
# #write and #close. We add #buffered and #flush as well.
module BufferingLogger
  class Buffer
    def initialize(logdev)
      @logdev = logdev
      @mutex = Mutex.new
    end

    # buffers during the block and then flushes.
    # returns the value of the block.
    def buffered
      @buffering = true
      yield
    ensure
      @buffering = false
      flush
    end

    def write(msg)
      if @buffering
        (buffer || create_buffer).write(msg)
      else
        @logdev.write(msg)
      end
    end

    def flush
      if buffer && buffer.length > 0
        @mutex.synchronize do
          @logdev.write buffer.string
        end
      end
    ensure
      unset_buffer if buffer
    end

    def close
      flush
      @mutex.synchronize do
        @logdev.close
      end
    end

    private

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
