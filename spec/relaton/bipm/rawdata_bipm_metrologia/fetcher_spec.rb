require "relaton/bipm/rawdata_bipm_metrologia/fetcher"
require "relaton/bipm/data_fetcher"

describe Relaton::Bipm::RawdataBipmMetrologia::Fetcher do
  it "create instance and fetch" do
    fetcher = double "fetcher"
    expect(fetcher).to receive(:fetch)
    expect(described_class).to receive(:new).with(:data_fetcher).and_return fetcher
    described_class.fetch(:data_fetcher)
  end

  context "instance methods" do
    let(:index) { double "index" }
    let(:errors) { Hash.new(true) }
    let(:data_fetcher) { instance_double Relaton::Bipm::DataFetcher, output: "output", ext: "yaml", index: index, errors: errors }
    subject { described_class.new data_fetcher }

    context "fetch_metrologia" do
      it "with volume" do
        expect(data_fetcher).to receive(:write_file) do |path, item|
          expect(path).to eq "output/metrologia-1a.yaml"
          expect(item).to be_instance_of Relaton::Bipm::ItemData
          expect(item.formattedref.content).to eq "Metrologia 1A"
          expect(item.docidentifier[0].content).to eq "Metrologia 1A"
          expect(item.docidentifier[0].type).to eq "BIPM"
          expect(item.docidentifier[0].primary).to be true
          expect(item.relation).to be_instance_of Array
          expect(item.source[0].content.to_s).to eq "https://iopscience.iop.org/volume/0026-1394/1A"
          expect(item.source[0].type).to eq "src"
        end
        expect(index).to receive(:add_or_update).with({ group: "Metrologia", number: "1A" }, "output/metrologia-1a.yaml")
        subject.fetch_metrologia "volume_1A"
      end

      it "with volume and issue" do
        expect(data_fetcher).to receive(:write_file) do |path, item|
          expect(path).to eq "output/metrologia-1-2.yaml"
          expect(item).to be_instance_of Relaton::Bipm::ItemData
          expect(item.formattedref.content).to eq "Metrologia 1 2"
          expect(item.docidentifier[0].content).to eq "Metrologia 1 2"
          expect(item.docidentifier[0].type).to eq "BIPM"
          expect(item.docidentifier[0].primary).to be true
          expect(item.relation).to be_instance_of Array
          expect(item.source[0].content.to_s).to eq "https://iopscience.iop.org/issue/0026-1394/1/2"
          expect(item.source[0].type).to eq "src"
        end
        expect(index).to receive(:add_or_update).with({ group: "Metrologia", number: "1 2" }, "output/metrologia-1-2.yaml")
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

    it "fetch_articles sorted by archive date" do
      path_old = "rawdata-bipm-metrologia/data/2021-01-01T00_00_00_content/0026-1394/art.xml"
      path_new = "rawdata-bipm-metrologia/data/2022-06-29T03_01_46_content/0026-1394/art.xml"
      expect(Dir).to receive(:[]).with("rawdata-bipm-metrologia/data/*content/0026-1394/**/*.xml")
        .and_return [path_new, path_old]
      docid = Relaton::Bib::Docidentifier.new(content: "Metrologia", type: "BIPM", primary: true)
      item = Relaton::Bipm::ItemData.new(docidentifier: [docid])
      # Expect parse to be called in sorted order: old first, then new
      expect(Relaton::Bipm::RawdataBipmMetrologia::NisoJatsParser).to receive(:parse)
        .with(path_old, errors).ordered.and_return item
      expect(Relaton::Bipm::RawdataBipmMetrologia::NisoJatsParser).to receive(:parse)
        .with(path_new, errors).ordered.and_return item
      expect(data_fetcher).to receive(:write_file).with("output/metrologia.yaml", item).twice
      expect(index).to receive(:add_or_update).with({ group: "Metrologia" }, "output/metrologia.yaml").twice
      subject.fetch_articles
    end

    it "archive_date extracts date from path" do
      path = "rawdata-bipm-metrologia/data/2022-06-29T03_01_46_content/0026-1394/art.xml"
      expect(subject.send(:archive_date, path)).to eq "2022-06-29T03_01_46"
    end

    it "archive_date returns empty string for non-matching path" do
      expect(subject.send(:archive_date, "some/other/path.xml")).to eq ""
    end

    it "docidentifier" do
      docid = subject.docidentifier("Metrologia 1A")
      expect(docid).to be_instance_of Array
      expect(docid[0]).to be_instance_of Relaton::Bib::Docidentifier
      expect(docid[0].content).to eq "Metrologia 1A"
      expect(docid[0].type).to eq "BIPM"
      expect(docid[0].primary).to be true
    end

    it "relation" do
      expect(Dir).to receive(:[])
        .with("rawdata-bipm-metrologia/data/*content/0026-1394/volume_1/issue_2/*")
        .and_return ["dir/volume_1/issue_2/article_3"]
      rel = subject.relation("volume_1", "issue_2")
      expect(rel).to be_instance_of Array
      expect(rel[0]).to be_instance_of Relaton::Bib::Relation
      expect(rel[0].type).to eq "partOf"
      expect(rel[0].bibitem).to be_instance_of Relaton::Bib::ItemData
      expect(rel[0].bibitem.docidentifier).to be_instance_of Array
      expect(rel[0].bibitem.docidentifier[0]).to be_instance_of Relaton::Bib::Docidentifier
      expect(rel[0].bibitem.docidentifier[0].content).to eq "Metrologia 1 2 3"
      expect(rel[0].bibitem.docidentifier[0].type).to eq "BIPM"
      expect(rel[0].bibitem.docidentifier[0].primary).to be true
      expect(rel[0].bibitem.formattedref.content).to eq "Metrologia 1 2 3"
    end

    context "typed_uri" do
      it "journal" do
        source = subject.typed_uri
        expect(source).to be_instance_of Array
        expect(source.size).to eq 1
        expect(source[0]).to be_instance_of Relaton::Bib::Uri
        expect(source[0].content.to_s).to eq "https://iopscience.iop.org/journal/0026-1394"
        expect(source[0].type).to eq "src"
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
