describe RelatonBipm::DataFetcher do
  it "call new and fetch" do
    # expect(Dir).to receive(:exist?).with("data").and_return false
    expect(FileUtils).to receive(:mkdir_p).with("data")
    fetcher = double("fetcher")
    expect(fetcher).to receive(:fetch).with "bipm-data-outcomes"
    expect(described_class).to receive(:new).with("data", "yaml").and_return fetcher
    described_class.fetch "bipm-data-outcomes"
  end

  it "initialize" do
    expect(File).to receive(:exist?).with("index.yaml").and_return true
    expect(YAML).to receive(:load_file).with("index.yaml").and_return({})
    fetcher = described_class.new "data", "bibxml"
    expect(fetcher.instance_variable_get(:@output)).to eq "data"
    expect(fetcher.instance_variable_get(:@format)).to eq "bibxml"
    expect(fetcher.instance_variable_get(:@ext)).to eq "xml"
    expect(fetcher.instance_variable_get(:@files)).to eq []
    expect(fetcher.instance_variable_get(:@index_path)).to eq "index.yaml"
    expect(fetcher.instance_variable_get(:@index)).to eq({})
  end

  context "instance methods" do
    subject { described_class.new "data", "yaml" }

    before :each do
      expect(File).to receive(:exist?).with("index.yaml").and_return false
      allow(File).to receive(:exist?).and_call_original
    end

    context "#fetch" do
      before(:each) do
        expect(File).to receive(:write).with("index.yaml", "--- {}\n", encoding: "UTF-8")
      end

      it "bipm-datata-outcomes" do
        expect(RelatonBipm::DataOutcomesParser).to receive(:parse).with subject
        subject.fetch "bipm-data-outcomes"
      end

      it "bipm-si-brochure" do
        expect(RelatonBipm::BipmSiBrochureParser).to receive(:parse).with subject
        subject.fetch "bipm-si-brochure"
      end
    end

    context "#write_file" do
      let(:item) do
        item = double "item"
        hash = double "hash"
        expect(hash).to receive(:to_yaml).and_return :yaml
        expect(item).to receive(:to_hash).and_return hash
        item
      end

      let(:path) { "data/cgpm/meeting/1889-00.yaml" }

      before :each do
        expect(File).to receive(:write).with(path, :yaml, encoding: "UTF-8")
      end

      it "without duplicate" do
        subject.write_file path, item
        expect(subject.instance_variable_get(:@files)).to eq [path]
      end

      it "with duplicate" do
        expect do
          subject.instance_variable_set(:@files, [path])
          subject.write_file path, item
        end.to output("File #{path} already exists\n").to_stderr
      end

      it "with duplicate and warn_duplicate: false" do
        expect do
          subject.instance_variable_set(:@files, [path])
          subject.write_file path, item, warn_duplicate: false
        end.not_to output("File #{path} already exists\n").to_stderr
      end
    end
  end
end
