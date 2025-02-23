# frozen_string_literal: true

require "forwardable"

module InvokeMatcher
  class Matcher
    extend Forwardable

    include RSpec::Mocks::ExampleMethods
    include RSpec::Matchers::Composable

    def_delegators :have_received_matcher, :failure_message, :failure_message_when_negated

    attr_reader :have_received_matcher, :expected_recipient, :expected_method

    def initialize(expected_method)
      @expected_method = expected_method
      @have_received_matcher = RSpec::Mocks::Matchers::HaveReceived.new(expected_method)
    end

    def description
      "invoke #{expected_method} on #{expected_recipient.inspect}"
    end

    def matches?(event_proc)
      ensure_recipient_is_defined!
      set_method_expectation
      setup_return_value_check if defined?(@expected_return)
      
      event_proc.call
      have_received_matcher.matches?(expected_recipient)
    end

    def does_not_match?(event_proc)
      ensure_recipient_is_defined!
      set_method_expectation
      event_proc.call
      have_received_matcher.does_not_match?(expected_recipient)
    end

    def on(expected_recipient)
      @expected_recipient = expected_recipient
      self
    end

    def with(*args, **kwargs)
      have_received_matcher.with(*args, **kwargs)
      self
    end

    def and_call_original
      @call_original = true
      self
    end

    def and_expect_return(expected_value)
      @expected_return = expected_value
      self
    end

    def method_missing(name, ...)
      ensure_recipient_is_defined!
      return super unless have_received_matcher.respond_to?(name)

      @have_received_matcher = have_received_matcher.public_send(name, ...)
      self
    end

    def respond_to_missing?(name, include_private = false)
      have_received_matcher.respond_to?(name, include_private)
    end

    def supports_block_expectations?
      true
    end

    private

    def ensure_recipient_is_defined!
      raise ArgumentError, "missing `on`" unless defined?(expected_recipient)
    end

    def set_method_expectation
      allow(expected_recipient).to receive(expected_method)
    end

    def setup_return_value_check
      allow(expected_recipient).to receive(expected_method) do |*args, **kwargs|
        actual_value = expected_recipient.method(expected_method).super_method.call(*args, **kwargs)
        verify_return_value(actual_value)
        actual_value
      end
    end

    def verify_return_value(actual_value)
      return if actual_value == @expected_return

      raise RSpec::Expectations::ExpectationNotMetError,
        "expected #{expected_method} to return #{@expected_return.inspect} but got #{actual_value.inspect}"
    end
  end

  def invoke(expected_method)
    Matcher.new(expected_method)
  end
end

RSpec::Matchers.define_negated_matcher :not_invoke, :invoke
