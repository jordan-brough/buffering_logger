require 'stringio'
require 'rack'

describe BufferingLogger::RackBuffer do

  let(:app) do
    lambda do |env|
      logger << message
      expect(dev_contents).to eq ''
      [200, env, "app"]
    end
  end

  let(:middleware) do
    BufferingLogger::RackBuffer.new(app, logger)
  end

  let(:logger) { BufferingLogger::Logger.new(dev) }
  let(:dev) { StringIO.new }
  let(:message) { 'some message' }

  def dev_contents
    dev.rewind
    dev.read
  end

  def env_for url, opts={}
    Rack::MockRequest.env_for(url, opts)
  end

  it 'buffers the message' do
    # see also the expectation inside the `let(:app)`
    code, env = middleware.call env_for('http://example.com')
    expect(code).to eq 200
    expect(dev_contents).to eq message
  end

  context 'with an exception' do
    let(:app) do
      lambda do |env|
        logger << message
        expect(dev_contents).to eq ''
        raise error
      end
    end

    let(:error) { StandardError.new('oops') }

    it 'still writes the message' do
      expect {
        middleware.call env_for('http://example.com')
      }.to raise_error(error)
      expect(dev_contents).to eq message
    end
  end

end
