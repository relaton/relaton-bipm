require "jing"

RSpec.describe Relaton::Bipm::Bibliography do
  context "raise RequestError" do
    it "fetch from GitHub" do
      index = double "index"
      expect(index).to receive(:search).and_return [{ id: { year: "156" }, path: "data/doc.yaml" }]
      expect(Relaton::Index).to receive(:find_or_create).with(
        :bipm,
        url: "https://raw.githubusercontent.com/relaton/relaton-data-bipm/refs/heads/v2/index-v1.zip",
        file: "index-v1.yaml", id_keys: %i[group type number year corr part append]
      ).and_return index
      agent = double(:agent)
      expect(agent).to receive(:get).and_raise Mechanize::ResponseCodeError.new(Mechanize::Page.new)
      expect(Mechanize).to receive(:new).and_return agent
      expect do
        Relaton::Bipm::Bibliography.search "Metrologia"
      end.to raise_error Relaton::RequestError
    end
  end

  context "bib instance" do
    subject do
      Relaton::Bipm::Item.from_yaml File.read("spec/fixtures/bipm_item.yml", encoding: "UTF-8")
    end

    it "returns XML" do
      file = "spec/fixtures/bipm_item.xml"
      xml = subject.to_xml bibdata: true
      File.write file, xml, encoding: "UTF-8" unless File.exist? file
      expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
      schema = Jing.new "spec/schemas/relaton-bipm-compile.rng"
      errors = schema.validate file
      expect(errors).to eq []
    end

    it "returns Hash" do
      hash = YAML.safe_load subject.to_yaml
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

  context "get document" do
    before do
      # Force to download index file
      allow_any_instance_of(Relaton::Index::Type).to receive(:actual?).and_return(false)
      allow_any_instance_of(Relaton::Index::FileIO).to receive(:check_file).and_return(nil)
    end

    it "search a code", vcr: "cctf_meeting_14" do
      result = Relaton::Bipm::Bibliography.search "BIPM CCTF Meeting 14 (1999)"
      expect(result).to be_instance_of Relaton::Bipm::ItemData
    end

    context "get document" do
      context "outcomes" do
        it "CCTF Recommendation EN", vcr: "cctf_recommendation_2009_02" do
          file = "spec/fixtures/cctf_recommendation_2009_02.xml"
          result = Relaton::Bipm::Bibliography.get "CCTF Recommendation 2 (2009)"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end

        it "CCTF Recommendation EN", vcr: "cctf_recommendation_2009_02" do
          file = "spec/fixtures/cctf_recommendation_2009_02.xml"
          result = Relaton::Bipm::Bibliography.get "CCTF Recommendation 2009-02"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end

        it "CCTF Recommendation short notation EN", vcr: "cctf_recommendation_2009_02" do
          file = "spec/fixtures/cctf_recommendation_2009_02.xml"
          result = Relaton::Bipm::Bibliography.get "CCTF REC 2 (2009, EN)"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end

        it "CCDS Recommendation", vcr: "cctf_recommendation_2009_02" do
          file = "spec/fixtures/cctf_recommendation_2009_02.xml"
          result = Relaton::Bipm::Bibliography.get "CCDS Recommendation 2 (2009)"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end

        it "CGPM meeting", vcr: "cgpm_meeting_1" do
          file = "spec/fixtures/cgpm_meeting_1.xml"
          result = Relaton::Bipm::Bibliography.get "CGPM Meeting 1 (1889)"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end

        xit "CGPM resolution", vcr: "cgpm_resolution_1889_00" do
          file = "spec/fixtures/cgpm_resolution_1889_00.xml"
          result = Relaton::Bipm::Bibliography.get "CGPM Resolution (1889)"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end

        context "CGPM resolution", vcr: "cgpm_resolution_1889_00" do
          let(:file) { "spec/fixtures/cgpm_resolution_1889_00.xml" }

          xit "CGPM Resolution (1889)" do
            result = Relaton::Bipm::Bibliography.get "CGPM Resolution (1889)"
            xml = result.to_xml(bibdata: true)
            File.write file, xml, encoding: "UTF-8" unless File.exist? file
            expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
              .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
          end

          xit "CGPM Resolution 1889-00" do
            result = Relaton::Bipm::Bibliography.get "CGPM Resolution 1889-00"
            expect(result.docidentifier.first.content).to eq "CGPM RES (1889)"
          end

          xit "CGPM RES 1 (1889)" do
            result = Relaton::Bipm::Bibliography.get "CGPM RES 1 (1889)"
            expect(result.docidentifier.first.content).to eq "CGPM RES (1889)"
          end
        end

        # relaton-data-bipm v2 no longer has data/cgpm/meeting/statement/1971-00.yaml
        xit "CGPM Declaration 1971-00" do
          result = Relaton::Bipm::Bibliography.get "CGPM Declaration 1971-00"
          expect(result.docidentifier.first.content).to eq "CGPM DECL (1971)"
        end

        it "CIPM resolution", vcr: "cipm_resolution_1879" do
          file = "spec/fixtures/cipm_resolution_1879.xml"
          result = Relaton::Bipm::Bibliography.get "CIPM Resolution (1879)"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end

        context "CIPM decision", vcr: "cipm_decision_2012_01" do
          it "long notation EN" do
            file = "spec/fixtures/cipm_decision_2012_01.xml"
            result = Relaton::Bipm::Bibliography.get "CIPM Decision 101-1 (2012)"
            xml = result.to_xml(bibdata: true)
            File.write file, xml, encoding: "UTF-8" unless File.exist? file
            expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
              .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
          end

          it "short notation EN" do
            file = "spec/fixtures/cipm_decision_2012_01.xml"
            result = Relaton::Bipm::Bibliography.get "CIPM DECN 101-1 (2012, EN)"
            xml = result.to_xml(bibdata: true)
            File.write file, xml, encoding: "UTF-8" unless File.exist? file
            expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
              .sub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
          end

          it "short notation language independent" do
            result = Relaton::Bipm::Bibliography.get "CIPM DECN 101-1 (2012)"
            expect(result.docidentifier.first.content).to eq "CIPM DECN 101-1 (2012)"
          end

          it "long notation FR" do
            file = "spec/fixtures/cipm_decision_2012_01.xml"
            result = Relaton::Bipm::Bibliography.get "CIPM Décision 101-1 (2012)"
            xml = result.to_xml(bibdata: true)
            File.write file, xml, encoding: "UTF-8" unless File.exist? file
            expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
              .sub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
          end

          it vcr: "cipm_decision_111_10" do
            result = Relaton::Bipm::Bibliography.get "CIPM DECN 111-10 (2022, E)"
            expect(result.docidentifier.first.content).to eq "CIPM DECN 111-10 (2022)"
          end
        end

        context "CIPM Meeting" do
          it "without year", vcr: "cipm_meeting_43_1950" do
            file = "spec/fixtures/cipm_meeting_43_1950.xml"
            result = Relaton::Bipm::Bibliography.get "CIPM Meeting 43"
            xml = result.to_xml(bibdata: true)
            File.write file, xml, encoding: "UTF-8" unless File.exist? file
            expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
              .sub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
          end

          it "with year", vcr: "cipm_meeting" do
            result = Relaton::Bipm::Bibliography.get "CIPM 111st Meeting (2022)"
            expect(result.docidentifier.first.content).to eq "CIPM 111st Meeting (2022)"
          end

          it "FR", vcr: "cipm_meeting" do
            result = Relaton::Bipm::Bibliography.get "CIPM 111e Réunion (2022)"
            expect(result.docidentifier.first.content).to eq "CIPM 111st Meeting (2022)"
          end
        end
      end

      # relaton-data-bipm lists the SI Brochure only in index-v2 now, and this gem reads index-v1
      xit "SI Brochure" do
        result = Relaton::Bipm::Bibliography.get "BIPM SI Brochure Part 1"
        en_id = result.docidentifier.find { |id| id.content.is_a?(String) && id.content.end_with?(", E)") }
        expect(en_id.content).to eq "BIPM SI Brochure 9e v3.01 (2019/2024, E)"
      end

      context "Metrologia" do
        it "journal" do
          VCR.use_cassette "metrologia" do
            file = "spec/fixtures/metrologia.xml"
            result = Relaton::Bipm::Bibliography.get "BIPM Metrologia"
            xml = result.to_xml bibdata: true
            File.write file, xml, encoding: "UTF-8" unless File.exist? file
            expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
              .sub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
          end
        end

        it "journal" do
          VCR.use_cassette "metrologia_30" do
            file = "spec/fixtures/metrologia_30.xml"
            result = Relaton::Bipm::Bibliography.get "BIPM Metrologia 30"
            xml = result.to_xml bibdata: true
            File.write file, xml, encoding: "UTF-8" unless File.exist? file
            expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
              .sub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
          end
        end

        it "volume" do
          VCR.use_cassette "metrologia_29_6" do
            file = "spec/fixtures/metrologia_29_6.xml"
            result = Relaton::Bipm::Bibliography.get "BIPM Metrologia 29 6"
            xml = result.to_xml bibdata: true
            File.write file, xml, encoding: "UTF-8" unless File.exist? file
            expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
              .sub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
          end
        end

        it "volume with title" do
          VCR.use_cassette "metrologia_30_4" do
            file = "spec/fixtures/metrologia_30_4.xml"
            result = Relaton::Bipm::Bibliography.get "BIPM Metrologia 30 4"
            xml = result.to_xml bibdata: true
            File.write file, xml, encoding: "UTF-8" unless File.exist? file
            expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
              .sub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
          end
        end

        it "page" do
          VCR.use_cassette "metrologia_29_6_373" do
            file = "spec/fixtures/metrologia_29_6_373.xml"
            result = Relaton::Bipm::Bibliography.get "BIPM Metrologia 29 6 373"
            xml = result.to_xml bibdata: true
            File.write file, xml, encoding: "UTF-8" unless File.exist? file
            expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
              .sub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
          end
        end

        it "wrong page" do
          expect do
            result = Relaton::Bipm::Bibliography.get "BIPM Metrologia 34 3 999"
            expect(result).to be_nil
          end.to output(
            /\[relaton-bipm\] INFO: \(BIPM Metrologia 34 3 999\) Not found\./,
          ).to_stderr_from_any_process
        end

        it "with 403 response code", vcr: "metrologia_50_4_385" do
          result = Relaton::Bipm::Bibliography.get "BIPM Metrologia 50 4 385"
          expect(result.docidentifier[0].content).to eq "Metrologia 50 4 385"
        end

        it "without author", vcr: "metrologia_19_4_163" do
          result = Relaton::Bipm::Bibliography.get "BIPM Metrologia 19 4 163"
          expect(result.docidentifier[0].content).to eq "Metrologia 19 4 163"
        end

        it "with text/html title", vcr: "metrologia_55_1_L13" do
          result = Relaton::Bipm::Bibliography.get "BIPM Metrologia 55 1 L13"
          expect(result.title[0].content).to eq(
            "The CODATA 2017 values of <em>h</em>, <em>e</em>, <em>k</em>, " \
            "and <em>N</em><sub>A</sub> for the revision of the SI",
          )
        end
      end
    end

    context "get static document" do
      # relaton-data-bipm v2 no longer has the static/jcgm documents
      context "JCGM" do
        xit "JCGM 200:2012" do
          bib = Relaton::Bipm::Bibliography.get "JCGM 200:2012"
          expect(bib.docidentifier[0].content).to eq "JCGM 200:2012"
        end

        xit "JCGM GUM-6:2020" do
          bib = Relaton::Bipm::Bibliography.get "JCGM GUM-6:2020"
          expect(bib.docidentifier[0].content).to eq "JCGM GUM-6:2020"
        end

        xit "JCGM GUM" do
          bib = Relaton::Bipm::Bibliography.get "JCGM GUM"
          expect(bib.docidentifier[0].content).to eq "JCGM GUM"
        end

        xit "JCGM VIM-3" do
          bib = Relaton::Bipm::Bibliography.get "JCGM VIM-3"
          expect(bib.docidentifier[0].content).to eq "JCGM VIM-3"
        end

        xit "JCGM 200:2008 Corrigendum" do
          bib = Relaton::Bipm::Bibliography.get "JCGM 200:2008 Corrigendum"
          expect(bib.docidentifier[0].content).to eq "JCGM 200:2008 Corrigendum"
        end
      end
    end
  end
end
