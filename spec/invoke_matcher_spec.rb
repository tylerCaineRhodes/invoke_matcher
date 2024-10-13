# frozen_string_literal: true

RSpec.describe InvokeMatcher do
  it "has a version number" do
    expect(InvokeMatcher::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end

  let(:dummy_class) { Class.new { def something; "result"; end } }
  let(:dummy_instance) { dummy_class.new }
  let(:invocation_proc) { -> { dummy_instance.something } }

  it "checks method invocation with return value" do
    expect { invocation_proc.call }.to InvokeMatcher.invoke(:something)
      .on(dummy_instance)
      .and_call_original
      .and_return("result")
  end
end
