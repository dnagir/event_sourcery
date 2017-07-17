RSpec.describe EventSourcery::EventStore::EventSource do
  let(:event_store) { double(:event_store) }
  subject(:event_source) { described_class.new(event_store) }

  describe 'adapter delegations' do
    %w[
      get_next_from
      latest_event_id
      get_events_for_aggregate_id
      get_event_by_uuid
      each_by_range
    ].each do |method|
      it "delegates ##{method} to the adapter" do
        allow(event_store).to receive(method.to_sym).and_return([])
        event_source.send(method.to_sym)
        expect(event_store).to have_received(method.to_sym)
      end
    end
  end
end
