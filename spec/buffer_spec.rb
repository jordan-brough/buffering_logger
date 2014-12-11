require 'stringio'

describe BufferingLogger::Buffer do
  let(:buffer) { BufferingLogger::Buffer.new(logdev) }

  let(:logdev) { Logger::LogDevice.new(dev) }
  let(:dev) { StringIO.new }
  let(:message) { 'some message' }

  def dev_contents
    dev.rewind
    dev.read
  end

  describe '#write' do
    context 'without buffering' do
      it 'writes to the logdev immediately' do
        buffer.write message
        expect(dev_contents).to eq message
      end
    end

    context 'with buffering' do
      it 'writes to the logdev after buffering' do
        buffer.buffered do
          buffer.write message
          expect(dev_contents).to eq ''
        end
        expect(dev_contents).to eq message
      end
    end
  end

  describe '#flush' do
    it 'flushes the log even during buffering' do
      buffer.buffered do
        buffer.write message
        expect(dev_contents).to eq ''
        buffer.flush
        expect(dev_contents).to eq message
      end
    end
  end

  describe '#close' do
    it 'flushes before closing' do
      buffer.buffered do
        buffer.write message
        expect(buffer).to receive(:flush).and_call_original # from #close
        buffer.close
        expect(buffer).to receive(:flush).and_call_original # after buffered
      end
    end

    it 'can be called multiple times' do
      expect {
        buffer.close
        buffer.close
      }.to_not raise_error
    end
  end

end
