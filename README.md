buffering_logger
=====================

BufferingLogger is a logger that buffers log entries and then writes them
all at once.

## Why

Buffering makes it possible for log tools like Splunk or Logstash
to more reliably group multiline logs as single events.

## Installation

Add

    gem 'buffering_logger'

to your application's Gemfile. For Rails applications add:

    require 'buffering_logger/railtie'
    BufferingLogger::Railtie.install

in `config/application.rb` *after* `require 'rails/all'`. This configures your
application to use BufferingLogger and inserts a middleware that buffers and
flushes logs for each request.

## Usage

For Rails applications follow the instructions above.

For Rack applications insert the `BufferingLogger::RackBuffer` middleware
manually.

For other uses, such as cron jobs, surround the relevant code that should be
buffered with a called to `buffered`:

    logger.buffered do
      ...code...
    end

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

## Rails & Rack

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

    def call(env)
      logger.buffered do
        @app.call(env)
      end
    end

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
