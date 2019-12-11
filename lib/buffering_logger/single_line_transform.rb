# This transforms a multiline log into a single line log by replacing newlines
# with a special string (a single space by default).
#
# This is useful for platforms like Heroku where multiline Rails request logs
# of one process are interwoven with the request logs of other processes and
# other log sources (like the Heroku router).
#
# If you want to convert newlines into a special string so that you can later
# turn them back into newlines (e.g. in Splunk using a
# [SEDCMD](http://docs.splunk.com/Documentation/Splunk/latest/admin/Propsconf))
# then you can supply a `replacement` argument.
class BufferingLogger::SingleLineTransform

  REPLACEMENT = ' '.freeze
  NEWLINE = /\r?\n/.freeze

  def initialize(replacement: REPLACEMENT)
    @replacement = replacement
  end

  def call(msg)
    msg = msg.dup
    msg.strip!
    msg.gsub!(NEWLINE, @replacement)
    msg << "\n"
  end

end
