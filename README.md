buffering_logger
=====================

BufferingLogger is a logger that buffers log entries and then writes them
all at once.

## Why

Buffering makes it possible for log tools like Splunk or Logstash
to more reliably group multiline logs as single events.

## Installation

Add

```ruby
gem 'buffering_logger'
```

to your application's Gemfile. For Rails applications add the following two
lines in `config/application.rb`:

```ruby
require 'rails/all'
require 'buffering_logger/railtie' # THIS LINE

…

module YourApp
  class Application < Rails::Application
    …
    BufferingLogger::Railtie.install # AND THIS LINE
```

This configures your application to use BufferingLogger and inserts a middleware
that buffers and flushes logs for each request.

## Usage

For Rails applications follow the instructions above.

For Rack applications insert the `BufferingLogger::RackBuffer` middleware
manually.

For other uses, such as cron jobs, surround the relevant code that should be
buffered with a called to `buffered`:

```ruby
logger.buffered do
  ...code...
end
```

Inside of the `buffered` block log lines will be queued up and then all written
to disk at once when the `buffered` block exits.

Outside of a `buffered` block BufferingLogger behaves like a non-buffered
logger.

### Log transforms

If you'd like to transform the buffer before flushing it you can supply a
'transform'. E.g.:

```ruby
logger.buffered(transform: MyTransform.new) { ... }
```

A transform should be an object that responds to `call(String)` and returns a
String. See BufferingLogger::SingleLineTransform as an example.

For Rails a request-log transform can be supplied when installing the Railtie:

```ruby
require 'buffering_logger/railtie'
require 'buffering_logger/single_line_transform'
BufferingLogger::Railtie.install(transform: BufferingLogger::SingleLineTransform.new)
```

You can also set a `default_transform` on a logger:

```ruby
logger.default_transform = ->(msg) { "transformed #{msg}" }
```

## Rails & Rack

### Buffering

BufferingLogger provides a Rack middleware (`BufferingLogger::RackBuffer`) that
buffers all the lines of a single Rails request log. (See installation
instructions above.)

E.g. this set of lines:

    Started PUT "/foo/bar" for 10.0.0.1 at 2014-12-09 05:29:39 +0000
    Processing by FoosController#bar as JSON
    Parameters: {"hey" => "there"}
    Completed 200 OK in 7.2ms (Views: 5.7ms | ActiveRecord: 1.1ms)

will all be written to the log device at the same time.  The middleware works
like this:

```ruby
def call(env)
  logger.buffered do
    @app.call(env)
  end
end
```

### Request ID

BufferingLogger also adds a Rack middleware by default that logs the request id
(`BufferingLogger::RailsRackLogRequestId`).

If desired, you can disable this behavior via:
```ruby
BufferingLogger::Railtie.install(request_id: false)
```

## Rails.application.config.log_tags and BufferingLogger

With a buffering logger and a properly configured log tool, you don't need to
log request-wide tags on every line. Instead you can log them once per request.
This means you will probably want to disable this line in your
`environments/*.rb`:
```ruby
# Disable this line in environments/*.rb:
# config.log_tags = [ :request_id ]
```

The request_id in particular is logged automatically by BufferingLogger (see
above).

If you would like to log other request-wide items you can follow the Rack
middleware pattern that `BufferingLogger::RailsRackLogRequestId` uses.

BufferingLogger warns you if you've configured log tags together with
BufferingLogger. To disable the warning you can pass `warn_log_tags: false` to
`BufferingLogger::Railtie.install()`.

## How BufferingLogger helps log tools

When a single "event" is composed of multiple log lines you want your log tools
to index that set of lines as a single entry so that you can perform log queries
like:

    controller=FoosController AND duration>100

where different parts of the data you're searching for come from different
lines.

The problem with multiline logs for log tools is knowing when log entries start
and stop. Most log tools can be configured to look for particular patterns, like
looking for "Started XXX" for the beginning of a Rails log entry.  And
"Completed" for the end of a log entry. However, a couple things make that
tricky:

- Sometimes the "Completed" line is never written (e.g. when a Rails request
raises an exception, or if an application locks up completely)
- If there are non-trivial delays between the lines of a multiline log (like for
a slow web server endpoint) then the log tool may become 'impatient' and split
your single event into multiple events.

Log forwarder processes could be made smarter but they are built to be very
simple and lightweight to keep CPU usage low.

Log indexer processes could be more patient, but this can tie up critical
resources and might delay important log information from getting indexed.

Buffering log entries helps solve both of these problems by writing all the log
data for a single log entry at once.

## Changing log devices

BufferingLogger also provides a `#logdev=` method to allow changing log devices
without creating a new logger. This is useful when using a forking server like
Unicorn if you want to provide separate log files for each worker process
(which also helps log tools).  This is important because by the time Unicorn
forks there may be many objects (such as ActiveRecord::Base) that already have
direct references to the existing logger object so the existing logger needs to
be updated in place, rather than being replaced with a new logger.

## Threads

Buffering logger is thread-safe. Every thread gets its own separated storage and
flushing for the messages sent by that thread.

E.g. in this code:

```ruby
logger = BufferingLogger::Logger.new($stdout)
Thread.new { logger.buffered { ... } }
Thread.new { logger.buffered { ... } }
```

the logs for each thread will be grouped together and atomically flushed to the
underlying log device.

And in this code:

```ruby
logger = BufferingLogger::Logger.new($stdout)
logger.buffered do
  ...
  t1 = Thread.new do
    logger.buffered do
      ...
    end
  end
  t1.join
  ...
end
```

the messages for the nested thread will be buffered separately from the main
thread's messages and will be flushed before the main thread's logs are flushed.
