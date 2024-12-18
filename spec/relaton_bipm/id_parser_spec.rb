describe RelatonBipm::Id do
  context "ID parser" do
    shared_examples "parses ID" do |ref, result|
      subject(:id) { RelatonBipm::Id.new.parse ref }

      it "parses #{ref}" do
        expect(id).to eq result
      end
    end

    context "outcomes" do
      it_behaves_like "parses ID", "CCTF -- Recommendation 2 (2009)", group: "CCTF", type: "Recommendation", number: "2", year: "2009"
      it_behaves_like "parses ID", "CCTF Recommendation 2 (2009)", group: "CCTF", type: "Recommendation", number: "2", year: "2009"
      it_behaves_like "parses ID", "CCTF Recommendation 2009-02", group: "CCTF", type: "Recommendation", number: "02", year: "2009"
      it_behaves_like "parses ID", "CCTF -- REC 2 (2009)", group: "CCTF", type: "REC", number: "2", year: "2009"
      it_behaves_like "parses ID", "CCTF -- REC 2 (2009, EN)", group: "CCTF", type: "REC", number: "2", year: "2009", lang: "EN"
      it_behaves_like "parses ID", "CCTF -- Recommandation 2 (2009)", group: "CCTF", type: "Recommandation", number: "2", year: "2009"
      it_behaves_like "parses ID", "CGPM -- Resolution (1889)", group: "CGPM", type: "Resolution", year: "1889"
      it_behaves_like "parses ID", "CGPM Resolution 1889-00", group: "CGPM", type: "Resolution", year: "1889", number: "00"
      it_behaves_like "parses ID", "CGPM Meeting 9", group: "CGPM", type: "Meeting", number: "9"
      it_behaves_like "parses ID", "Decision CIPM/101-1 (2012)", group: "CIPM", type: "Decision", number: "101-1", year: "2012"
      it_behaves_like "parses ID", "DECN CIPM/101-66 (2012, FR)", group: "CIPM", type: "DECN", number: "101-66", year: "2012", lang: "FR"
      it_behaves_like "parses ID", "Décision CIPM/101-66 (2012)", group: "CIPM", type: "Décision", number: "101-66", year: "2012"
      it_behaves_like "parses ID", "CIPM Decision 2017-10", group: "CIPM", type: "Decision", number: "10", year: "2017"
      it_behaves_like "parses ID", "CIPM -- Meeting 103 (2014)", group: "CIPM", type: "Meeting", number: "103", year: "2014"
      it_behaves_like "parses ID", "CCL -- Réunion 9 (1997)", group: "CCL", type: "Réunion", number: "9", year: "1997"
      it_behaves_like "parses ID", "CCM -- REC 1 (2010)", group: "CCM", type: "REC", number: "1", year: "2010"
      it_behaves_like "parses ID", "CCPR -- Meeting 25 (2022)", group: "CCPR", type: "Meeting", number: "25", year: "2022"
      it_behaves_like "parses ID", "CCQM -- Réunion 11 (2005)", group: "CCQM", type: "Réunion", number: "11", year: "2005"
      it_behaves_like "parses ID", "CCRI -- Meeting 21 (2009)", group: "CCRI", type: "Meeting", number: "21", year: "2009"
      it_behaves_like "parses ID", "CCT -- REC 1 (2005, EN)", group: "CCT", type: "REC", number: "1", year: "2005", lang: "EN"
      it_behaves_like "parses ID", "CCU -- Meeting 22 (2016)", group: "CCU", type: "Meeting", number: "22", year: "2016"
      it_behaves_like "parses ID", "JCGM -- Réunion 15 (2009)", group: "JCGM", type: "Réunion", number: "15", year: "2009"
      it_behaves_like "parses ID", "JCRB -- Action 10-1 (2003)", group: "JCRB", type: "Action", number: "10-1", year: "2003"
      it_behaves_like "parses ID", "Recommendation JCRB/43-1 (2021)", group: "JCRB", type: "Recommendation", number: "43-1", year: "2021"
      it_behaves_like "parses ID", "JCGM 100:2008", group: "JCGM", number: "100", year: "2008"
      it_behaves_like "parses ID", "JCGM 200:2008 Corrigendum", group: "JCGM", number: "200", year: "2008", corr: "Corrigendum"
      it_behaves_like "parses ID", "JCGM GUM-6:2020", group: "JCGM", number: "GUM-6", year: "2020"
      it_behaves_like "parses ID", "JCGM GUM", group: "JCGM", number: "GUM"
      it_behaves_like "parses ID", "JCGM VIM-3", group: "JCGM", number: "VIM-3"
    end

    context "SI Brochure" do
      it_behaves_like "parses ID", "SI Brochure, Part 1", group: "SI", type: "Brochure", part: "1"
      it_behaves_like "parses ID", "SI Brochure, Partie 1", group: "SI", type: "Brochure", part: "1"
      it_behaves_like "parses ID", "SI Brochure Part 1", group: "SI", type: "Brochure", part: "1"
      it_behaves_like "parses ID", "SI Brochure, Appendix 4", group: "SI", type: "Brochure", append: "4"
      it_behaves_like "parses ID", "SI Brochure, Annexe 4", group: "SI", type: "Brochure", append: "4"
      it_behaves_like "parses ID", "SI Brochure Appendix 4", group: "SI", type: "Brochure", append: "4"
      it_behaves_like "parses ID", "CCEM-GD-RSI-1", group: "CCEM", type: "GD-RSI", number: "1"
      it_behaves_like "parses ID", "CCL-GD-MeP-1", group: "CCL", type: "GD-MeP", number: "1"
      it_behaves_like "parses ID", "CCM-GD-RSI-1", group: "CCM", type: "GD-RSI", number: "1"
      it_behaves_like "parses ID", "SI MEP A1", group: "SI", type: "MEP", number: "A1"
      it_behaves_like "parses ID", "Rapport BIPM-2019/05", group: "Rapport", type: "BIPM", number: "2019/05"
    end

    context "Metrologia" do
      it_behaves_like "parses ID", "Metrologia", group: "Metrologia"
      it_behaves_like "parses ID", "Metrologia 11", group: "Metrologia", number: "11"
      it_behaves_like "parses ID", "Metrologia 12 4", group: "Metrologia", number: "12 4"
      it_behaves_like "parses ID", "Metrologia 26 4 E01", group: "Metrologia", number: "26 4 E01"
      it_behaves_like "parses ID", "Metrologia 39 1A 10", group: "Metrologia", number: "39 1A 10"
      it_behaves_like "parses ID", "Metrologia 53 1 aa0f0c", group: "Metrologia", number: "53 1 aa0f0c"
    end
  end

  it "invalid ID" do
    expect do
      RelatonBipm::Id.new.parse "CCTF -- Recommendation 2 (2009"
    end.to raise_error RelatonBib::RequestError
  end

  context "comparing IDs" do
    shared_examples "comparing IDs" do |ref1, ref2, result = true|
      it "abbreviation and full type names are equal" do
        id1 = RelatonBipm::Id.new.parse ref1
        id2 = RelatonBipm::Id.new.parse ref2
        expect(id1 == id2).to eq result
      end
    end

    context "outcomes" do
      it_behaves_like "comparing IDs", "CCTF -- Recommendation 2 (2009)", "CCTF REC 2 (2009)"
      it_behaves_like "comparing IDs", "JCRB -- Meeting 22 (2009)", "JCRB -- Réunion 22 (2009)"
      it_behaves_like "comparing IDs", "CIPM Decision 106-10 (2017)", "CIPM -- Décision 106-10 (2017)"
      it_behaves_like "comparing IDs", "CGPM Resolution 1889-00", "CGPM -- Resolution (1889)"
      it_behaves_like "comparing IDs", "CCTF -- REC 1 (2001, EN)", "CCTF -- REC 1 (2001, FR)", false
      it_behaves_like "comparing IDs", "CIPM Declaration (2001)", "CIPM -- Déclaration (2001)"
      it_behaves_like "comparing IDs", "Recommendation JCRB/43-1 (2021)", "JCRB -- Recommandation 43-1 (2021)"
      it_behaves_like "comparing IDs", "CIPM Meeting 43", "CIPM -- Réunion 43 (1950)"
      it_behaves_like "comparing IDs", "CGPM RES 1 (1889)", "CGPM Resolution (1889)"
    end

    context "SI Brochure" do
      it_behaves_like "comparing IDs", "SI Brochure", "SI Brochure"
      it_behaves_like "comparing IDs", "SI Brochure", "SI Brochure, Appendix 4", false
      it_behaves_like "comparing IDs", "SI Brochure, Appendix 4", "SI Brochure, Appendix 4"
    end

    context "Metrologia" do
      it_behaves_like "comparing IDs", "Metrologia", "Metrologia"
      it_behaves_like "comparing IDs", "Metrologia", "Metrologia 11", false
      it_behaves_like "comparing IDs", "Metrologia 11", "Metrologia 11"
      it_behaves_like "comparing IDs", "Metrologia 11", "Metrologia 12 4", false
      it_behaves_like "comparing IDs", "Metrologia 12 4", "Metrologia 12 4"
      it_behaves_like "comparing IDs", "Metrologia 12 4", "Metrologia 26 4 E01", false
      it_behaves_like "comparing IDs", "Metrologia 26 4 E01", "Metrologia 26 4 E01"
    end

    context "JCGM" do
      it_behaves_like "comparing IDs", "JCGM 100:2008", "JCGM 100:2008"
      it_behaves_like "comparing IDs", "JCGM 100:2008", "JCGM 101:2008", false
      it_behaves_like "comparing IDs", "JCGM 200:2008 Corrigendum", "JCGM 200:2008 Corrigendum"
      it_behaves_like "comparing IDs", "JCGM 200:2008 Corrigendum", "JCGM 200:2008", false
      it_behaves_like "comparing IDs", "JCGM 200:2008", "JCGM 200:2008 Corrigendum", false
      it_behaves_like "comparing IDs", "JCGM GUM-6:2020", "JCGM GUM-6:2020"
      it_behaves_like "comparing IDs", "JCGM GUM-6:2020", "JCGM GUM:2020", false
      it_behaves_like "comparing IDs", "JCGM GUM:2020", "JCGM GUM", false
      it_behaves_like "comparing IDs", "JCGM VIM-3", "JCGM VIM-3"
      it_behaves_like "comparing IDs", "JCGM VIM-3", "JCGM VIM-2", false
    end

    it "`CIPM RES 1` should not be equal to `CGPM Resolution (1889)`" do
      id1 = RelatonBipm::Id.new.parse "CIPM RES 1"
      id2 = RelatonBipm::Id.new.parse "CGPM Resolution (1889)"
      expect(id1 == id2).to be false
    end
  end
end
