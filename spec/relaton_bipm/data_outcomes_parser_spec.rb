describe RelatonBipm::DataOutcomesParser do
  context "class methods" do
    it "::parse" do
      data_parser = double "data_parser"
      expect(data_parser).to receive(:parse)
      expect(described_class).to receive(:new).and_return data_parser
      described_class.parse :data_fetcher
    end
  end

  context "instance methods" do
    let(:index2) { double "index2" }
    let(:data_fetcher) { double "data_fetcher", output: "data", format: "yaml", ext: "yaml", files: [], index2: index2 }
    subject { described_class.new data_fetcher }

    it "#parse" do
      expect(Dir).to receive(:[])
        .with("bipm-data-outcomes/{cctf,cgpm,cipm,ccauv,ccem,ccl,ccm,ccpr,ccqm,ccri,cct,ccu,jcgm,jcrb}")
        .and_return ["bipm-data-outcomes/cgpm"]
      expect(subject).to receive(:fetch_body).with("bipm-data-outcomes/cgpm")
      subject.parse
    end

    it "#fetch_body" do
      expect(Dir).to receive(:[]).with("bipm-data-outcomes/cgpm/*-en").and_return ["cgpm/meetings-en"]
      expect(subject).to receive(:fetch_type).with("cgpm/meetings-en", "CGPM")
      subject.fetch_body "bipm-data-outcomes/cgpm"
    end

    it "#fetch_type" do
      expect(FileUtils).to receive(:mkdir_p).with("data/cgpm")
      expect(FileUtils).to receive(:mkdir_p).with("data/cgpm/meeting")
      expect(Dir).to receive(:[]).with("cgpm/meetings-en/*.{yml,yaml}").and_return ["cgpm/meetings-en/1.yml"]
      expect(subject).to receive(:fetch_meeting).with("cgpm/meetings-en/1.yml", "CGPM", "Meeting", "data/cgpm/meeting")
      subject.fetch_type("cgpm/meetings-en", "CGPM")
    end

    context "#contributors" do
      shared_examples "contributors" do |date, body|
        it do
          contribs = subject.contributors date, body
          expect(contribs.size).to eq 2
          expect(contribs[0][:role]).to eq [{ type: "publisher" }]
          expect(contribs[0][:entity][:abbreviation]).to eq content: "BIPM", language: ["en", "fr"], script: "Latn"
          expect(contribs[0][:entity][:name][0][:content]).to eq "International Bureau of Weights and Measures"
          expect(contribs[0][:entity][:name][0][:language]).to eq "en"
          expect(contribs[0][:entity][:name][0][:script]).to eq "Latn"
          expect(contribs[0][:entity][:name][1][:content]).to eq "Bureau international des poids et mesures"
          expect(contribs[0][:entity][:url]).to eq "www.bipm.org"
          if body == "CCTF"
            if Date.parse(date).year < 1999
              abbr = "CCDS"
              en = "Consultative Committee for the Definition of the Second"
              fr = "Comité Consultatif pour la Définition de la Seconde"
            else
              abbr = "CCTF"
              en = "Consultative Committee for Time and Frequency"
              fr = "Comité consultatif du temps et des fréquences"
            end
            expect(contribs[1][:role]).to eq [{ type: "author" }]
            expect(contribs[1][:entity][:abbreviation]).to eq(
              { content: abbr, language: ["en", "fr"], script: "Latn" },
            )
            expect(contribs[1][:entity][:name]).to eq(
              [{ content: en, language: "en", script: "Latn" },
               { content: fr, language: "fr", script: "Latn" }],
            )
          end
        end
      end

      it_should_behave_like "contributors", "1998-11-11", "CCTF"
      it_should_behave_like "contributors", "1999-11-11", "CCTF"
    end

    context "#fetch_meeting" do
      it "no part" do
        expect(data_fetcher).to receive(:write_file) do |path, item|
          expect(path).to eq "data/cgpm/meeting/1.yaml"
          hash = item.to_hash
          file = "spec/fixtures/#{path}"
          File.write file, hash.to_yaml, encoding: "UTF-8" unless File.exist? file
          yaml = YAML.load_file(file)
          expect(hash).to eq yaml
        end
        expect(subject).to receive(:fetch_resolution).with(
          body: "CGPM", en: kind_of(Hash), fr: kind_of(Hash),
          dir: "data/cgpm/meeting", src: kind_of(Array), num: "1"
        )
        expect(index2).to receive(:add_or_update).with({ group: "CGPM", type: "Meeting", number: "1", year: "1889" }, "data/cgpm/meeting/1.yaml")
        subject.fetch_meeting "spec/fixtures/cgpm/meetings-en/meeting-01.yml", "CGPM", "Meeting", "data/cgpm/meeting"
      end

      it "with part" do
        allow(File).to receive(:read).and_wrap_original do |method, f, **args|
          file = f == "data/cipm/meeting/101.yaml" ? "spec/fixtures/#{f.sub("101", "101_1")}" : f
          method.call file, **args
        end
        ["data/cipm/meeting/101-1.yaml", "data/cipm/meeting/101.yaml",
         "data/cipm/meeting/101.yaml", "data/cipm/meeting/101-2.yaml"].each do |expect_path|
          expect(data_fetcher).to receive(:write_file) do |path, item, **args|
            expect(path).to eq expect_path
            if item.relation.size == 1
              data_fetcher.files << path
              file = "spec/fixtures/#{path.sub('101.', '101_1.')}"
            else
              expect(args[:warn_duplicate]).to be item.relation.empty? && nil
              file = "spec/fixtures/#{path}"
            end
            hash = item.to_hash
            File.write file, hash.to_yaml, encoding: "UTF-8" unless File.exist? file
            yaml = YAML.load_file(file)
            expect(hash).to eq yaml
          end
        end

        expect(subject).to receive(:fetch_resolution).with(
          body: "CIPM", en: kind_of(Hash), fr: kind_of(Hash),
          dir: "data/cipm/meeting", src: kind_of(Array), num: /\d+/
        ).twice

        expect(index2).to receive(:add_or_update).with({ group: "CIPM", type: "Meeting", number: "101-1", year: "2012" }, "data/cipm/meeting/101-1.yaml")
        expect(index2).to receive(:add_or_update).with({ group: "CIPM", type: "Meeting", number: "101-2", year: "2012" }, "data/cipm/meeting/101-2.yaml")
        expect(index2).to receive(:add_or_update).with({ group: "CIPM", type: "Meeting", number: "101", year: "2012" }, "data/cipm/meeting/101.yaml")
        subject.fetch_meeting "spec/fixtures/cipm/meetings-en/meeting-101-1.yml", "CIPM", "Meeting", "data/cipm/meeting"
        subject.fetch_meeting "spec/fixtures/cipm/meetings-en/meeting-101-2.yml", "CIPM", "Meeting", "data/cipm/meeting"
      end

      it "without fr" do
        outdir = "spec/fixtures/data/jcrb/meeting"
        expect(data_fetcher).to receive(:write_file) do |path, item|
          hash = item.to_hash
          File.write path, hash.to_yaml, encoding: "UTF-8" unless File.exist? path
          expect(hash).to eq(YAML.load_file(path))
        end.exactly(6).times

        expect(index2).to receive(:add_or_update).with(
          { group: "JCRB", type: "Meeting", number: "48", year: "2024" }, "#{outdir}/48.yaml"
        )
        expect(index2).to receive(:add_or_update).with(
          { group: "JCRB", type: "ACT", number: "48-1", year: "2024" }, "#{outdir}/action/2024-48-1.yaml"
        )
        expect(index2).to receive(:add_or_update).with(
          { group: "JCRB", type: "ACT", number: "48-2", year: "2024" }, "#{outdir}/action/2024-48-2.yaml"
        )
        expect(index2).to receive(:add_or_update).with(
          { group: "JCRB", type: "ACT", number: "48-3", year: "2024" }, "#{outdir}/action/2024-48-3.yaml"
        )
        expect(index2).to receive(:add_or_update).with(
          { group: "JCRB", type: "RES", number: "48-1", year: "2024" }, "#{outdir}/resolution/2024-48-1.yaml"
        )
        expect(index2).to receive(:add_or_update).with(
          { group: "JCRB", type: "RES", number: "48-2", year: "2024" }, "#{outdir}/resolution/2024-48-2.yaml"
        )

        subject.fetch_meeting "spec/fixtures/jcrb/meetings-en/meeting-48.yml", "JCRB", "Meeting", outdir
      end
    end

    context "#parse_file" do
      let(:data_fetcher) { double "data_fetcher", output: "data", format: "xml", ext: "xml", files: [], index2: index2 }
      it "xml" do
        expect(File).to receive(:read).with("file.xml", encoding: "UTF-8").and_return "xml"
        expect(RelatonBipm::XMLParser).to receive(:from_xml).with("xml").and_return "item"
        expect(subject.parse_file("file.xml")).to eq "item"
      end
    end

    context "#fetch_resolution" do
      it "one resolution" do
        expect(FileUtils).to receive(:mkdir_p).with("data/cgpm/meeting/resolution")
        expect(data_fetcher).to receive(:write_file) do |path, item|
          expect(path).to eq "data/cgpm/meeting/resolution/1889-00.yaml"
          hash = item.to_hash
          file = "spec/fixtures/#{path}"
          File.write file, hash.to_yaml, encoding: "UTF-8" unless File.exist? file
          yaml = YAML.load_file(file)
          expect(hash).to eq yaml
        end

        en = YAML.load_file "spec/fixtures/cgpm/meetings-en/meeting-01.yml"
        fr = YAML.load_file "spec/fixtures/cgpm/meetings-fr/meeting-01.yml"
        src = [{ type: "src", content: "http://www.bipm.org/publications/cgpm/meeting-01.html" }]

        expect(index2).to receive(:add_or_update).with(
          { group: "CGPM", type: "RES", year: "1889" }, "data/cgpm/meeting/resolution/1889-00.yaml"
        )
        subject.fetch_resolution(
          body: "CGPM", en: en, fr: fr, dir: "data/cgpm/meeting", src: src, num: "1",
        )
      end

      it "multiple resolutions" do
        expect(FileUtils).to receive(:mkdir_p).with("data/cipm/meeting/decision").exactly(40).times
        expect(data_fetcher).to receive(:write_file) do |path, item|
          expect(path).to match(/data\/cipm\/meeting\/decision\/\d{4}-[\d-]{2,6}\.yaml/)
          hash = item.to_hash
          file = "spec/fixtures/#{path}"
          File.write file, hash.to_yaml, encoding: "UTF-8" unless File.exist? file
          yaml = YAML.load_file(file)
          expect(hash).to eq yaml
        end.exactly(40).times

        en = YAML.load_file "spec/fixtures/cipm/meetings-en/meeting-101-1.yml"
        fr = YAML.load_file "spec/fixtures/cipm/meetings-fr/meeting-101-1.yml"
        src = [{ type: "src", content: "http://www.bipm.org/publications/cipm/meeting-01.html" }]

        expect(index2).to receive(:add_or_update).with(kind_of(Hash), kind_of(String)).exactly(40).times
        subject.fetch_resolution(
          body: "CIPM", en: en, fr: fr, dir: "data/cipm/meeting", src: src, num: "1",
        )
      end
    end

    context "#resolution_title" do
      it "don't create empty title" do
        en_res = { "title" => "" }
        fr_res = { "title" => "" }
        expect(subject.resolution_title(en_res, fr_res)).to eq []
      end
    end

    context "#resolution_fr_long_id" do
      shared_examples "resolution_fr_long_id" do |group, type, number, year, expected|
        it "special case" do
          fr_id = subject.resolution_fr_long_id group, type, number, year
          expect(fr_id).to eq expected
        end
      end

      it_behaves_like "resolution_fr_long_id", "CIPM", "Decision", "10-1", "2012", "Décision CIPM/10-1 (2012)"
      it_behaves_like "resolution_fr_long_id", "CIPM", "Resolution", "1", "2012", "Résolution 1 du CIPM (2012)"
      it_behaves_like "resolution_fr_long_id", "CGPM", "Resolution", "1", "2012", "Résolution 1 de la CGPM (2012)"
      it_behaves_like "resolution_fr_long_id", "CIPM", "NoTranslation", "", "2012", "NoTranslation du CIPM (2012)"
    end
  end
end
