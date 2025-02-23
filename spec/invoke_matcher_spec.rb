# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
RSpec.describe InvokeMatcher do
  let(:dummy_class) { Class.new { def something = "result" } }
  let(:dummy_instance) { dummy_class.new }
  let(:invocation_proc) { -> { dummy_instance.something } }

  it "has a version number" do
    expect(InvokeMatcher::VERSION).not_to be nil
  end

  context "when testing invocation with original call" do
    specify do
      expect { invocation_proc.call }.to invoke(:something)
        .on(dummy_instance)
        .and_call_original
    end
  end

  context "when testing invocation with return value" do
    specify do
      expect { invocation_proc.call }.to invoke(:something)
        .on(dummy_instance)
        .and_expect_return("result")
    end
  end

  context "when the method is invoked indirectly" do
    let(:parent_class) do
      Class.new do
        def initialize(dummy_instance)
          @dummy_instance = dummy_instance
        end

        def call_dummy
          @dummy_instance.something
        end
      end
    end

    let(:parent_instance) { parent_class.new(dummy_instance) }

    specify do
      expect { parent_instance.call_dummy }.to invoke(:something)
        .on(dummy_instance)
        .and_expect_return("result")
    end

    it "raises an error when the expected return value does not match" do
      expect do
        expect { parent_instance.call_dummy }.to invoke(:something)
          .on(dummy_instance)
          .and_expect_return("b")
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end
  end

  context "when checking method is not invoked" do
    let(:unrelated_method_proc) { -> { "some other result" } }

    specify do
      expect { unrelated_method_proc.call }.to not_invoke(:something).on(dummy_instance)
    end
  end

  context "when checking multiple invocations" do
    specify do
      expect { 3.times { dummy_instance.something } }.to invoke(:something)
        .on(dummy_instance)
        .at_least(3).times
    end
  end

  context "when testing method arguments" do
    let(:dummy_class) do
      Class.new do
        def greet(name, times: 1)
          "Hello #{name}" * times
        end
      end
    end

    it "matches positional arguments" do
      expect { dummy_instance.greet("Alice") }.to invoke(:greet)
        .with("Alice")
        .on(dummy_instance)
    end

    it "matches keyword arguments" do
      expect { dummy_instance.greet("Bob", times: 2) }.to invoke(:greet)
        .with("Bob", times: 2)
        .on(dummy_instance)
    end

    it "fails when arguments don't match" do
      expect do
        expect { dummy_instance.greet("Alice", times: 1) }.to invoke(:greet)
          .with("Bob", times: 2)
          .on(dummy_instance)
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end

    it "matches return value with arguments" do
      expect { dummy_instance.greet("Alice", times: 2) }.to invoke(:greet)
        .with("Alice", times: 2)
        .on(dummy_instance)
        .and_expect_return("Hello Alice" * 2)
    end

    it "fails when return value doesn't match" do
      expect do
        expect { dummy_instance.greet("Alice", times: 2) }.to invoke(:greet)
          .with("Alice", times: 2)
          .on(dummy_instance)
          .and_expect_return("Wrong return value")
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end
  end
end
# rubocop:enable Metrics/BlockLength
