#
# With buffered logs we don't need to log the request_id on every line.
# Instead we log it once near the start of the request.
# We do this via a Rack middleware to ensure that it's logged even for things
# like a `RoutingError` or other exceptional cases.
#
class BufferingLogger::RailsRackLogRequestId

  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    Rails.logger.info("request_id=#{request.request_id.inspect}")

    @app.call(env)
  end

end
