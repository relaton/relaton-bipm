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
    expect(Relaton::Index).to receive(:find_or_create).with(:bipm, file: "index2.yaml").and_return({})
    fetcher = described_class.new "data", "bibxml"
    expect(fetcher.instance_variable_get(:@output)).to eq "data"
    expect(fetcher.instance_variable_get(:@format)).to eq "bibxml"
    expect(fetcher.instance_variable_get(:@ext)).to eq "xml"
    expect(fetcher.instance_variable_get(:@files)).to eq []
    expect(fetcher.instance_variable_get(:@index2)).to eq({})
  end

  context "instance methods" do
    subject { described_class.new "data", "yaml" }

    # before :each do
    #   expect(File).to receive(:exist?).with("index.yaml").and_return false
    #   allow(File).to receive(:exist?).and_call_original
    # end

    context "#fetch" do
      before(:each) do
        index2 = subject.instance_variable_get(:@index2)
        expect(index2).to receive(:save)
      end

      it "bipm-datata-outcomes" do
        expect(RelatonBipm::DataOutcomesParser).to receive(:parse).with subject
        subject.fetch "bipm-data-outcomes"
      end

      it "bipm-si-brochure" do
        expect(RelatonBipm::BipmSiBrochureParser).to receive(:parse).with subject
        subject.fetch "bipm-si-brochure"
      end

      it "rawdata-bipm-metrologia" do
        expect(RelatonBipm::RawdataBipmMetrologia::Fetcher).to receive(:fetch).with subject
        subject.fetch "rawdata-bipm-metrologia"
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

    context "#serialize" do
      it "xml" do
        subject.instance_variable_set(:@format, "xml")
        item = double "item"
        expect(item).to receive(:to_xml).with(bibdata: true).and_return :xml
        expect(subject.serialize(item)).to eq :xml
      end

      it "yaml" do
        item = double "item", to_hash: {}
        expect(subject.serialize(item)).to eq "--- {}\n"
      end

      it "bibxml" do
        subject.instance_variable_set(:@format, "bibxml")
        item = double "item", to_bibxml: "<bibxml/>"
        expect(subject.serialize(item)).to eq "<bibxml/>"
      end
    end
  end
end
