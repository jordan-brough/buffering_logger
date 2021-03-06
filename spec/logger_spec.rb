require 'stringio'
require 'tempfile'

describe BufferingLogger::Logger do
  let(:logger) { BufferingLogger::Logger.new(dev) }

  let(:dev) { StringIO.new }
  let(:message) { 'some message' }

  def dev_contents(device=dev)
    device.rewind
    device.read
  end

  describe 'writing logs' do
    context 'without buffering' do
      it 'writes the message immediately' do
        logger << message
        expect(dev_contents).to eq message
      end
    end

    context 'with a default transform' do
      let(:default_transform) do
        ->(msg) { "hello #{msg} goodbye" }
      end

      before do
        logger.default_transform = default_transform
      end

      it 'applies the transform by default' do
        logger.buffered do
          logger << 'jordan brough'
        end
        expect(dev_contents).to eq 'hello jordan brough goodbye'
      end

      it 'uses an override transform when present' do
        override_transform = ->(msg) { "override #{msg} transform"}
        logger.buffered(transform: override_transform) do
          logger << 'jordan brough'
        end
        expect(dev_contents).to eq 'override jordan brough transform'
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

      context 'with a transform' do
        let(:transform) do
          ->(msg) { "hello #{msg} goodbye" }
        end

        it 'applies the transform' do
          logger.buffered(transform: transform) do
            logger << 'jordan brough'
          end
          expect(dev_contents).to eq 'hello jordan brough goodbye'
        end
      end

      context 'with separate buffered multithreaded logging' do
        before do
          # format the log with just the message plus a newline
          logger.formatter = ->(_, _, _, msg) { "#{msg}\n" }
        end

        it 'uses separate buffers and buffering status for each thread' do
          thread1_queue = Queue.new
          thread2_queue = Queue.new

          thread1 = Thread.new do
            logger.buffered do
              thread1_queue << 'started'
              thread2_queue.shift == 'started' || raise

              logger.info 'thread1 message 1'
              thread1_queue << 'sent 1'

              thread2_queue.shift == 'sent 1' || raise
              logger.info 'thread1 message 2'
              thread1_queue << 'sent 2'

              thread2_queue.shift == 'sent 2' || raise
            end

            thread1_queue << 'finished'
          end

          thread2 = Thread.new do
            logger.buffered do
              thread2_queue << 'started'
              thread1_queue.shift == 'started' || raise

              thread1_queue.shift == 'sent 1' || raise

              logger.info 'thread2 message 1'
              thread2_queue << 'sent 1'

              thread1_queue.shift == 'sent 2' || raise
              logger.info 'thread2 message 2'
              thread2_queue << 'sent 2'

              thread1_queue.shift == 'finished' || raise
            end
          end

          thread1.join
          thread2.join

          expected_grouping = <<-LOG.gsub(/^\s*/, '')
            thread1 message 1
            thread1 message 2
            thread2 message 1
            thread2 message 2
          LOG

          expect(dev_contents).to eq(expected_grouping)
        end
      end

      context 'with nested buffered multithreaded logging' do
        before do
          # format the log with just the message plus a newline
          logger.formatter = ->(_, _, _, msg) { "#{msg}\n" }
        end

        it 'uses separate buffers and buffering status for each thread' do
          thread1_queue = Queue.new
          thread2_queue = Queue.new

          thread2 = nil
          thread1 = Thread.new do
            # thread 2 code, nested inside of thread1
            thread2 = Thread.new do
              logger.buffered do
                thread2_queue << 'started'
                thread1_queue.shift == 'started' || raise

                thread1_queue.shift == 'sent 1' || raise

                logger.info 'thread2 message 1'
              end
              thread2_queue << 'finished 2'
            end

            # thread 1 code
            logger.buffered do
              thread1_queue << 'started'
              thread2_queue.shift == 'started' || raise

              logger.info 'thread1 message 1'
              thread1_queue << 'sent 1'

              thread2_queue.shift == 'finished 2' || raise
              logger.info 'thread1 message 2'
            end
          end

          thread1.join
          thread2.join

          expected_grouping = <<-LOG.gsub(/^\s*/, '')
            thread2 message 1
            thread1 message 1
            thread1 message 2
          LOG

          expect(dev_contents).to eq(expected_grouping)
        end
      end

      context 'with nested buffered + non-buffered multithreaded logging' do
        before do
          # format the log with just the message plus a newline
          logger.formatter = ->(_, _, _, msg) { "#{msg}\n" }
        end

        it 'uses separate buffers and buffering status for each thread' do
          thread1_queue = Queue.new
          thread2_queue = Queue.new

          thread2 = nil
          thread1 = Thread.new do
            # thread 2 code, nested inside of thread1
            thread2 = Thread.new do
              thread2_queue << 'started'
              thread1_queue.shift == 'started' || raise

              thread1_queue.shift == 'sent 1' || raise

              logger.info 'thread2 message 1'
              thread2_queue << 'finished 2'
            end

            # thread 1 code
            logger.buffered do
              thread1_queue << 'started'
              thread2_queue.shift == 'started' || raise

              logger.info 'thread1 message 1'
              thread1_queue << 'sent 1'

              thread2_queue.shift == 'finished 2' || raise
              logger.info 'thread1 message 2'
            end
          end

          thread1.join
          thread2.join

          expected_grouping = <<-LOG.gsub(/^\s*/, '')
            thread2 message 1
            thread1 message 1
            thread1 message 2
          LOG

          expect(dev_contents).to eq(expected_grouping)
        end
      end

    end
  end

  describe '#logdev=' do
    let(:logger) { BufferingLogger::Logger.new(dev_arg) }
    let(:dev_arg) { StringIO.new }
    let!(:old_dev) { logger.raw_log_device.dev }
    let(:new_dev) { StringIO.new }

    it 'changes the logdev in place' do
      logger.logdev = new_dev
      logger << message
      expect(dev_contents(new_dev)).to eq message
    end

    context 'when it opened the previous logdev' do
      let(:dev_arg) { Tempfile.new('log').path }

      it 'closes the previous logdev' do
        logger.logdev = new_dev
        expect(old_dev).to be_closed
      end
    end

    context 'when it did not open the previous logdev' do
      let(:dev_arg) { StringIO.new }

      it 'does not close the previous logdev' do
        logger.logdev = new_dev
        expect(old_dev).to_not be_closed
      end
    end

    context 'when using stdout' do
      let(:dev_arg) { $stdout }

      it 'does not blow up' do
        expect {
          logger.logdev = new_dev
        }.to_not raise_error
        expect(old_dev).to_not be_closed
      end
    end

    context 'when switching multiple times' do
      specify do
        logger = BufferingLogger::Logger.new(Tempfile.new('log').path)

        old_dev = logger.raw_log_device.dev
        logger.logdev = StringIO.new
        expect(old_dev).to be_closed

        old_dev_2 = logger.raw_log_device.dev
        logger.logdev = StringIO.new
        expect(old_dev_2).to_not be_closed
      end
    end
  end

end
