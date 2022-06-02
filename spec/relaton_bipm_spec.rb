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
    VCR.use_cassette "cctf_meetings_5" do
      result = RelatonBipm::BipmBibliography.search "BIPM CCTF Meetings 5"
      expect(result).to be_instance_of RelatonBipm::BipmBibliographicItem
    end
  end

  context "get document" do
    it "CCTF Recommendation" do
      VCR.use_cassette "cctf_recommendation_1970_02" do
        result = RelatonBipm::BipmBibliography.get "CCTF Recommendation 1970-02"
        result
      end
    end

    it "CGPM meetings" do
      VCR.use_cassette "cgpm_meetings_1" do
        file = "spec/fixtures/cgpm_meetings_1.xml"
        result = RelatonBipm::BipmBibliography.get "CGPM Meetings 1"
        xml = result.to_xml bibdata: true
        File.write file, xml, encoding: "UTF-8" unless File.exist? file
        expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
          .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
      end
    end

    it "CGPM resolution" do
      VCR.use_cassette "cgpm_resolution_1889_00" do
        file = "spec/fixtures/cgpm_resolution_1889_00.xml"
        result = RelatonBipm::BipmBibliography.get "CGPM Resolution 1889-00"
        xml = result.to_xml bibdata: true
        File.write file, xml, encoding: "UTF-8" unless File.exist? file
        expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
          .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
      end
    end

    it "CGPM resolution" do
      VCR.use_cassette "cgpm_resolution_1889_00" do
        file = "spec/fixtures/cgpm_resolution_1889_00.xml"
        result = RelatonBipm::BipmBibliography.get "CGPM Resolution 1889"
        xml = result.to_xml bibdata: true
        File.write file, xml, encoding: "UTF-8" unless File.exist? file
        expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
          .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
      end
    end

    it "CIPM decision" do
      VCR.use_cassette "cipm_decision_2012_01" do
        file = "spec/fixtures/cipm_decision_2012_01.xml"
        result = RelatonBipm::BipmBibliography.get "CIPM Decision 2012-01"
        xml = result.to_xml(bibdata: true).gsub(/<fetched>\d{4}-\d{2}-\d{2}<\/fetched>/, "")
        File.write file, xml, encoding: "UTF-8" unless File.exist? file
        expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
          .gsub(/<fetched>\d{4}-\d{2}-\d{2}<\/fetched>/, "")
      end
    end

    it "CIPM with year in parenthesis" do
      VCR.use_cassette "cipm_decision_2012_01" do
        file = "spec/fixtures/cipm_decision_2012_01.xml"
        result = RelatonBipm::BipmBibliography.get "CIPM Decision 1 (2012)"
        xml = result.to_xml(bibdata: true).gsub(/<fetched>\d{4}-\d{2}-\d{2}<\/fetched>/, "")
        File.write file, xml, encoding: "UTF-8" unless File.exist? file
        expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
          .gsub(/<fetched>\d{4}-\d{2}-\d{2}<\/fetched>/, "")
      end
    end

    it "using French reference" do
      VCR.use_cassette "cipm_decision_2012_01" do
        file = "spec/fixtures/cipm_decision_2012_01.xml"
        result = RelatonBipm::BipmBibliography.get "CIPM Décision 2012-01"
        xml = result.to_xml(bibdata: true).gsub(/<fetched>\d{4}-\d{2}-\d{2}<\/fetched>/, "")
        File.write file, xml, encoding: "UTF-8" unless File.exist? file
        expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
          .gsub(/<fetched>\d{4}-\d{2}-\d{2}<\/fetched>/, "")
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

      it "article" do
        VCR.use_cassette "metrologia_29_6_373" do
          file = "spec/fixtures/metrologia_29_6_373.xml"
          result = RelatonBipm::BipmBibliography.get "BIPM Metrologia 29 6 373"
          xml = result.to_xml bibdata: true
          File.write file, xml, encoding: "UTF-8" unless File.exist? file
          expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
            .sub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        end
      end
    end
  end
end
