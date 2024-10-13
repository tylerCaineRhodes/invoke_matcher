# frozen_string_literal: true

module InvokeMatcher
  class Matcher
    include RSpec::Mocks::ExampleMethods

    attr_reader :expected_method, :have_received_matcher, :expected_recipient, :expected_return_value

    def initialize(expected_method)
      @expected_method = expected_method
      @have_received_matcher = RSpec::Mocks::Matchers::HaveReceived.new(expected_method)
      @expected_recipient = nil
      @expected_return_value = nil
    end

    def description
      "invoke #{expected_method} on #{expected_recipient.inspect}"
    end

    def and_return(expected_value)
      @expected_return_value = expected_value
      self
    end

    def method_missing(name, *args, &block)
      if respond_to_missing?(name)
        @have_received_matcher = have_received_matcher.public_send(name, *args, &block)
        self
      else
        super
      end
    end

    def and_call_original
      @call_original = true
      self
    end

    def call_original(matcher)
      @call_original ? matcher.and_call_original : matcher
    end

    def respond_to_missing?(name, include_private = false)
      have_received_matcher.respond_to?(name, include_private)
    end

    def matches?(event_proc)
      ensure_recipient_is_defined!
      set_method_expectation

      actual_return_value = event_proc.call

      matches_result?(actual_return_value) && have_received_matcher.matches?(expected_recipient)
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

    def failure_message
      have_received_matcher.failure_message
    end

    def failure_message_when_negated
      have_received_matcher.failure_message_when_negated
    end

    def supports_block_expectations?
      true
    end

    private

    def ensure_recipient_is_defined!
      raise ArgumentError, 'missing `on`' unless defined?(expected_recipient)
    end

    def set_method_expectation
      unless testing_double?
        allow(expected_recipient).to receive(expected_method).and_return(@expected_return_value)
      end
    end

    def testing_double?
      expected_recipient.is_a?(RSpec::Mocks::Double) ||
      expected_recipient.is_a?(RSpec::Mocks::InstanceVerifyingDouble) ||
      expected_recipient.is_a?(RSpec::Mocks::ObjectVerifyingDouble)
    end

    def matches_result?(actual_return_value)
      return true unless defined?(@expected_return_value)

      values_match?(@expected_return_value, actual_return_value)
    end

    def values_match?(expected, actual)
      expected == actual
    end
  end

  def invoke(expected_method)
    Matcher.new(expected_method)
  end
end

RSpec::Matchers.define_negated_matcher :not_invoke, :invoke
