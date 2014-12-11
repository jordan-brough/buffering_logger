module BufferingLogger
  class RackBuffer
    def initialize(app, logger)
      @app, @logger = app, logger
    end

    def call(env)
      @logger.buffered { @app.call(env) }
    end
  end
end
