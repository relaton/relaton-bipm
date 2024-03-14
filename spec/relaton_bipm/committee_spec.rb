RSpec.describe RelatonBipm::Committee do
  it "warn when an acronym is invalid" do
    expect do
      RelatonBipm::Committee.new acronym: "INVAL"
    end.to output(/Invalid acronym/).to_stderr_from_any_process
  end
end
