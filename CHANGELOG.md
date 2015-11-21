# v2.0.0 (unreleased)

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