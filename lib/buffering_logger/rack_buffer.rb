module BufferingLogger
  class RackBuffer
    def initialize(app, logger, transform: nil)
      @app, @logger, @transform = app, logger, transform
    end

    def call(env)
      @logger.buffered(transform: @transform) { @app.call(env) }
    end
  end
end
