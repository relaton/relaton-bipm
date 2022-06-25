describe RelatonBipm::Index do
  it "create from GitHub repo" do
    VCR.use_cassette "index" do
      expect(File).to receive(:exist?).with(/index\.yaml/).and_return false
      allow(File).to receive(:exist?).and_call_original
      expect(File).to receive(:write).with(/index\.yaml/, kind_of(String), encoding: "UTF-8")
      expect(subject.instance_variable_get(:@index)).to be_instance_of Hash
    end
  end

  context "create from file" do
    before(:each) do
      expect(File).to receive(:exist?).with(/index\.yaml/).and_return true
      expect(File).to receive(:ctime).with(/index\.yaml/).and_return Time.now
      expect(File).to receive(:read).with(/index\.yaml/, encoding: "UTF-8").and_return <<~YAML
        ---
        ? - CCTF Meeting 5
        : data/cctf/meeting/5.yaml
        ? - CCTF Recommendation 1970-2
          - CCTF Recommendation 5-2
        : data/cctf/meeting/recommendation/1970-02.yaml
      YAML
    end

    it "parse index" do
      expect(subject.instance_variable_get(:@index)).to eq(
        {
          ["CCTF Meeting 5"] => "data/cctf/meeting/5.yaml",
          ["CCTF Recommendation 1970-2", "CCTF Recommendation 5-2"] => "data/cctf/meeting/recommendation/1970-02.yaml",
        },
      )
    end
  end
end
