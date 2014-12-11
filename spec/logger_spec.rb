require 'stringio'

describe BufferingLogger::Logger do
  let(:logger) { BufferingLogger::Logger.new(*args) }

  let(:args) { [dev] }
  let(:dev) { StringIO.new }
  let(:message) { 'some message' }

  def dev_contents(dev=dev)
    dev.rewind
    dev.read
  end

  describe 'writing logs' do
    context 'without buffering' do
      it 'writes the message immediately' do
        logger << message
        expect(dev_contents).to eq message
      end
    end

    context 'with buffering' do
      it 'writes the message after buffering' do
        logger.buffered do
          logger << message
          expect(dev_contents).to eq ''
        end
        expect(dev_contents).to eq message
      end
    end
  end

  describe '#logdev=' do
    let(:new_dev) { StringIO.new }

    it 'changes the logdev in place' do
      logger.logdev = new_dev
      logger << message
      expect(dev_contents(new_dev)).to eq message
    end

    it 'closes the previous logdev' do
      logger.logdev = new_dev
      expect(dev).to be_closed
    end
  end

end
