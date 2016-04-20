RSpec.describe EventSourcery::ProcessedEventTrackerAdapters::Postgres do
  subject(:postgres_tracker) { described_class.new(connection) }
  let(:table_name) { EventSourcery::ProcessedEventTrackerAdapters::Postgres::TABLE_NAME }
  let(:processor_name) { 'blah' }
  let(:table) { connection[table_name] }
  let(:track_entry) { table.where(name: processor_name).first }

  def last_processed_event_id
    postgres_tracker.last_processed_event_id(processor_name)
  end

  def setup_table
    connection.execute "drop table if exists #{table_name}"
    postgres_tracker.setup(processor_name)
  end

  describe '#setup' do
    before do
      connection.execute "drop table if exists #{table_name}"
    end

    it 'creates the table' do
      postgres_tracker.setup(processor_name)
      expect { table.count }.to_not raise_error
    end

    it "creates an entry for the projector if it doesn't exist" do
      postgres_tracker.setup(processor_name)
      expect(last_processed_event_id).to eq 0
    end
  end

  describe '#processed_event' do
    before do
      setup_table
    end

    it 'updates the tracker entry to the given ID' do
      postgres_tracker.processed_event(processor_name, 1)
      expect(last_processed_event_id).to eq 1
    end
  end

  describe '#processing_event' do
    before { setup_table }

    context 'when the block succeeds' do
      it 'marks the event as processed' do
        postgres_tracker.processing_event(processor_name, 1) do

        end
        expect(last_processed_event_id).to eq 1
      end
    end

    context 'when the block raises' do
      it "doesn't mark the event as processed and raises an error" do
        expect(last_processed_event_id).to eq 0
        expect {
          postgres_tracker.processing_event(processor_name, 1) do
            raise 'boo'
          end
        }.to raise_error(RuntimeError)
        expect(last_processed_event_id).to eq 0
      end
    end

    context 'out of order processing' do
      it "raises an error" do
        expect {
          postgres_tracker.processing_event(processor_name, 2) { }
        }.to raise_error(EventSourcery::NonSequentialEventProcessingError)
      end

      it "doesn't update a tracker" do
        expect {
          begin
            postgres_tracker.processing_event(processor_name, 2) {}
          rescue EventSourcery::NonSequentialEventProcessingError
          end
        }.to change { last_processed_event_id }.by 0
      end
    end
  end

  describe '#last_processed_event_id' do
    before do
      setup_table
    end

    it 'starts at 0' do
      expect(last_processed_event_id).to eq 0
    end

    it 'updates as events are processed' do
      postgres_tracker.processed_event(processor_name, 1)
      expect(last_processed_event_id).to eq 1
    end
  end

  describe '#reset_last_processed_event_id' do
    before do
      setup_table
    end

    it 'resets the last processed event back to 0' do
      postgres_tracker.processed_event(processor_name, 1)
      postgres_tracker.reset_last_processed_event_id(processor_name)
      expect(last_processed_event_id).to eq 0
    end
  end

  describe '#tracked_processors' do
    before do
      connection.execute "drop table if exists #{table_name}"
      postgres_tracker.setup
    end

    context 'with two tracked processors' do
      before do
        postgres_tracker.setup(:one)
        postgres_tracker.setup(:two)
      end

      it 'returns an array of tracked processors' do
        expect(postgres_tracker.tracked_processors).to eq ['one', 'two']
      end
    end

    context 'with no tracked processors' do
      it 'returns an empty array' do
        expect(postgres_tracker.tracked_processors).to eq []
      end
    end
  end
end
