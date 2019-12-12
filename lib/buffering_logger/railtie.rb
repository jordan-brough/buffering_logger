require 'buffering_logger'
require 'buffering_logger/rack_buffer'
require 'buffering_logger/rails_rack_log_request_id'
require 'rails/railtie'

class BufferingLogger::Railtie < Rails::Railtie

  def self.install(
    transform: nil, device: nil, sync: true, request_id: true,
    warn_log_tags: true
  )
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

      # We insert this at the very beginning so that all logs, even from other
      # middleware, get buffered together.
      app.config.middleware.insert(
        0,
        BufferingLogger::RackBuffer,
        logger,
        transform: transform,
      )

      # Log the request_id
      if request_id
        app.config.middleware.insert_after(
          Rails::Rack::Logger,
          BufferingLogger::RailsRackLogRequestId,
        )
      end

      if warn_log_tags && app.config.log_tags.present?
        puts(<<~TEXT.squish)
          NOTE: You're using `Rails.application.config.log_tags` with
          BufferingLogger. We recommend disabling these when using
          BufferingLogger. See the README for more info.
        TEXT
      end
    end
  end

end
