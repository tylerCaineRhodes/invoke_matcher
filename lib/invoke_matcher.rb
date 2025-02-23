# frozen_string_literal: true

require "forwardable"

module InvokeMatcher
  class Matcher
    extend Forwardable

    include RSpec::Mocks::ExampleMethods
    include RSpec::Matchers::Composable

    def_delegators :have_received_matcher, :failure_message, :failure_message_when_negated

    attr_reader :have_received_matcher, :expected_recipient

    def initialize(expected_method)
      @expected_method = expected_method
      @have_received_matcher = RSpec::Mocks::Matchers::HaveReceived.new(@expected_method)
    end

    def description
      "invoke #{@expected_method} on #{expected_recipient.inspect}"
    end

    def and_call_original
      @call_original = true
      self
    end

    def method_missing(name, ...)
      ensure_recipient_is_defined!
      return super unless respond_to_missing?(name)

      @have_received_matcher = have_received_matcher.public_send(name, ...)
      self
    end

    def respond_to_missing?(name, include_private = false)
      @have_received_matcher.respond_to?(name, include_private)
    end

    def matches?(event_proc)
      ensure_recipient_is_defined!
      set_method_expectation

      event_proc.call

      have_received_matcher.matches?(expected_recipient) && matches_result?
    end

    def set_method_expectation
      expectation = allow(expected_recipient).to receive(@expected_method)
      expectation.and_call_original if @call_original
      
      if !testing_double? && defined?(@args) && defined?(@kwargs)
        @actual_result = expected_recipient.send(@expected_method, *@args, **@kwargs)
      end
    end

    def testing_double?
      @expected_recipient.is_a?(RSpec::Mocks::Double) ||
        @expected_recipient.is_a?(RSpec::Mocks::InstanceVerifyingDouble) ||
        @expected_recipient.is_a?(RSpec::Mocks::ObjectVerifyingDouble)
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
      @args = args
      @kwargs = kwargs

      have_received_matcher.with(*args, **kwargs)
      self
    end

    def supports_block_expectations?
      true
    end

    def matches_result?
      return true unless defined?(@expected_return_value)

      values_match?(@expected_return_value, @actual_result)
    end

    def and_expect_return(expected_return_value)
      @expected_return_value = expected_return_value
      self
    end

    private

    def ensure_recipient_is_defined!
      raise ArgumentError, "missing `on`" unless defined?(expected_recipient)
    end

    def call_original(matcher)
      @call_original ? matcher.and_call_original : matcher
    end
  end

  def invoke(expected_method)
    InvokeMatcher::Matcher.new(expected_method)
  end
end

RSpec::Matchers.define_negated_matcher :not_invoke, :invoke
