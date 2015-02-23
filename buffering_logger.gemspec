Gem::Specification.new do |s|
  s.name        = 'buffering_logger'
  s.version     = '1.0.1'
  s.date        = '2014-12-10'
  s.summary     = 'BufferingLogger is a logger that buffers log entries and then writes them all at once.'
  s.description = 'Buffering makes it possible for log tools like Splunk or Logstash to more reliably group multiline logs as single events.'
  s.authors     = ['Jordan Brough']
  s.email       = 'rubygems.j@brgh.net'
  s.files       = Dir["lib/**/*"]
  s.homepage    = 'https://github.com/jordan-brough/buffering_logger'
  s.license     = 'MIT'
end
