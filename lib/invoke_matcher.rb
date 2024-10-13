# frozen_string_literal: true

require_relative "invoke_matcher/version"
require "rspec"

module InvokeMatcher
  class Matcher
    attr_reader :expected_method, :have_received_matcher, :expected_recipient, :call_original

    def initialize(expected_method)
      @expected_method = expected_method
      @have_received_matcher = RSpec::Mocks::Matchers::HaveReceived.new(expected_method)
      @call_original = false
    end

    def description
      "invoke #{expected_method} on #{expected_recipient.inspect}"
    end

    def and_call_original
      @call_original = true
      self
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

    def respond_to_missing?(name, include_private = false)
      have_received_matcher.respond_to?(name, include_private)
    end

    def matches?(event_proc)
      ensure_recipient_is_defined!
      set_method_expectation

      event_proc.call

      matches_result? && have_received_matcher.matches?(expected_recipient)
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
        expectation = allow(expected_recipient).to receive(expected_method)
        expectation.and_call_original if call_original
      end
    end

    def testing_double?
      expected_recipient.is_a?(RSpec::Mocks::Double) ||
        expected_recipient.is_a?(RSpec::Mocks::InstanceVerifyingDouble) ||
        expected_recipient.is_a?(RSpec::Mocks::ObjectVerifyingDouble)
    end

    def matches_result?
      return true unless defined?(@expected_return_value)

      actual_return_value = expected_recipient.send(expected_method)
      values_match?(@expected_return_value, actual_return_value)
    end
  end

  def self.invoke(expected_method)
    Matcher.new(expected_method)
  end
end
