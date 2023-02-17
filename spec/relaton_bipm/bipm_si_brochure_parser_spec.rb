describe RelatonBipm::BipmSiBrochureParser do
  context "class methods" do
    it "::parse" do
      data_parser = double "data_parser"
      expect(data_parser).to receive(:parse)
      expect(described_class).to receive(:new).and_return data_parser
      described_class.parse :data_fetcher
    end
  end

  context "instance methods" do
    let(:data_fetcher) { double "data_fetcher", output: "data", ext: "yaml", files: [], index: {} }
    subject { described_class.new data_fetcher }

    it "#parse_si_brochure" do
      allow(File).to receive(:exist?).and_call_original
      expect(Dir).to receive(:[]).with("bipm-si-brochure/_site/documents/*.rxl")
        .and_return [
          "spec/fixtures/si_brochure/si-brochure-en.rxl",
          "spec/fixtures/si_brochure/si-brochure-fr.rxl",
        ]
      expect(File).to receive(:exist?).with("data/si-brochure.yaml").and_return false, true

      expect(data_fetcher).to receive(:write_file) do |path, item, opt|
        expect(path).to eq "data/si-brochure.yaml"
        p = if opt[:warn_duplicate]
              "spec/fixtures/#{path.sub('brochure', 'brochure_1')}"
            else
              "spec/fixtures/#{path}"
            end
        hash = item.to_hash
        File.write p, hash.to_yaml, encoding: "UTF-8" unless File.exist? p
        yaml = YAML.load_file(p)
        expect(hash).to eq yaml
      end.twice

      allow(YAML).to receive(:load_file).and_wrap_original do |m, path|
        m.call path.sub(/^data\/si-brochure\.yaml/, "spec/fixtures/data/si-brochure_1.yaml")
      end

      subject.parse
      expect(data_fetcher.index).to eq ["SI Brochure"] => "data/si-brochure.yaml"
    end

    it "#fix_si_brochure_id" do
      hash = {
        "id" => "BIPMBrochure", "docnumber" => "Brochure",
        "docid" => [{ "type" => "BIPM", "id" => "BIPM Brochure" }]
      }
      subject.fix_si_brochure_id hash
      expect(hash["id"]).to eq "BIPMSIBrochureAppendix4"
      expect(hash["docnumber"]).to eq "SI Brochure, Appendix 4"
      expect(hash["docid"]).to eq(
        [{ "type" => "BIPM", "id" => "BIPM SI Brochure, Appendix 4", "primary" => true }],
      )
    end
  end
end
