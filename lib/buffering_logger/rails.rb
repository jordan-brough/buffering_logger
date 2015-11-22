require 'rails/railtie'
require 'active_support/deprecation'
require 'active_support/core_ext/string/filters'

ActiveSupport::Deprecation.warn(<<-WARN.squish)
  "buffering_logger/rails" is deprecated.
  Please use "buffering_logger/railtie" instead and call BufferingLogger::Railtie.install explicitly.
WARN

require 'buffering_logger/railtie'
BufferingLogger::Railtie.install
