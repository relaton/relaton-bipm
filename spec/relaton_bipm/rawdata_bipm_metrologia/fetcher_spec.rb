describe RelatonBipm::RawdataBipmMetrologia::Fetcher do
  it "create instance and fetch" do
    fetcher = double "fetcher"
    expect(fetcher).to receive(:fetch)
    expect(described_class).to receive(:new).with(:data_fetcher).and_return fetcher
    described_class.fetch(:data_fetcher)
  end

  context "instance methods" do
    let(:index2) { double "index2" }
    let(:data_fetcher) { double "data_fetcher", output: "output", ext: "yaml", index2: index2 }
    subject { described_class.new data_fetcher }

    context "fetch_metrologia" do
      before do
        expect(RelatonBipm::BipmBibliographicItem).to receive(:new).with(
          type: "article", formattedref: :fref, docid: :did, language: ["en"],
          script: ["Latn"], relation: [:rel], link: :uri
        ).and_return(:item)
      end

      it "with volume" do
        expect(subject).to receive(:formattedref).with("Metrologia 1A").and_return(:fref)
        expect(subject).to receive(:docidentifier).with("Metrologia 1A").and_return(:did)
        expect(subject).to receive(:relation).with("volume_1A").and_return([:rel])
        expect(subject).to receive(:typed_uri).with("volume_1A").and_return(:uri)
        expect(data_fetcher).to receive(:write_file).with("output/metrologia-1a.yaml", :item)
        expect(index2).to receive(:add_or_update).with({ group: "Metrologia", number: "1A" }, "output/metrologia-1a.yaml")
        subject.fetch_metrologia "volume_1A"
      end

      it "with volume and issue" do
        expect(subject).to receive(:formattedref).with("Metrologia 1 2").and_return(:fref)
        expect(subject).to receive(:docidentifier).with("Metrologia 1 2").and_return(:did)
        expect(subject).to receive(:relation).with("volume_1", "issue_2").and_return([:rel])
        expect(subject).to receive(:typed_uri).with("volume_1", "issue_2").and_return(:uri)
        expect(data_fetcher).to receive(:write_file).with("output/metrologia-1-2.yaml", :item)
        expect(index2).to receive(:add_or_update).with({ group: "Metrologia", number: "1 2" }, "output/metrologia-1-2.yaml")
        subject.fetch_metrologia "volume_1", "issue_2"
      end
    end

    it "fetch" do
      expect(subject).to receive(:fetch_metrologia).with(no_args)
      expect(subject).to receive(:fetch_volumes).with(no_args)
      expect(subject).to receive(:fetch_issues).with(no_args)
      expect(subject).to receive(:fetch_articles).with(no_args)
      subject.fetch
    end

    it "fetch_volumes" do
      expect(Dir).to receive(:[]).with("rawdata-bipm-metrologia/data/*content/0026-1394/*").and_return ["dir/volume"]
      expect(subject).to receive(:fetch_metrologia).with("volume")
      subject.fetch_volumes
    end

    it "fetch_issues" do
      expect(Dir).to receive(:[]).with("rawdata-bipm-metrologia/data/*content/0026-1394/*/*").and_return ["dir/volume/issue"]
      expect(subject).to receive(:fetch_metrologia).with("volume", "issue")
      subject.fetch_issues
    end

    it "fetch_articles" do
      expect(Dir).to receive(:[]).with("rawdata-bipm-metrologia/data/*content/0026-1394/**/*.xml").and_return [:path]
      item = double "item", docidentifier: [double(id: "Metrologia")]
      expect(RelatonBipm::RawdataBipmMetrologia::NisoJatsParser).to receive(:parse).with(:path).and_return item
      expect(data_fetcher).to receive(:write_file).with("output/metrologia.yaml", item)
      expect(index2).to receive(:add_or_update).with({ group: "Metrologia" }, "output/metrologia.yaml")
      subject.fetch_articles
    end

    it "formattedref" do
      fr = subject.formattedref("Metrologia 1A")
      expect(fr).to be_instance_of RelatonBib::FormattedRef
      expect(fr.content).to eq "Metrologia 1A"
      expect(fr.language).to eq ["en"]
      expect(fr.script).to eq ["Latn"]
    end

    it "docidentifier" do
      docid = subject.docidentifier("Metrologia 1A")
      expect(docid).to be_instance_of Array
      expect(docid[0]).to be_instance_of RelatonBib::DocumentIdentifier
      expect(docid[0].id).to eq "Metrologia 1A"
      expect(docid[0].type).to eq "BIPM"
      expect(docid[0].primary).to be true
    end

    it "relation" do
      expect(Dir).to receive(:[])
        .with("rawdata-bipm-metrologia/data/*content/0026-1394/volume_1/issue_2/*")
        .and_return ["dir/volume_1/issue_2/article_3"]
      rel = subject.relation("volume_1", "issue_2")
      expect(rel).to be_instance_of Array
      expect(rel[0]).to be_instance_of RelatonBib::DocumentRelation
      expect(rel[0].type).to eq "partOf"
      expect(rel[0].bibitem).to be_instance_of RelatonBipm::BipmBibliographicItem
      expect(rel[0].bibitem.docidentifier).to be_instance_of Array
      expect(rel[0].bibitem.docidentifier[0]).to be_instance_of RelatonBib::DocumentIdentifier
      expect(rel[0].bibitem.docidentifier[0].id).to eq "Metrologia 1 2 3"
      expect(rel[0].bibitem.docidentifier[0].type).to eq "BIPM"
      expect(rel[0].bibitem.docidentifier[0].primary).to be true
      expect(rel[0].bibitem.formattedref).to be_instance_of RelatonBib::FormattedRef
      expect(rel[0].bibitem.formattedref.content).to eq "Metrologia 1 2 3"
      expect(rel[0].bibitem.formattedref.language).to eq ["en"]
      expect(rel[0].bibitem.formattedref.script).to eq ["Latn"]
    end

    context "typed_uri" do
      it "journal" do
        link = subject.typed_uri
        expect(link).to be_instance_of Array
        expect(link.size).to eq 1
        expect(link[0]).to be_instance_of RelatonBib::TypedUri
        expect(link[0].content.to_s).to eq "https://iopscience.iop.org/journal/0026-1394"
        expect(link[0].type).to eq "src"
      end
      it "with volume" do
        link = subject.typed_uri("volume_1")
        expect(link[0].content.to_s).to eq "https://iopscience.iop.org/volume/0026-1394/1"
      end

      it "with volume and issue" do
        link = subject.typed_uri("volume_1", "issue_2")
        expect(link[0].content.to_s).to eq "https://iopscience.iop.org/issue/0026-1394/1/2"
      end
    end
  end
end
