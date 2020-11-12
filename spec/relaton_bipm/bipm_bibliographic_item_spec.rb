RSpec.describe RelatonBipm::BipmBibliographicItem do
  it "warn when si_aspect is invalid" do
    expect do
      RelatonBipm::BipmBibliographicItem.new si_aspect: "aspect"
    end.to output(/invalid si_aspect/).to_stderr
  end
end
