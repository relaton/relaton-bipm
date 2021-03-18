RSpec.describe RelatonBipm::BipmBibliographicItem do
  it "warn when si_aspect is invalid" do
    expect do
      RelatonBipm::BipmBibliographicItem.new si_aspect: "aspect"
    end.to output(/invalid si_aspect/).to_stderr
  end

  it "warning when docstatus is invalid" do
    expect do
      RelatonBipm::BipmBibliographicItem.new docstatus: RelatonBib::DocumentStatus.new(stage: "status")
    end.to output(/\[relaton-bipm\] Warning: invalid docstatus: status/).to_stderr
  end
end
