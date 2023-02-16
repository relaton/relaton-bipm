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
    let(:data_fetcher) { double "data_fetcher", output: "data", ext: "yaml", files: [], index: {} }
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
      expect(subject).to receive(:fetch_meeting).with("cgpm/meetings-en/1.yml", "CGPM", "meeting", "data/cgpm/meeting")
      subject.fetch_type("cgpm/meetings-en", "CGPM")
    end

    context "#contributors" do
      shared_examples "contributors" do |date, body|
        it do
          contribs = subject.contributors date, body
          expect(contribs.size).to eq 2
          expect(contribs[0][:role]).to eq [{ type: "publisher" }]
          expect(contribs[0][:entity][:abbreviation]).to eq "BIPM"
          expect(contribs[0][:entity][:name]).to eq "Bureau International des Poids et Mesures"
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
        subject.fetch_meeting "spec/fixtures/cgpm/meetings-en/meeting-01.yml", "CGPM", "meeting", "data/cgpm/meeting"
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
        expect(data_fetcher.index).to eq(
          {
            ["CIPM -- Meeting 101 (2012)", "CIPM -- Réunion 101 (2012)"] => "data/cipm/meeting/101.yaml",
            ["CIPM -- Meeting 101-1 (2012)", "CIPM -- Réunion 101-1 (2012)"] => "data/cipm/meeting/101-1.yaml",
            ["CIPM -- Meeting 101-2 (2012)", "CIPM -- Réunion 101-2 (2012)"] => "data/cipm/meeting/101-2.yaml",
          },
        )
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

        subject.fetch_resolution(
          body: "CGPM", en: en, fr: fr, dir: "data/cgpm/meeting", src: src, num: "1",
        )
        expect(data_fetcher.index).to eq(
          {
            [
              "CGPM -- Resolution (1889)",
              "CGPM -- RES (1889)",
              "CGPM -- RES (1889, EN)",
              "CGPM -- RES (1889, FR)",
              "CGPM -- Résolution (1889)",
            ] => "data/cgpm/meeting/resolution/1889-00.yaml",
          },
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

        subject.fetch_resolution(
          body: "CIPM", en: en, fr: fr, dir: "data/cipm/meeting", src: src, num: "1",
        )
        expect(data_fetcher.index).to include(
          {
            [
              "Decision CIPM/101-1 (2012)",
              "DECN CIPM/101-1 (2012)",
              "DECN CIPM/101-1 (2012, EN)",
              "DECN CIPM/101-1 (2012, FR)",
              "Décision CIPM/101-1 (2012)",
            ] => "data/cipm/meeting/decision/2012-101-1.yaml",
          },
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
  end
end