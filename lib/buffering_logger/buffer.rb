# Buffer is used to wrap the logger's logdev to accomplish buffering.
# For the purposes of the Logger class a LogDevice only needs to implement
# #write and #close. We add #buffered and #flush as well.
module BufferingLogger
  class Buffer
    def initialize(logdev)
      @logdev = logdev
      @buffer = StringIO.new
    end

    # buffers during the block and then flushes.
    # returns the value of the block.
    def buffered
      buffering_was = @buffering # in case we're already buffering
      @buffering = true
      yield
    ensure
      @buffering = buffering_was
      flush if !@buffering
    end

    def write(msg)
      @buffer.write(msg)
      flush if !@buffering
    end

    def flush
      if @buffer.length > 0
        @logdev.write @buffer.string
        @buffer = StringIO.new
      end
    end

    def close
      flush
      @logdev.close
    end
  end
end
