RSpec.describe RelatonBipm do
  it "has a version number" do
    expect(RelatonBipm::VERSION).not_to be nil
  end

  it "retur grammar hash" do
    hash = RelatonBipm.grammar_hash
    expect(hash).to be_instance_of String
    expect(hash.size).to eq 32
  end

  it "search a code" do
    expect(File).to receive(:exist?).with(/index\.yaml/).and_return false
    allow(File).to receive(:exist?).and_call_original
    VCR.use_cassette "cctf_meeting_14" do
      result = RelatonBipm::BipmBibliography.search "BIPM CCTF -- Meeting 14 (1999)"
      expect(result).to be_instance_of RelatonBipm::BipmBibliographicItem
    end
  end

  context "get document" do
    context "from relaton-data-bipm" do
      before :each do
        expect(File).to receive(:exist?).with(/index\.yaml/).and_return false
        allow(File).to receive(:exist?).and_call_original
      end

      it "CCTF Recommendation EN" do
        VCR.use_cassette "cctf_recommendation_2009_02" do
          file = "spec/fixtures/cctf_recommendation_2009_02.xml"
          result = RelatonBipm::BipmBibliography.get "CCTF -- Recommendation 2 (2009)"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end
      end

      it "CCTF Recommendation short notation EN" do
        VCR.use_cassette "cctf_recommendation_2009_02" do
          file = "spec/fixtures/cctf_recommendation_2009_02.xml"
          result = RelatonBipm::BipmBibliography.get "CCTF -- REC 2 (2009, EN)"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end
      end

      it "CCDS Recommendation" do
        VCR.use_cassette "cctf_recommendation_2009_02" do
          file = "spec/fixtures/cctf_recommendation_2009_02.xml"
          result = RelatonBipm::BipmBibliography.get "CCDS -- Recommendation 2 (2009)"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end
      end

      it "CGPM meetings" do
        VCR.use_cassette "cgpm_meeting_1" do
          file = "spec/fixtures/cgpm_meeting_1.xml"
          result = RelatonBipm::BipmBibliography.get "CGPM -- Meeting 1 (1889)"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end
      end

      it "CGPM resolution" do
        VCR.use_cassette "cgpm_resolution_1889_00" do
          file = "spec/fixtures/cgpm_resolution_1889_00.xml"
          result = RelatonBipm::BipmBibliography.get "CGPM -- Resolution (1889)"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end
      end

      it "CGPM resolution" do
        VCR.use_cassette "cgpm_resolution_1889_00" do
          file = "spec/fixtures/cgpm_resolution_1889_00.xml"
          result = RelatonBipm::BipmBibliography.get "CGPM -- Resolution (1889)"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end
      end

      context "CIPM decision" do
        it "long notation EN" do
          VCR.use_cassette "cipm_decision_2012_01" do
            file = "spec/fixtures/cipm_decision_2012_01.xml"
            result = RelatonBipm::BipmBibliography.get "BIPM Decision CIPM/101-1 (2012)"
            xml = result.to_xml(bibdata: true)
            File.write file, xml, encoding: "UTF-8" unless File.exist? file
            expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
              .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
          end
        end

        it "short notation EN" do
          VCR.use_cassette "cipm_decision_2012_01" do
            file = "spec/fixtures/cipm_decision_2012_01.xml"
            result = RelatonBipm::BipmBibliography.get "BIPM DECN CIPM/101-1 (2012, EN)"
            xml = result.to_xml(bibdata: true)
            File.write file, xml, encoding: "UTF-8" unless File.exist? file
            expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
              .sub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
          end
        end

        it "long notation FR" do
          VCR.use_cassette "cipm_decision_2012_01" do
            file = "spec/fixtures/cipm_decision_2012_01.xml"
            result = RelatonBipm::BipmBibliography.get "BIPM Décision CIPM/101-1 (2012)"
            xml = result.to_xml(bibdata: true)
            File.write file, xml, encoding: "UTF-8" unless File.exist? file
            expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
              .sub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
          end
        end
      end

      it "SI Brochure", vcr: "si_brochure" do
        result = RelatonBipm::BipmBibliography.get "BIPM SI Brochure"
        expect(result.docidentifier[0].id).to eq "BIPM SI Brochure"
      end
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

      it "volume" do
        VCR.use_cassette "metrologia_30" do
          file = "spec/fixtures/metrologia_30.xml"
          result = RelatonBipm::BipmBibliography.get "BIPM Metrologia 30"
          xml = result.to_xml bibdata: true
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .sub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end
      end

      it "issue" do
        VCR.use_cassette "metrologia_29_6" do
          file = "spec/fixtures/metrologia_29_6.xml"
          result = RelatonBipm::BipmBibliography.get "BIPM Metrologia 29 6"
          xml = result.to_xml bibdata: true
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .sub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end
      end

      it "issue with title" do
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
          result = RelatonBipm::BipmBibliography.get "BIPM Metrologia 29 6 001"
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
          /\[relaton-bipm\] \("BIPM Metrologia 34 3 999"\) not found\./,
        ).to_stderr
      end

      # it "with 403 response code", vcr: "metrologia_50_4_385" do
      #   result = RelatonBipm::BipmBibliography.get "BIPM Metrologia 50 4 385"
      #   expect(result.docidentifier[0].id).to eq "Metrologia 50 4 385"
      # end

      it "without author", vcr: "metrologia_19_4_163" do
        result = RelatonBipm::BipmBibliography.get "BIPM Metrologia 19 4 004"
        expect(result.docidentifier[0].id).to eq "Metrologia 19 4 004"
      end

      # it "with text/html title", vcr: "metrologia_55_1_L13" do
      #   result = RelatonBipm::BipmBibliography.get "BIPM Metrologia 55 1 aa950a"
      #   expect(result.title[0].title.content).to eq(
      #     "The CODATA 2017 values of<em>h</em>,<em>e</em>,<em>k</em>, " \
      #     "and<em>N</em><sub>A</sub> for the revision of the SI",
      #   )
      # end
    end
  end
end
