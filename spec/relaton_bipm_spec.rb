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
    VCR.use_cassette "cctf_meeting_5" do
      result = RelatonBipm::BipmBibliography.search "BIPM CCTF Meeting 5"
      expect(result).to be_instance_of RelatonBipm::BipmBibliographicItem
    end
  end

  context "get document" do
    context "from relaton-data-bipm" do
      before :each do
        expect(File).to receive(:exist?).with(/index\.yaml/).and_return false
        allow(File).to receive(:exist?).and_call_original
      end

      it "CCTF Recommendation" do
        VCR.use_cassette "cctf_recommendation_1970_02" do
          file = "spec/fixtures/cctf_recommendation_1970_02.xml"
          result = RelatonBipm::BipmBibliography.get "CCTF Recommendation 1970-02"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end
      end

      it "CCTF Recommendation" do
        VCR.use_cassette "cctf_recommendation_1970_02" do
          file = "spec/fixtures/cctf_recommendation_1970_02.xml"
          result = RelatonBipm::BipmBibliography.get "CCTF Recommendation 5-02"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end
      end

      it "CCDS Recommendation" do
        VCR.use_cassette "cctf_recommendation_1970_02" do
          file = "spec/fixtures/cctf_recommendation_1970_02.xml"
          result = RelatonBipm::BipmBibliography.get "CCDS Recommendation 1970-02"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end
      end

      it "CGPM meetings" do
        VCR.use_cassette "cgpm_meeting_1" do
          file = "spec/fixtures/cgpm_meeting_1.xml"
          result = RelatonBipm::BipmBibliography.get "CGPM Meeting 1"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end
      end

      it "CGPM resolution" do
        VCR.use_cassette "cgpm_resolution_1889_00" do
          file = "spec/fixtures/cgpm_resolution_1889_00.xml"
          result = RelatonBipm::BipmBibliography.get "CGPM Resolution 1889-00"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end
      end

      it "CGPM resolution" do
        VCR.use_cassette "cgpm_resolution_1889_00" do
          file = "spec/fixtures/cgpm_resolution_1889_00.xml"
          result = RelatonBipm::BipmBibliography.get "CGPM Resolution 1889"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end
      end

      it "CIPM decision" do
        VCR.use_cassette "cipm_decision_2012_01" do
          file = "spec/fixtures/cipm_decision_2012_01.xml"
          result = RelatonBipm::BipmBibliography.get "CIPM Decision 2012-01"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end
      end

      it "CIPM with year in parenthesis" do
        VCR.use_cassette "cipm_decision_2012_01" do
          file = "spec/fixtures/cipm_decision_2012_01.xml"
          result = RelatonBipm::BipmBibliography.get "CIPM Decision 1 (2012)"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .sub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end
      end

      it "using French reference" do
        VCR.use_cassette "cipm_decision_2012_01" do
          file = "spec/fixtures/cipm_decision_2012_01.xml"
          result = RelatonBipm::BipmBibliography.get "CIPM Décision 2012-01"
          xml = result.to_xml(bibdata: true)
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .sub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
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
          result = RelatonBipm::BipmBibliography.get "BIPM Metrologia 29 6 373"
          xml = result.to_xml bibdata: true
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .sub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end
      end

      it "wrong page", vcr: "metrologia_34_3_9" do
        expect do
          result = RelatonBipm::BipmBibliography.get "BIPM Metrologia 34 3 9"
          expect(result).to be_nil
        end.to output(
          %r{
            \[relaton-bipm\]\sNo\sarticle\sis\savailable\sat\sthe\sspecified\sstart\spage\s"9"\sin\sissue\s"BIPM\sMetrologia\s34\s3"\.\n
            \[relaton-bipm\]\sAvailable\sarticles\sin\sthe\sissue\sstart\sat\sthe\sfollowing\spages:\s\(201,\s211,\s215,\s235,\s241,\s245,\s251,\s257,\s261,\s291,\s293,\s295\)
          }x,
        ).to_stderr
      end

      it "with 403 response code", vcr: "metrologia_50_4_385" do
        result = RelatonBipm::BipmBibliography.get "BIPM Metrologia 50 4 385"
        expect(result.docidentifier[0].id).to eq "Metrologia 50 4 385"
      end
    end
  end
end
