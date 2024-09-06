# encoding: UTF-8

describe RelatonBipm::RawdataBipmMetrologia::ArticleParser do
  let(:doc) { Nokogiri::XML(File.read("spec/fixtures/met12_3_273.xml", encoding: "UTF-8")) }
  subject { described_class.new doc, "12", "3", "273" }

  it "call parser method" do
    path = "rawdata-bipm-metrologia//data/2022-04-05T10_55_52_content/0026-1394/0026-1394_55/0026-1394_55_1/0026-1394_55_1_L13/met_55_1_L13.xml"
    expect(File).to receive(:read).with(path, encoding: "UTF-8").and_return :xml
    expect(Nokogiri).to receive(:XML).with(:xml).and_return :doc
    parser = double "parser"
    expect(parser).to receive(:parse)
    expect(described_class).to receive(:new).with(:doc, "55", "1", "L13").and_return parser
    described_class.parse path
  end

  it "create instance" do
    expect(subject.instance_variable_get(:@doc)).to eq doc.at("/article")
    expect(subject.instance_variable_get(:@meta)).to eq doc.at("/article/front/article-meta")
    expect(subject.instance_variable_get(:@journal)).to eq "12"
    expect(subject.instance_variable_get(:@volume)).to eq "3"
    expect(subject.instance_variable_get(:@article)).to eq "273"
  end

  context "instance methods" do
    # let(:doc) { double "doc" }

    # subject do
    #   expect(doc).to receive(:at).with("/article").and_return :doc
    #   expect(doc).to receive(:at).with("/article/front/article-meta").and_return :meta
    #   described_class.new doc, "29", "6", "389"
    # end

    let(:doc_series_id) do
      Nokogiri::XML <<~XML
        <article>
          <front>
            <journal-meta>
              <journal-title-group>
                <journal-title>Metrologia</journal-title>
              </journal-title-group>
            </journal-meta>
            <article-meta>
              <article-id pub-id-type="publisher-id">0026-1394__</article-id>
              <article-id pub-id-type="doi">10.1088/0026-1394/29/6/389</article-id>
              <article-id pub-id-type="manuscript">001</article-id>
              <volume>29</volume>
              <issue>6</issue>
              <fpage>373</fpage>
              <lpage>378</lpage>
            </article-meta>
          </front>
        </article>
      XML
    end

    let(:doc_dates) do
      Nokogiri::XML <<~XML
        <article>
          <front>
            <article-meta>
              <pub-date pub-type="epub">
                <day>01</day>
                <month>1</month>
                <year>2019</year>
              </pub-date>
              <pub-date pub-type="ppub">
                <day>02</day>
                <month>3</month>
                <year>2020</year>
              </pub-date>
            </article-meta>
          </front>
        </article>
      XML
    end

    context "parse" do
      let(:item) { subject.parse }
      it { expect(item).to be_instance_of RelatonBipm::BipmBibliographicItem }
      it { expect(item.docidentifier[0]).to be_instance_of RelatonBib::DocumentIdentifier }
      it { expect(item.title).to be_instance_of RelatonBib::TypedTitleStringCollection }
      it { expect(item.contributor[0]).to be_instance_of RelatonBib::ContributionInfo }
      it { expect(item.date[0]).to be_instance_of RelatonBib::BibliographicDate }
      it { expect(item.copyright[0]).to be_instance_of RelatonBib::CopyrightAssociation }
      it { expect(item.abstract[0]).to be_instance_of RelatonBib::FormattedString }
      it { expect(item.relation[0]).to be_instance_of RelatonBib::DocumentRelation }
      it { expect(item.series[0]).to be_instance_of RelatonBib::Series }
      it { expect(item.extent[0]).to be_instance_of RelatonBib::Locality }
      it { expect(item.type).to eq "article" }
      it { expect(item.doctype).to be_instance_of RelatonBipm::DocumentType }
      it { expect(item.link[0]).to be_instance_of RelatonBib::TypedUri }
    end

    context "parse_docid" do
      let(:docid) { subject.parse_docid }
      it { expect(docid[0]).to be_instance_of RelatonBib::DocumentIdentifier }
      it { expect(docid[0].id).to eq "Metrologia 12 3 273" }
      it { expect(docid[0].type).to eq "BIPM" }
      it { expect(docid[0].primary).to be true }
      it { expect(docid[1].id).to eq "10.1088/0026-1394/49/3/273" }
      it { expect(docid[1].type).to eq "doi" }
      it { expect(docid[1].primary).to be nil }
    end

    it("volume_issue_article") { expect(subject.volume_issue_article).to eq "12 3 273" }

    it "parse_title" do
      doc = Nokogiri::XML <<~XML
        <article>
          <front>
            <article-meta>
              <title-group>
                <article-title xml:lang="en">Title</article-title>
              </title-group>
            </article-meta>
          </front>
        </article>
      XML
      subject.instance_variable_set :@doc, doc.at("/article")
      subject.instance_variable_set :@meta, doc.at("/article/front/article-meta")
      title = subject.parse_title
      expect(title).to be_instance_of Array
      expect(title.size).to eq 1
      expect(title[0]).to be_instance_of RelatonBib::TypedTitleString
      expect(title[0].title.content).to eq "Title"
      expect(title[0].title.language).to eq ["en"]
      expect(title[0].title.script).to eq ["Latn"]
    end

    context "parse_contrib" do
      context "organization" do
        let(:doc) do
          Nokogiri::XML <<~XML
            <article>
              <front>
                <article-meta>
                  <contrib-group>
                    <contrib contrib-type="author" xlink:type="simple">
                      <collab>Sentinel-3 L2 Products and Algorithm Team</collab>
                    </contrib>
                  </contrib-group>
                </article-meta>
              </front>
            </article>
          XML
        end

        before do
          subject.instance_variable_set :@doc, doc.at("/article")
          subject.instance_variable_set :@meta, doc.at("/article/front/article-meta")
        end

        let(:contrib) { subject.parse_contributor }
        it { expect(contrib[0]).to be_instance_of RelatonBib::ContributionInfo }
        it { expect(contrib[0].role[0].type).to eq "author" }
        it { expect(contrib[0].entity).to be_instance_of RelatonBib::Organization }
        it { expect(contrib[0].entity.name).to be_instance_of Array }
        it { expect(contrib[0].entity.name[0]).to be_instance_of RelatonBib::LocalizedString }
        it { expect(contrib[0].entity.name[0].content).to eq "Sentinel-3 L2 Products and Algorithm Team" }
      end

      context "person" do
        let(:contrib) { subject.parse_contributor }
        it { expect(contrib.size).to eq 5 }
        it { expect(contrib[0]).to be_instance_of RelatonBib::ContributionInfo }
        it { expect(contrib[0].role[0].type).to eq "author" }
        it { expect(contrib[0].entity).to be_instance_of RelatonBib::Person }
        it { expect(contrib[0].entity.name.completename).to be_instance_of RelatonBib::LocalizedString }
        it { expect(contrib[0].entity.affiliation[0]).to be_instance_of RelatonBib::Affiliation }
      end
    end

    context "parse_affiliation" do
      shared_examples "ignore affiliation" do |xml|
        let(:aff) { Nokogiri::XML::DocumentFragment.parse(xml).at("aff") }
        it { expect(subject.parse_affiliation(aff)).to be_nil }
      end

      it_behaves_like "ignore affiliation", '<aff id="aff1"><label>1</label>Permanent address:</aff>'
      it_behaves_like "ignore affiliation", '<aff id="aff1"><label>1</label>Germany</aff>'
      it_behaves_like "ignore affiliation", '<aff id="aff1"><label>1</label>Guest</aff>'
      it_behaves_like "ignore affiliation", '<aff id="aff1"><label>1</label>Deceased</aff>'
      it_behaves_like "ignore affiliation",
        '<aff id="aff1"><label>1</label>Author to whom any correspondence should be addressed</aff>'
      it_behaves_like "ignore affiliation",
        '<aff id="aff1"><label>1</label><institution>1005 Southover Lane</institution></aff>'

      context "with institution & subdivision" do
        let(:affiliation) { subject.parse_affiliation doc.at("aff") }
        it { expect(affiliation).to be_instance_of RelatonBib::Affiliation }
        it { expect(affiliation.organization).to be_instance_of RelatonBib::Organization }
        it { expect(affiliation.organization.name[0].content).to eq "Korea Research Institute of Standards and Science" }
        it { expect(affiliation.organization.subdivision[0].content).to eq "Division of Physical Metrology" }
        it { expect(affiliation.organization.contact[0].formatted_address).to eq "267 Gajeong-ro, Yuseong-gu, Daejeon 305-340, Republic of Korea" }
      end

      context "with institution only" do
        let(:doc) { Nokogiri::XML File.read("spec/fixtures/met_52_1_155.xml", encoding: "UTF-8") }
        let(:affiliation) { subject.parse_affiliation doc.at("aff") }
        it { expect(affiliation).to be_instance_of RelatonBib::Affiliation }
        it { expect(affiliation.organization).to be_instance_of RelatonBib::Organization }
        it { expect(affiliation.organization.name[0].content).to eq "Bureau International des Poids et Mesures (BIPM)" }
        it { expect(affiliation.organization.subdivision).to be_empty }
        it { expect(affiliation.organization.contact[0].formatted_address).to eq "Pavillon de Breteuil, 92312 CEDEX, Sèvres, France" }
      end

      context "without institution" do
        let(:aff_with_tags) do
          aff = Nokogiri::XML::DocumentFragment.parse(<<~XML).at("aff")
            <aff id="aff1">
              <label>1</label>DRA/SRIRMa, C.E.N. Saclay, B.P. n<sup>o</sup> 2, F-91190 Gif s/Yvette, France</aff>
          XML
          subject.parse_affiliation aff
        end

        let(:aff_with_amp) do
          aff = Nokogiri::XML::DocumentFragment.parse(<<~XML).at("aff")
            <aff id="aff1">
              <label>1</label>Department of Physics, Texas A &amp; M University, College Station, Texas 77843, USA</aff>
          XML
          subject.parse_affiliation aff
        end

        it { expect(aff_with_tags).to be_instance_of RelatonBib::Affiliation }
        it { expect(aff_with_tags.organization).to be_instance_of RelatonBib::Organization }
        it do
          expect(aff_with_tags.organization.name[0].content).to eq(
            "DRA/SRIRMa, C.E.N. Saclay, B.P. n<sup>o</sup> 2, F-91190 Gif s/Yvette, France"
          )
        end

        it do
          expect(aff_with_amp.organization.name[0].content).to eq(
            "Department of Physics, Texas A & M University, College Station, Texas 77843, USA"
          )
        end
      end
    end

    it "fullname" do
      contrib = doc.at("/article/front/article-meta/contrib-group/contrib/name")
      fullname = subject.fullname contrib
      expect(fullname).to be_instance_of RelatonBib::FullName
      expect(fullname.completename).to be_instance_of RelatonBib::LocalizedString
      expect(fullname.completename.content).to eq "Yong-Wan Kim"
      expect(fullname.completename.language).to eq ["en"]
      expect(fullname.completename.script).to eq ["Latn"]
    end

    it "parse_date" do
      date = subject.parse_date
      expect(date).to be_instance_of Array
      expect(date.size).to eq 1
      expect(date[0]).to be_instance_of RelatonBib::BibliographicDate
      expect(date[0].type).to eq "published"
      expect(date[0].on).to eq "2012-03-16"
    end

    it "parse_copyright" do
      copyright = subject.parse_copyright
      expect(copyright).to be_instance_of Array
      expect(copyright.size).to eq 1
      expect(copyright[0]).to be_instance_of RelatonBib::CopyrightAssociation
      expect(copyright[0].owner).to be_instance_of Array
      expect(copyright[0].owner.size).to eq 1
      expect(copyright[0].owner[0]).to be_instance_of RelatonBib::ContributionInfo
      expect(copyright[0].owner[0].entity).to be_instance_of RelatonBib::Organization
      expect(copyright[0].owner[0].entity.name).to be_instance_of Array
      expect(copyright[0].owner[0].entity.name[0]).to be_instance_of RelatonBib::LocalizedString
      expect(copyright[0].owner[0].entity.name[0].content).to eq "IOP Publishing Ltd"
    end

    it "parse_abstract" do
      doc = Nokogiri::XML <<~XML
        <article>
          <front>
            <article-meta>
              <abstract xml:lang="en">
                <title>Main text</title>
                <p>This pilot study was conducted ...</p>
                <p>To reach the main text click on <ext-link xlink:href="https://www.bipm.org/documents/20126/" xlink:type="simple">Final Report</ext-link>.</p>
              </abstract>
            </article-meta>
          </front>
        </article>
      XML
      subject.instance_variable_set :@doc, doc.at("/article")
      subject.instance_variable_set :@meta, doc.at("/article/front/article-meta")
      abstract = subject.parse_abstract
      expect(abstract).to be_instance_of Array
      expect(abstract.size).to eq 1
      expect(abstract[0]).to be_instance_of RelatonBib::FormattedString
      expect(abstract[0].language).to eq ["en"]
      expect(abstract[0].content).to be_equivalent_to <<~HTML
        Main text
        <p>This pilot study was conducted...</p>
        <p>To reach the main text click on Final Report.</p>
      HTML
    end

    context "parse_relation" do
      let(:rels) { subject.parse_relation }
      it { expect(rels).to be_instance_of Array }
      it { expect(rels.size).to eq 2 }
      it { expect(rels[0]).to be_instance_of RelatonBib::DocumentRelation }
    end

    context "parse_series" do
      let(:series) { subject.parse_series }
      it { expect(series).to be_instance_of Array }
      it { expect(series.size).to eq 1 }
      it { expect(series[0]).to be_instance_of RelatonBib::Series }
      it { expect(series[0].title).to be_instance_of RelatonBib::TypedTitleString }
      it { expect(series[0].title.title.content).to eq "Metrologia" }
    end

    context "parse_extent" do
      let(:doc) { Nokogiri::XML(File.read("spec/fixtures/met_52_1_155.xml", encoding: "UTF-8")) }
      let(:extent) { subject.parse_extent }
      it { expect(extent[0]).to be_instance_of RelatonBib::Locality }
      it { expect(extent[0].type).to eq "volume" }
      it { expect(extent[0].reference_from).to eq "52" }
      it { expect(extent[1].type).to eq "issue" }
      it { expect(extent[1].reference_from).to eq "1" }
      it { expect(extent[2].type).to eq "page" }
      it { expect(extent[2].reference_from).to eq "155" }
      it { expect(extent[2].reference_to).to eq "162" }
    end

    it("parse_type") { expect(subject.parse_type).to eq "article" }

    it "parse_doctype" do
      doctype = subject.parse_doctype
      expect(doctype).to be_instance_of RelatonBipm::DocumentType
      expect(doctype.type).to eq "article"
    end

    context "parse_link" do
      let(:doc) { Nokogiri::XML File.read("spec/fixtures/met_52_1_155.xml", encoding: "UTF-8") }
      let(:link) { subject.parse_link }
      it { expect(link[0]).to be_instance_of RelatonBib::TypedUri }
      it { expect(link[0].content.to_s).to eq "https://doi.org/10.1088/0026-1394/52/1/155" }
      it { expect(link[0].type).to eq "src" }
      it { expect(link[1].type).to eq "doi" }
    end
  end
end
