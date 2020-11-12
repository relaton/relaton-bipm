RSpec.describe RelatonBipm::EditorialGroup do
  it "warn when committee is invalid" do
    expect do
      RelatonBipm::EditorialGroup.new committee: ["INVAL"], workgroup: ["WG"]
    end.to output(/invalid committee/).to_stderr
  end
end
