module EventSourcery
  class Repository
    def self.load(aggregate_class, aggregate_id, event_source:, event_sink:)
      new(event_source: event_source, event_sink: event_sink).load(aggregate_class, aggregate_id)
    end

    def initialize(event_source:, event_sink:)
      @event_source = event_source
      @event_sink = event_sink
    end

    def load(aggregate_class, aggregate_id)
      events = event_source.get_events_for_aggregate_id(aggregate_id)
      aggregate_class.new(aggregate_id, events)
    end

    def save(aggregate)
      new_events = aggregate.changes
      if new_events.any?
        event_sink.sink(new_events, expected_version: aggregate.version - new_events.count)
      end
      aggregate.clear_changes
    end

    private

    attr_reader :event_source, :event_sink
  end
end