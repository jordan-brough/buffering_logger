$:.push File.expand_path('lib', __dir__)

require 'buffering_logger/version'

Gem::Specification.new do |s|
  s.name        = 'buffering_logger'
  s.version     = BufferingLogger::VERSION
  s.required_ruby_version = ">= 2.1.0"
  s.date        = '2016-02-04'
  s.summary     = 'BufferingLogger is a logger that buffers log entries and then writes them all at once.'
  s.description = 'Buffering makes it possible for log tools like Splunk or Logstash to more reliably group multiline logs as single events.'
  s.authors     = ['Jordan Brough']
  s.email       = 'rubygems.j@brgh.net'
  s.files       = Dir["lib/**/*"]
  s.homepage    = 'https://github.com/jordan-brough/buffering_logger'
  s.license     = 'MIT'
end
