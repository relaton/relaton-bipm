describe RelatonBipm::RawdataBipmMetrologia::ArticleParser do
  it "create instance" do
    path = "rawdata-bipm-metrologia//data/2022-04-05T10_55_52_content/0026-1394/0026-1394_55/0026-1394_55_1/0026-1394_55_1_L13/met_55_1_L13.xml"
    expect(File).to receive(:read).with(path, encoding: "UTF-8").and_return :xml
    expect(Nokogiri).to receive(:XML).with(:xml).and_return :doc
    parser = double "parser"
    expect(parser).to receive(:parse)
    expect(described_class).to receive(:new).with(:doc, "55", "1", "L13").and_return parser
    described_class.parse path
  end

  context "instance methods" do
    let(:doc) { double "doc" }
    subject do
      expect(doc).to receive(:at).with("/article").and_return :doc
      expect(doc).to receive(:at).with("/article/front/article-meta").and_return :meta
      described_class.new doc, "29", "6", "389"
    end

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

    it "parse" do
      expect(subject).to receive(:parse_docid).and_return :docid
      expect(subject).to receive(:parse_title).and_return :title
      expect(subject).to receive(:parse_contributor).and_return :contributor
      expect(subject).to receive(:parse_date).and_return :date
      expect(subject).to receive(:parse_copyright).and_return :copyright
      expect(subject).to receive(:parse_abstract).and_return :abstract
      expect(subject).to receive(:parse_relation).and_return :relation
      expect(subject).to receive(:parse_series).and_return :series
      expect(subject).to receive(:parse_extent).and_return :extent
      expect(subject).to receive(:parse_type).and_return :type
      expect(subject).to receive(:parse_doctype).and_return :doctype
      expect(subject).to receive(:parse_link).and_return :link
      expect(RelatonBipm::BipmBibliographicItem).to receive(:new).with(
        docid: :docid, title: :title, contributor: :contributor, date: :date,
        copyright: :copyright, abstract: :abstract, relation: :relation,
        series: :series, extent: :extent, type: :type, doctype: :doctype, link: :link
      ).and_return :item
      expect(subject.parse).to eq :item
    end

    it "parse_docid" do
      subject.instance_variable_set :@doc, doc_series_id.at("/article")
      subject.instance_variable_set :@meta, doc_series_id.at("/article/front/article-meta")
      docid = subject.parse_docid
      expect(docid).to be_instance_of Array
      expect(docid.size).to eq 2
      expect(docid[0]).to be_instance_of RelatonBib::DocumentIdentifier
      expect(docid[0].id).to eq "Metrologia 29 6 389"
      expect(docid[0].type).to eq "BIPM"
      expect(docid[0].primary).to be true
      expect(docid[1]).to be_instance_of RelatonBib::DocumentIdentifier
      expect(docid[1].primary).to be nil
      expect(docid[1].id).to eq "10.1088/0026-1394/29/6/389"
      expect(docid[1].type).to eq "doi"
    end

    context "volume_issue_article" do
      it "with missing page" do
        doc = Nokogiri::XML <<~XML
          <article>
            <front>
              <article-meta>
                <article-id pub-id-type="manuscript">1_29_6</article-id>
                <volume>1</volume>
                <issue>29</issue>
              </article-meta>
            </front>
          </article>
        XML
        subject.instance_variable_set :@doc, doc.at("/article")
        subject.instance_variable_set :@meta, doc.at("/article/front/article-meta")
        expect(subject.volume_issue_article).to eq "29 6 389"
      end
    end

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

    it "parse_contrib" do
      doc = Nokogiri::XML <<~XML
        <article>
          <front>
            <article-meta>
              <contrib-group>
                <contrib contrib-type="author">
                  <name>
                    <surname>Smith</surname>
                    <given-names>John M G</given-names>
                  </name>
                  <xref ref-type="aff" rid="aff1"/>
                </contrib>
                <contrib contrib-type="author" xlink:type="simple">
                  <collab>Sentinel-3 L2 Products and Algorithm Team</collab>
                </contrib>
                <aff id="aff1">
                  <label>1</label>Division of Applied Physics, National Research Council, Ottawa, Canada</aff>
              </contrib-group>
            </article-meta>
          </front>
        </article>
      XML
      subject.instance_variable_set :@doc, doc.at("/article")
      subject.instance_variable_set :@meta, doc.at("/article/front/article-meta")
      contrib = subject.parse_contributor
      expect(contrib).to be_instance_of Array
      expect(contrib.size).to eq 2
      expect(contrib[0]).to be_instance_of RelatonBib::ContributionInfo
      expect(contrib[0].role).to be_instance_of Array
      expect(contrib[0].role[0].type).to eq "author"
      expect(contrib[0].entity).to be_instance_of RelatonBib::Person
      expect(contrib[0].entity.name.surname).to be_instance_of RelatonBib::LocalizedString
      expect(contrib[0].entity.name.surname.content).to eq "Smith"
      expect(contrib[0].entity.name.forename).to be_instance_of Array
      expect(contrib[0].entity.name.forename[0].content).to eq "John"
      expect(contrib[0].entity.name.forename[0].initial).to eq "M"
      expect(contrib[0].entity.name.forename[1].initial).to eq "G"
      expect(contrib[0].entity.affiliation).to be_instance_of Array
      expect(contrib[0].entity.affiliation[0]).to be_instance_of RelatonBib::Affiliation
      expect(contrib[0].entity.affiliation[0].organization).to be_instance_of RelatonBib::Organization
      expect(contrib[0].entity.affiliation[0].organization.name).to be_instance_of Array
      expect(contrib[0].entity.affiliation[0].organization.name[0]).to be_instance_of RelatonBib::LocalizedString
      expect(contrib[0].entity.affiliation[0].organization.name[0].content).to eq "Division of Applied Physics, National Research Council"
      expect(contrib[0].entity.affiliation[0].organization.contact).to be_instance_of Array
      expect(contrib[0].entity.affiliation[0].organization.contact[0]).to be_instance_of RelatonBib::Address
      expect(contrib[0].entity.affiliation[0].organization.contact[0].city).to eq "Ottawa"
      expect(contrib[0].entity.affiliation[0].organization.contact[0].country).to eq "Canada"
      expect(contrib[1].entity).to be_instance_of RelatonBib::Organization
      expect(contrib[1].entity.name).to be_instance_of Array
      expect(contrib[1].entity.name[0]).to be_instance_of RelatonBib::LocalizedString
      expect(contrib[1].entity.name[0].content).to eq "Sentinel-3 L2 Products and Algorithm Team"
    end

    it "fullname" do
      doc = Nokogiri::XML <<~XML
        <article>
          <front>
            <article-meta>
              <contrib-group>
                <contrib contrib-type="author">
                  <name>
                    <surname>E C Morris</surname>
                  </name>
                </contrib>
              </contrib-group>
            </article-meta>
          </front>
        </article>
      XML
      contrib = doc.at("/article/front/article-meta/contrib-group/contrib/name")
      fullname = subject.fullname contrib
      expect(fullname).to be_instance_of RelatonBib::FullName
      expect(fullname.surname).to be_instance_of RelatonBib::LocalizedString
      expect(fullname.surname.content).to eq "E C Morris"
      expect(fullname.surname.language).to eq ["en"]
      expect(fullname.surname.script).to eq ["Latn"]
    end

    it "parse_date" do
      subject.instance_variable_set :@doc, doc_dates.at("/article")
      subject.instance_variable_set :@meta, doc_dates.at("/article/front/article-meta")
      date = subject.parse_date
      expect(date).to be_instance_of Array
      expect(date.size).to eq 1
      expect(date[0]).to be_instance_of RelatonBib::BibliographicDate
      expect(date[0].type).to eq "published"
      expect(date[0].on).to eq "2019-01-01"
    end

    it "parse_copyright" do
      doc = Nokogiri::XML <<~XML
        <article>
          <front>
            <article-meta>
              <permissions>
                <copyright-statement>\u00a9 2022 BIPM &amp; IOP Publishing Ltd</copyright-statement>
                <copyright-year>2022</copyright-year>
              </permissions>
            </article-meta>
          </front>
        </article>
      XML
      subject.instance_variable_set :@doc, doc.at("/article")
      subject.instance_variable_set :@meta, doc.at("/article/front/article-meta")
      copyright = subject.parse_copyright
      expect(copyright).to be_instance_of Array
      expect(copyright.size).to eq 1
      expect(copyright[0]).to be_instance_of RelatonBib::CopyrightAssociation
      expect(copyright[0].owner).to be_instance_of Array
      expect(copyright[0].owner.size).to eq 2
      expect(copyright[0].owner[0]).to be_instance_of RelatonBib::ContributionInfo
      expect(copyright[0].owner[0].entity).to be_instance_of RelatonBib::Organization
      expect(copyright[0].owner[0].entity.name).to be_instance_of Array
      expect(copyright[0].owner[0].entity.name[0]).to be_instance_of RelatonBib::LocalizedString
      expect(copyright[0].owner[0].entity.name[0].content).to eq "BIPM"
      expect(copyright[0].owner[1].entity.name[0].content).to eq "IOP Publishing Ltd"
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

    it "parse_relation" do
      subject.instance_variable_set :@doc, doc_dates.at("/article")
      subject.instance_variable_set :@meta, doc_dates.at("/article/front/article-meta")
      rels = subject.parse_relation
      expect(rels).to be_instance_of Array
      expect(rels.size).to eq 2
      expect(rels[0]).to be_instance_of RelatonBib::DocumentRelation
    end

    it "parse_series" do
      subject.instance_variable_set :@doc, doc_series_id.at("/article")
      series = subject.parse_series
      expect(series).to be_instance_of Array
      expect(series.size).to eq 1
      expect(series[0]).to be_instance_of RelatonBib::Series
      expect(series[0].title).to be_instance_of RelatonBib::TypedTitleString
      expect(series[0].title.title.content).to eq "Metrologia"
    end

    it "parse_extent" do
      subject.instance_variable_set :@doc, doc_series_id.at("/article")
      subject.instance_variable_set :@meta, doc_series_id.at("/article/front/article-meta")
      extent = subject.parse_extent
      expect(extent).to be_instance_of Array
      expect(extent.size).to eq 3
      expect(extent[0]).to be_instance_of RelatonBib::Locality
      expect(extent[0].type).to eq "volume"
      expect(extent[0].reference_from).to eq "29"
      expect(extent[1].type).to eq "issue"
      expect(extent[1].reference_from).to eq "6"
      expect(extent[2].type).to eq "page"
      expect(extent[2].reference_from).to eq "373"
      expect(extent[2].reference_to).to eq "378"
    end

    it "parse_type" do
      expect(subject.parse_type).to eq "article"
    end

    it "parse_doctype" do
      doctype = subject.parse_doctype
      expect(doctype).to be_instance_of RelatonBipm::DocumentType
      expect(doctype.type).to eq "article"
    end

    it "parse_link" do
      doc = Nokogiri::XML File.read("spec/fixtures/met_52_1_155.xml", encoding: "UTF-8")
      subject.instance_variable_set :@meta, doc.at("/article/front/article-meta")
      link = subject.parse_link
      expect(link).to be_instance_of Array
      expect(link.size).to eq 2
      expect(link[0]).to be_instance_of RelatonBib::TypedUri
      expect(link[0].content.to_s).to eq "https://doi.org/10.1088/0026-1394/52/1/155"
      expect(link[0].type).to eq "src"
      expect(link[1].type).to eq "doi"
    end
  end
end
