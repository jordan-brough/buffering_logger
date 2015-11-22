require 'logger'

# Buffering happens within a #buffered block, like:
#   logger.buffered { logger.info 'hi'; logger.info 'goodbye' }
# Buffering is implemented by wrapping the logger @logdev object with a Buffer.

module BufferingLogger
  class Logger < ::Logger

    def initialize(logdev, shift_age: 0, shift_size: 1048576)
      @shift_age, @shift_size = shift_age, shift_size
      super(nil, shift_age, shift_size)
      self.logdev = logdev
    end

    # allow changing the log destination. e.g.: in Unicorn during after_fork to
    # set a separate log path for each worker.
    def logdev=(logdev)
      @logdev.close if @logdev
      @logdev = Buffer.new(
        LogDevice.new(logdev, shift_age: @shift_age, shift_size: @shift_size)
      )
    end

    def buffered(transform: nil)
      @logdev.buffered(transform: transform) do
        yield
      end
    end
  end
end
