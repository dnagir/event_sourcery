module EventHelpers
  def new_event(aggregate_id: SecureRandom.uuid, type: 'test_event', body: {}, id: nil)
    EventSourcery::Event.new(id: id,
                             aggregate_id: aggregate_id,
                             type: type,
                             body: body)
  end

  def create_old_events_schema
    pg_connection.execute 'drop table events'
    pg_connection.create_table(:events) do
      primary_key :id, type: :Bignum
      column :aggregate_id, 'uuid not null'
      column :type, 'varchar(255) not null'
      column :body, 'json not null'
      column :created_at, 'timestamp without time zone not null default (now() at time zone \'utc\')'
      index :aggregate_id
      index :type
      index :created_at
    end
  end
end

RSpec.configure do |config|
  config.include EventHelpers
end
