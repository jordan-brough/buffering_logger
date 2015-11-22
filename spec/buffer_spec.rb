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

      context 'with a transform' do
        let(:transform) do
          ->(msg) { "hello #{msg} goodbye" }
        end

        it 'applies the transform' do
          buffer.buffered(transform: transform) do
            buffer.write 'jordan brough'
          end
          expect(dev_contents).to eq 'hello jordan brough goodbye'
        end
      end
    end
  end

  describe 'merging incompatible encodings' do
    it 'does not generate an error' do
      expect {
        buffer.buffered do
          buffer.write '✓'
          buffer.write '✓'.force_encoding('ASCII-8BIT')
        end
      }.to_not raise_error
    end
  end

  describe '#close' do
    it 'can be called multiple times' do
      expect {
        buffer.close
        buffer.close
      }.to_not raise_error
    end
  end

end
