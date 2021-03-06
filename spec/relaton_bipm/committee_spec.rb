RSpec.describe RelatonBipm::Committee do
  it "warn when an acronym is invalid" do
    expect do
      RelatonBipm::Committee.new acronym: "INVAL"
    end.to output(/invalid acronym/).to_stderr
  end
end
