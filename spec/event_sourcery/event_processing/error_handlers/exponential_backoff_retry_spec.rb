RSpec.describe EventSourcery::EventProcessing::ErrorHandlers::ExponentialBackoffRetry do
  subject(:error_handler) do
    described_class.new(
      processor_name: processor_name,
    )
  end
  let(:processor_name) { 'processor_name' }
  let(:on_event_processor_error) { spy }
  let(:logger) { spy(Logger) }

  before do
    allow(EventSourcery.config).to receive(:on_event_processor_error).and_return(on_event_processor_error)
    allow(EventSourcery).to receive(:logger).and_return(logger)
    allow(logger).to receive(:error)
    allow(error_handler).to receive(:sleep)
  end

  describe '#with_error_handling' do
    let(:original_error) { double(to_s: 'OriginalError', backtrace: ['back', 'trace']) }
    let(:event) { double(uuid: SecureRandom.uuid) }
    let(:number_of_errors_to_raise) { 3 }
    subject(:with_error_handling) do
      @count = 0
      error_handler.with_error_handling do
        @count +=1
        raise error if @count <= number_of_errors_to_raise
      end
    end
    before { with_error_handling }

    context 'when the raised error is StandardError' do
      let(:error) { StandardError.new('Some error') }
      it 'logs the errors' do
        expect(logger).to have_received(:error).thrice
      end

      it 'calls on_event_processor_error with error and processor name' do
        expect(on_event_processor_error).to have_received(:call).thrice.with(error, processor_name)
      end

      it 'sleeps the process at default interval' do
        expect(error_handler).to have_received(:sleep).with(1).thrice
      end
    end

    context 'when the raised errors are EventProcessingError for the same event' do
      let(:error) { EventSourcery::EventProcessingError.new(event, original_error) }

      it 'logs the original error' do
        expect(logger).to have_received(:error).thrice.with("Processor #{processor_name} died with OriginalError.\\n back\\ntrace")
      end

      it 'calls on_event_processor_error with error and processor name' do
        expect(on_event_processor_error).to have_received(:call).thrice.with(original_error, processor_name)
      end

      it 'sleeps the process at exponential increasing intervals' do
        expect(error_handler).to have_received(:sleep).with(1).once
        expect(error_handler).to have_received(:sleep).with(2).once
        expect(error_handler).to have_received(:sleep).with(4).once
      end

      context 'when lots of errors are raised for the same event' do
        let(:number_of_errors_to_raise) { 10 }

        it 'sleeps the process at exponential increasing intervals' do
          expect(error_handler).to have_received(:sleep).with(1).once
          expect(error_handler).to have_received(:sleep).with(2).once
          expect(error_handler).to have_received(:sleep).with(4).once
          expect(error_handler).to have_received(:sleep).with(8).once
          expect(error_handler).to have_received(:sleep).with(16).once
          expect(error_handler).to have_received(:sleep).with(32).once
          expect(error_handler).to have_received(:sleep).with(64).exactly(4).times
        end
      end
    end

    context 'when the raised errors are EventProcessingError for the different events' do
      let(:error_for_event) { EventSourcery::EventProcessingError.new(event, original_error) }
      let(:another_event) { double(uuid: SecureRandom.uuid) }
      let(:error_for_another_event) { EventSourcery::EventProcessingError.new(another_event, original_error) }
      subject(:with_error_handling) do
        @count = 0
        error_handler.with_error_handling do
          @count +=1
          raise error_for_event if @count <= 3
          raise error_for_another_event if @count <= 5
        end
      end

      it 'resets retry interval when event uuid changes' do
        expect(error_handler).to have_received(:sleep).with(1).twice
        expect(error_handler).to have_received(:sleep).with(2).twice
        expect(error_handler).to have_received(:sleep).with(4).once
      end
    end
  end
end
