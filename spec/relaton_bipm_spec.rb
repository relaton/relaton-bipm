RSpec.describe RelatonBipm do
  before { RelatonBipm.instance_variable_set :@configuration, nil }

  it "has a version number" do
    expect(RelatonBipm::VERSION).not_to be nil
  end

  it "retur grammar hash" do
    hash = RelatonBipm.grammar_hash
    expect(hash).to be_instance_of String
    expect(hash.size).to eq 32
  end

  it "search a code", vcr: "cctf_meeting_14" do
    expect(File).to receive(:exist?).with(/index2\.yaml/).and_return false
    allow(File).to receive(:exist?).and_call_original
    result = RelatonBipm::BipmBibliography.search "BIPM CCTF Meeting 14 (1999)"
    expect(result).to be_instance_of RelatonBipm::BipmBibliographicItem
  end

  context "get document" do
    context "outcomes" do
      it "CCTF Recommendation EN", vcr: "cctf_recommendation_2009_02" do
        file = "spec/fixtures/cctf_recommendation_2009_02.xml"
        result = RelatonBipm::BipmBibliography.get "CCTF Recommendation 2 (2009)"
        xml = result.to_xml(bibdata: true)
        File.write file, xml, encoding: "UTF-8" unless File.exist? file
        expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
          .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
      end

      it "CCTF Recommendation EN", vcr: "cctf_recommendation_2009_02" do
        file = "spec/fixtures/cctf_recommendation_2009_02.xml"
        result = RelatonBipm::BipmBibliography.get "CCTF Recommendation 2009-02"
        xml = result.to_xml(bibdata: true)
        File.write file, xml, encoding: "UTF-8" unless File.exist? file
        expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
          .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
      end

      it "CCTF Recommendation short notation EN", vcr: "cctf_recommendation_2009_02" do
        file = "spec/fixtures/cctf_recommendation_2009_02.xml"
        result = RelatonBipm::BipmBibliography.get "CCTF REC 2 (2009, EN)"
        xml = result.to_xml(bibdata: true)
        File.write file, xml, encoding: "UTF-8" unless File.exist? file
        expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
          .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
      end

      it "CCDS Recommendation", vcr: "cctf_recommendation_2009_02" do
        file = "spec/fixtures/cctf_recommendation_2009_02.xml"
        result = RelatonBipm::BipmBibliography.get "CCDS Recommendation 2 (2009)"
        xml = result.to_xml(bibdata: true)
        File.write file, xml, encoding: "UTF-8" unless File.exist? file
        expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
          .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
      end

      it "CGPM meeting", vcr: "cgpm_meeting_1" do
        file = "spec/fixtures/cgpm_meeting_1.xml"
        result = RelatonBipm::BipmBibliography.get "CGPM Meeting 1 (1889)"
        xml = result.to_xml(bibdata: true)
        File.write file, xml, encoding: "UTF-8" unless File.exist? file
        expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
          .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
      end

      it "CGPM resolution", vcr: "cgpm_resolution_1889_00" do
        file = "spec/fixtures/cgpm_resolution_1889_00.xml"
        result = RelatonBipm::BipmBibliography.get "CGPM Resolution (1889)"
        xml = result.to_xml(bibdata: true)
        File.write file, xml, encoding: "UTF-8" unless File.exist? file
        expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
          .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
      end

      context "CGPM resolution", vcr: "cgpm_resolution_1889_00" do
        let(:file) { "spec/fixtures/cgpm_resolution_1889_00.xml" }

        it "CGPM Resolution (1889)" do
          result = RelatonBipm::BipmBibliography.get "CGPM Resolution (1889)"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end

        it "CGPM Resolution 1889-00" do
          result = RelatonBipm::BipmBibliography.get "CGPM Resolution 1889-00"
          expect(result.docidentifier.first.id).to eq "CGPM RES (1889)"
        end

        it "CGPM RES 1 (1889)" do
          result = RelatonBipm::BipmBibliography.get "CGPM RES 1 (1889)"
          expect(result.docidentifier.first.id).to eq "CGPM RES (1889)"
        end
      end

      it "CGPM Declaration 1971-00", vcr: "cgpm_declaration_1971_00" do
        result = RelatonBipm::BipmBibliography.get "CGPM Declaration 1971-00"
        expect(result.docidentifier.first.id).to eq "CGPM DECL (1971)"
      end

      it "CIPM resolution", vcr: "cipm_resolution_1879" do
        file = "spec/fixtures/cipm_resolution_1879.xml"
        result = RelatonBipm::BipmBibliography.get "CIPM Resolution (1879)"
        xml = result.to_xml(bibdata: true)
        File.write file, xml, encoding: "UTF-8" unless File.exist? file
        expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
          .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
      end

      context "CIPM decision", vcr: "cipm_decision_2012_01" do
        it "long notation EN" do
          file = "spec/fixtures/cipm_decision_2012_01.xml"
          result = RelatonBipm::BipmBibliography.get "CIPM Decision 101-1 (2012)"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end

        it "short notation EN" do
          file = "spec/fixtures/cipm_decision_2012_01.xml"
          result = RelatonBipm::BipmBibliography.get "CIPM DECN 101-1 (2012, EN)"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .sub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end

        it "short notation language independent" do
          result = RelatonBipm::BipmBibliography.get "CIPM DECN 101-1 (2012)"
          expect(result.docidentifier.first.id).to eq "CIPM DECN 101-1 (2012)"
        end

        it "long notation FR" do
          file = "spec/fixtures/cipm_decision_2012_01.xml"
          result = RelatonBipm::BipmBibliography.get "CIPM Décision 101-1 (2012)"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .sub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end

        it vcr: "cipm_decision_111_10" do
          result = RelatonBipm::BipmBibliography.get "CIPM DECN 111-10 (2022, E)"
          expect(result.docidentifier.first.id).to eq "CIPM DECN 111-10 (2022)"
        end
      end

      context "CIPM Meeting" do
        it "without year", vcr: "cipm_meeting_43_1950" do
          file = "spec/fixtures/cipm_meeting_43_1950.xml"
          result = RelatonBipm::BipmBibliography.get "CIPM Meeting 43"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .sub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end

        it "with year", vcr: "cipm_meeting" do
          result = RelatonBipm::BipmBibliography.get "CIPM 111st Meeting (2022)"
          expect(result.docidentifier.first.id).to eq "CIPM 111st Meeting (2022)"
        end

        it "FR", vcr: "cipm_meeting" do
          result = RelatonBipm::BipmBibliography.get "CIPM 111e Réunion (2022)"
          expect(result.docidentifier.first.id).to eq "CIPM 111st Meeting (2022)"
        end
      end
    end

    it "SI Brochure", vcr: "si_brochure" do
      result = RelatonBipm::BipmBibliography.get "BIPM SI Brochure"
      expect(result.docidentifier[0].id).to eq "BIPM SI Brochure"
    end

    context "Metrologia" do
      it "journal" do
        VCR.use_cassette "metrologia" do
          file = "spec/fixtures/metrologia.xml"
          result = RelatonBipm::BipmBibliography.get "BIPM Metrologia"
          xml = result.to_xml bibdata: true
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .sub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end
      end

      it "journal" do
        VCR.use_cassette "metrologia_30" do
          file = "spec/fixtures/metrologia_30.xml"
          result = RelatonBipm::BipmBibliography.get "BIPM Metrologia 30"
          xml = result.to_xml bibdata: true
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .sub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end
      end

      it "volume" do
        VCR.use_cassette "metrologia_29_6" do
          file = "spec/fixtures/metrologia_29_6.xml"
          result = RelatonBipm::BipmBibliography.get "BIPM Metrologia 29 6"
          xml = result.to_xml bibdata: true
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .sub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end
      end

      it "volume with title" do
        VCR.use_cassette "metrologia_30_4" do
          file = "spec/fixtures/metrologia_30_4.xml"
          result = RelatonBipm::BipmBibliography.get "BIPM Metrologia 30 4"
          xml = result.to_xml bibdata: true
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .sub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end
      end

      it "page" do
        VCR.use_cassette "metrologia_29_6_373" do
          file = "spec/fixtures/metrologia_29_6_373.xml"
          result = RelatonBipm::BipmBibliography.get "BIPM Metrologia 29 6 373"
          xml = result.to_xml bibdata: true
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .sub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end
      end

      it "wrong page" do
        expect do
          result = RelatonBipm::BipmBibliography.get "BIPM Metrologia 34 3 999"
          expect(result).to be_nil
        end.to output(
          /\[relaton-bipm\] \(BIPM Metrologia 34 3 999\) not found\./,
        ).to_stderr
      end

      it "with 403 response code", vcr: "metrologia_50_4_385" do
        result = RelatonBipm::BipmBibliography.get "BIPM Metrologia 50 4 385"
        expect(result.docidentifier[0].id).to eq "Metrologia 50 4 385"
      end

      it "without author", vcr: "metrologia_19_4_163" do
        result = RelatonBipm::BipmBibliography.get "BIPM Metrologia 19 4 163"
        expect(result.docidentifier[0].id).to eq "Metrologia 19 4 163"
      end

      it "with text/html title", vcr: "metrologia_55_1_L13" do
        result = RelatonBipm::BipmBibliography.get "BIPM Metrologia 55 1 L13"
        expect(result.title[0].title.content).to eq(
          "The CODATA 2017 values of h, e, k, and N<sub>A</sub> for the revision of the SI",
        )
      end
    end
  end
end
