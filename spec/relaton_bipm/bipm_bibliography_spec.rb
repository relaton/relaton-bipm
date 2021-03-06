require "jing"

RSpec.describe RelatonBipm::BipmBibliography do
  it "raise ReauestError" do
    expect(Net::HTTP).to receive(:get_response).and_raise SocketError
    expect do
      RelatonBipm::BipmBibliography.search "ref"
    end.to raise_error RelatonBib::RequestError
  end

  context "bib instance" do
    subject do
      hash = YAML.load_file "spec/fixtures/bipm_item.yml"
      bib_hash = RelatonBipm::HashConverter.hash_to_bib hash
      RelatonBipm::BipmBibliographicItem.new bib_hash
    end

    it "returns XML" do
      file = "spec/fixtures/bipm_item.xml"
      xml = subject.to_xml bibdata: true
      File.write file, xml, encoding: "UTF-8" unless File.exist? file
      expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
      schema = Jing.new "spec/fixtures/isobib.rng"
      errors = schema.validate file
      expect(errors).to eq []
    end

    it "returns Hash" do
      hash = subject.to_hash
      file = "spec/fixtures/bipm.yaml"
      File.write file, hash.to_yaml, encoding: "UTF-8" unless File.exist? file
      expect(hash).to eq YAML.load_file file
    end

    it "returns AsciiBib" do
      bib = subject.to_asciibib
      file = "spec/fixtures/asciibib.adoc"
      File.write file, bib, encoding: "UTF-8" unless File.exist? file
      expect(bib).to eq File.read(file, encoding: "UTF-8")
    end
  end
end
