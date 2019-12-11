# v2.0.5 (unreleased)

* Improve mutex handling

* Add a `default_transform` property

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