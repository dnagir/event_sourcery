# EventSourcery

A framework for building event sourced, CQRS applications.

## Development Status

EventSourcery is currently being used in production by multiple apps but we
haven't finalized the API yet and things are still moving rapidly. Until we
release a 1.0 things may change without first being deprecated.

## Goals

The goal of EventSourcery is to make it easier to build event sourced, CQRS applications.

The hope is that by using EventSourcery you can focus on modeling your domain with aggregates, commands, and events; and not worry about stitching together application plumbing.

## Core Concepts

Refer to [core concepts](./docs/core-concepts.md) to learn about the core pieces of EventSourcery.

## Getting Started Guide

**TODO**

## Configuration

There are several ways to configure Event Sourcery to your liking. The following presents some examples:

```ruby
EventSourcery.configure do |config|
  # Add custom reporting of errors occurring during event processing.
  # One might set up Rollbar here.
  config.on_event_processor_error = proc { |exception, processor_name| … }

  # Enable Event Sourcery logging.
  config.logger = Logger.new('logs/my_event_sourcery_app.log')

  # Customize how event body attributes are serialized
  config.event_body_serializer
    .add(BigDecimal) { |decimal| decimal.to_s('F') }

  # Config how your want to handle event processing errors
  config.error_handler_class = EventSourcery::EventProcessing::ErrorHandlers::ExponentialBackoffRetry
end
```

## Applications that use EventSourcery

- [Identity](https://github.com/envato/identity) (note that this was the ES/CQRS implementation that ES was initially extracted from).
- [Payables](https://github.com/envato/payables).
- [Calendar Example App](https://github.com/envato/calendar-es-example).

## Development

### Dependencies

- Postgresql
- Ruby

### Running the Test Suite

Run the `setup` script, inside the project directory to install the gem dependencies and create the test database (if it is not already created).
```bash
./bin/setup
```

Then you can run the test suite with rspec:
```bash
rspec
```

### Release

To release a new version:

1. Update the version number in `lib/event_sourcery/version.rb`
2. Get this change onto master via the normal PR process
3. Run `gem_push=false bundle exec rake release`, this will create a git tag for the
   version, push tags up to GitHub, and package the code in a `.gem` file.
4. Manually upload the generated gem file (`pkg/event_sourcery-#{version}.gem`) to
   [rubygems.envato.com](https://rubygems.envato.com).

## Resources

Not sure what Event Sourcing (ES), Command Query Responsibility Segregation (CQRS), or even Domain-Driven Design (DDD) are? Here are a few links to get you started:

- [CQRS and Event Sourcing Talk](https://www.youtube.com/watch?v=JHGkaShoyNs) - by Greg Young at Code on the Beach 2014
- [DDD/CQRS Google Group](https://groups.google.com/forum/#!forum/dddcqrs) - from people new to the concepts to old hands
- [DDD Weekly Newsletter](https://buildplease.com/pages/dddweekly/) - a weekly digest of what's happening in the community
- [Domain-Driven Design](https://www.amazon.com/Domain-Driven-Design-Tackling-Complexity-Software/dp/0321125215) - the definitive guide
- [Greg Young's Blog](https://goodenoughsoftware.net) - a (the?) lead proponent of all things Event Sourcing
