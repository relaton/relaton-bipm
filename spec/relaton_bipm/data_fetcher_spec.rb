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
        expect(subject).to receive(:parse_bipm_data_outcomes)
        subject.fetch "bipm-data-outcomes"
      end

      it "bipm-si-brochure" do
        expect(subject).to receive(:parse_si_brochure)
        subject.fetch "bipm-si-brochure"
      end
    end

    it "#fetch_bipm_data_outcomes" do
      expect(Dir).to receive(:[]).with("bipm-data-outcomes/{cctf,cgpm,cipm}").and_return ["bipm-data-outcomes/cgpm"]
      expect(subject).to receive(:fetch_body).with("bipm-data-outcomes/cgpm")
      subject.parse_bipm_data_outcomes
    end

    it "#fetch_body" do
      expect(Dir).to receive(:[]).with("cgpm/*-en").and_return ["cgpm/meetings-en"]
      expect(subject).to receive(:fetch_type).with("cgpm/meetings-en", "CGPM")
      subject.fetch_body "cgpm"
    end

    it "#fetch_type" do
      expect(FileUtils).to receive(:mkdir_p).with("data/cgpm")
      expect(FileUtils).to receive(:mkdir_p).with("data/cgpm/meeting")
      expect(Dir).to receive(:[]).with("cgpm/meetings-en/*.{yml,yaml}").and_return ["cgpm/meetings-en/1.yml"]
      expect(subject).to receive(:fetch_meeting).with("cgpm/meetings-en/1.yml", "CGPM", "meeting", "data/cgpm/meeting")
      subject.fetch_type("cgpm/meetings-en", "CGPM")
    end

    context "#fetch_meeting" do
      it "no part" do
        expect(subject).to receive(:write_file) do |path, item|
          expect(path).to eq "data/cgpm/meeting/1.yaml"
          hash = item.to_hash
          file = "spec/fixtures/#{path}"
          File.write file, hash.to_yaml, encoding: "UTF-8" unless File.exist? file
          yaml = YAML.load_file(file)
          yaml["fetched"] = Date.today.to_s
          expect(hash).to eq yaml
        end
        expect(subject).to receive(:fetch_resolution).with(
          body: "CGPM", en: kind_of(Hash), fr: kind_of(Hash),
          dir: "data/cgpm/meeting", src: kind_of(Array), num: "1"
        )
        subject.fetch_meeting "spec/fixtures/cgpm/meetings-en/meeting-01.yml", "CGPM", "meeting", "data/cgpm/meeting"
      end

      it "with part" do
        allow(File).to receive(:read).and_wrap_original do |method, f, **args|
          file = f == "data/cipm/meeting/101.yaml" ? "spec/fixtures/#{f.sub("101", "101_1")}" : f
          method.call file, **args
        end
        ["data/cipm/meeting/101-1.yaml", "data/cipm/meeting/101.yaml",
         "data/cipm/meeting/101.yaml", "data/cipm/meeting/101-2.yaml"].each do |expect_path|
          expect(subject).to receive(:write_file) do |path, item, **args|
            expect(path).to eq expect_path
            if item.relation.size == 1
              subject.instance_variable_get(:@files) << path
              file = "spec/fixtures/#{path.sub('101.', '101_1.')}"
            else
              expect(args[:warn_duplicate]).to be item.relation.empty? && nil
              file = "spec/fixtures/#{path}"
            end
            hash = item.to_hash
            hash["fetched"] = Date.today.to_s
            hash["relation"]&.each { |rel| rel["bibitem"]["fetched"] = Date.today.to_s }
            File.write file, hash.to_yaml, encoding: "UTF-8" unless File.exist? file
            yaml = YAML.load_file(file)
            yaml["fetched"] = Date.today.to_s
            yaml["relation"]&.each { |rel| rel["bibitem"]["fetched"] = Date.today.to_s }
            expect(hash).to eq yaml
          end
        end

        expect(subject).to receive(:fetch_resolution).with(
          body: "CIPM", en: kind_of(Hash), fr: kind_of(Hash),
          dir: "data/cipm/meeting", src: kind_of(Array), num: /\d+/
        ).twice

        subject.fetch_meeting "spec/fixtures/cipm/meetings-en/meeting-101-1.yml", "CIPM", "meeting", "data/cipm/meeting"
        subject.fetch_meeting "spec/fixtures/cipm/meetings-en/meeting-101-2.yml", "CIPM", "meeting", "data/cipm/meeting"
        expect(subject.instance_variable_get(:@index)).to eq(
          {
            ["CIPM Meeting 101"] => "data/cipm/meeting/101.yaml",
            ["CIPM Meeting 101-1"] => "data/cipm/meeting/101-1.yaml",
            ["CIPM Meeting 101-2"] => "data/cipm/meeting/101-2.yaml",
          },
        )
      end
    end

    context "#fetch_resolution" do
      it "one resolution" do
        expect(FileUtils).to receive(:mkdir_p).with("data/cgpm/meeting/resolution")
        expect(subject).to receive(:write_file) do |path, item|
          expect(path).to eq "data/cgpm/meeting/resolution/1889-00.yaml"
          hash = item.to_hash
          file = "spec/fixtures/#{path}"
          File.write file, hash.to_yaml, encoding: "UTF-8" unless File.exist? file
          yaml = YAML.load_file(file)
          yaml["fetched"] = Date.today.to_s
          expect(hash).to eq yaml
        end

        en = YAML.load_file "spec/fixtures/cgpm/meetings-en/meeting-01.yml"
        fr = YAML.load_file "spec/fixtures/cgpm/meetings-fr/meeting-01.yml"
        src = [{ type: "src", content: "http://www.bipm.org/publications/cgpm/meeting-01.html" }]

        subject.fetch_resolution(
          body: "CGPM", en: en, fr: fr, dir: "data/cgpm/meeting", src: src, num: "1",
        )
      end

      it "multiple resolutions" do
        expect(FileUtils).to receive(:mkdir_p).with("data/cipm/meeting/decision").exactly(40).times
        expect(subject).to receive(:write_file) do |path, item|
          expect(path).to match(/data\/cipm\/meeting\/decision\/\d{4}-\d{2}\.yaml/)
          hash = item.to_hash
          file = "spec/fixtures/#{path}"
          File.write file, hash.to_yaml, encoding: "UTF-8" unless File.exist? file
          yaml = YAML.load_file(file)
          yaml["fetched"] = Date.today.to_s
          expect(hash).to eq yaml
        end.exactly(40).times

        en = YAML.load_file "spec/fixtures/cipm/meetings-en/meeting-101-1.yml"
        fr = YAML.load_file "spec/fixtures/cipm/meetings-fr/meeting-101-1.yml"
        src = [{ type: "src", content: "http://www.bipm.org/publications/cipm/meeting-01.html" }]

        subject.fetch_resolution(
          body: "CIPM", en: en, fr: fr, dir: "data/cipm/meeting", src: src, num: "1",
        )
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

    it "#parse_si_brochure" do
      expect(Dir).to receive(:[]).with("bipm-si-brochure/site/documents/*.rxl")
        .and_return [
          "spec/fixtures/si_brochure/si-brochure-en.rxl",
          "spec/fixtures/si_brochure/si-brochure-fr.rxl",
        ]
      expect(File).to receive(:exist?).with("data/si-brochure.yaml").and_return false, true

      expect(subject).to receive(:write_file) do |path, item, opt|
        expect(path).to eq "data/si-brochure.yaml"
        p = if opt[:warn_duplicate]
              "spec/fixtures/#{path.sub('brochure', 'brochure_1')}"
            else
              "spec/fixtures/#{path}"
            end
        hash = item.to_hash
        hash["fetched"] = Date.today.to_s
        File.write p, hash.to_yaml, encoding: "UTF-8" unless File.exist? p
        yaml = YAML.load_file(p)
        yaml["fetched"] = Date.today.to_s
        expect(hash).to eq yaml
      end.twice

      allow(YAML).to receive(:load_file).and_wrap_original do |m, path|
        m.call path.sub(/^data\/si-brochure\.yaml/, "spec/fixtures/data/si-brochure_1.yaml")
      end

      subject.parse_si_brochure
      expect(subject.instance_variable_get(:@index)).to eq ["SI Brochure"] => "data/si-brochure.yaml"
    end
  end
end
