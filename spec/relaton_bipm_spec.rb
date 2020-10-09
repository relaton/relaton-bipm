RSpec.describe RelatonBipm do
  it "has a version number" do
    expect(RelatonBipm::VERSION).not_to be nil
  end

  it "retur grammar hash" do
    hash = RelatonBipm.grammar_hash
    expect(hash).to be_instance_of String
    expect(hash.size).to eq 32
  end

  it "search a code" do
    VCR.use_cassette "si_brochure" do
      result = RelatonBipm::BipmBibliography.search "BIPM si-brochure"
      expect(result).to be_instance_of RelatonBipm::BipmBibliographicItem
    end
  end

  context "get document" do
    it "by code" do
      VCR.use_cassette "si_brochure" do
        file = "spec/fixtures/si_brochure.xml"
        result = RelatonBipm::BipmBibliography.get "BIPM si-brochure"
        xml = result.to_xml bibdata: true
        File.write file, xml, encoding: "UTF-8" unless File.exist? file
        expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
      end
    end
  end
end
