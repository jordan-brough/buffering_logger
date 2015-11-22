require 'buffering_logger'
require 'buffering_logger/rack_buffer'
require 'rails/railtie'

module BufferingLogger
  class Railtie < Rails::Railtie
    def self.install(transform: transform, device: nil, sync: true)
      initializer :buffering_logger, :before => :initialize_logger do |app|
        device ||= begin
          # Does mostly the same things that Rails does. See http://git.io/2v9FxQ

          path = app.paths["log"].first

          unless File.exist? File.dirname path
            FileUtils.mkdir_p File.dirname path
          end

          file = File.open(path, 'a')
          file.binmode
          file
        end

        device.sync = true if sync && device.respond_to?(:sync=)

        logger = BufferingLogger::Logger.new(device)
        logger.formatter = app.config.log_formatter
        logger = ActiveSupport::TaggedLogging.new(logger)

        app.config.logger = logger

        # Inserts at the very beginning so that all logs, even from other
        # middleware, get buffered together.
        app.config.middleware.insert(0, BufferingLogger::RackBuffer, logger, transform: transform)
      end
    end
  end
end
