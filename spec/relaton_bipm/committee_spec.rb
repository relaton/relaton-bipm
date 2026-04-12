RSpec.describe RelatonBipm::Committee do
  it "warn when an acronym is invalid" do
    expect do
      described_class.new acronym: "INVAL"
    end.to output(/Invalid acronym/).to_stderr_from_any_process
  end

  it "not warn when an acronym is valid" do
    expect do
      described_class.new acronym: "CCL-CCTF-WGFS"
    end.not_to output.to_stderr_from_any_process
  end
end
