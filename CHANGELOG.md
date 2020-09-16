# v3.1.1

*   Include ActiveSupport::LoggerSilence if available

# v3.1.0

*   Default to using `ActiveSupport::Logger::SimpleFormatter`

*   Log the request id by default and add docs about Rails log tags

# v3.0.0

*   Fix threaded buffering status

    Previously the `buffering` status was being set as an instance variable,
    which meant that even though threaded buffers were separate, threaded usage
    could change the `buffering` status for a different thread.

    For threaded web servers this meant that logs were not lost but they also
    were not buffered properly.

    For manual threads inside of a single request (e.g. using `Thread.new`) this
    could cause logs to be lost.

# v2.0.6

*   Improve mutex handling

# v2.0.5

*   Add a `default_transform` property

# v2.0.4

*   Fix for multiple sequential logdev switches

# v2.0.3

*   Only close logdevs that we opened

# v2.0.2

*   No functionality updates

# v2.0.1

*   No functionality updates

# v2.0.0

*   BufferingLogger::Railtie now allows supplying a custom log device.

*   Log transforms. You can now supply transforms to modify the buffered
    contents before flushing them to the log device.

*   'buffering_logger/rails' has been deprecated.  Instead, require
    'buffering_logger/railtie' and call 'BufferingLogger::Railtie.install'.

*   BufferingLogger is now thread-safe.

*   Remove nested buffering support.

    This added complexity and shouldn't really be needed.

# v1.0.1

*   Fix encoding issue

    If the lines of a log have different encodings and those encodings are not
    automatically joinable by Ruby then Ruby would raise an
    `Encoding::CompatibilityError`.

# v1.0.0

*   Initial Release