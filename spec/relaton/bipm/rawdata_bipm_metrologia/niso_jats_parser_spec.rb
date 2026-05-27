# encoding: UTF-8
require "relaton/bipm/rawdata_bipm_metrologia/niso_jats_parser"

describe Relaton::Bipm::RawdataBipmMetrologia::NisoJatsParser do
  let(:doc) { Niso::Jats::Article.from_xml source }

  it "call parser method" do
    path = "rawdata-bipm-metrologia//data/2022-04-05T10_55_52_content/0026-1394/0026-1394_55/0026-1394_55_1/0026-1394_55_1_L13/met_55_1_L13.xml"
    expect(File).to receive(:read).with(path, encoding: "UTF-8").and_return :xml
    expect(Niso::Jats::Article).to receive(:from_xml).with(:xml).and_return :doc
    parser = double "parser"
    expect(parser).to receive(:parse)
    expect(described_class).to receive(:new).with(:doc, "55", "1", "L13", {}).and_return parser
    described_class.parse path
  end

  context "met12_3_273" do
    let(:source) { File.read("spec/fixtures/rawdata-bipm/met12_3_273.xml", encoding: "UTF-8") }
    subject { described_class.new(doc, "12", "3", "273").parse }

    it { expect(subject).to be_instance_of Relaton::Bipm::ItemData }

    context "parse_docidentifier" do
      it { expect(subject.docidentifier[0]).to be_instance_of Relaton::Bib::Docidentifier }
      it { expect(subject.docidentifier[0].content).to eq "Metrologia 12 3 273" }
      it { expect(subject.docidentifier[0].type).to eq "BIPM" }
      it { expect(subject.docidentifier[0].primary).to be true }
      it { expect(subject.docidentifier[1].content).to eq "10.1088/0026-1394/49/3/273" }
      it { expect(subject.docidentifier[1].type).to eq "doi" }
    end

    it "parse_title" do
      expect(subject.title[0]).to be_instance_of Relaton::Bib::Title
      expect(subject.title[0].content).to eq(
        "Realization and validation of the detector-based absolute " \
        "integrating sphere method for luminous-flux measurement at KRISS",
      )
      expect(subject.title[0].script).to eq "Latn"
    end

    context "parse_contributor" do
      it { expect(subject.contributor.size).to eq 5 }
      it { expect(subject.contributor[0]).to be_instance_of Relaton::Bib::Contributor }
      it { expect(subject.contributor[0].role[0].type).to eq "author" }
      it { expect(subject.contributor[0].person).to be_instance_of Relaton::Bib::Person }
      it { expect(subject.contributor[0].person.name.completename).to be_instance_of Relaton::Bib::LocalizedString }
      it { expect(subject.contributor[0].person.name.completename.content).to eq "Yong-Wan Kim" }
      it { expect(subject.contributor[0].person.affiliation[0]).to be_instance_of Relaton::Bib::Affiliation }
    end

    it "parse_date" do
      expect(subject.date.size).to eq 1
      expect(subject.date[0]).to be_instance_of Relaton::Bib::Date
      expect(subject.date[0].type).to eq "published"
      expect(subject.date[0].at.to_s).to eq "2012-03-16"
    end

    it "parse_copyright" do
      expect(subject.copyright.size).to eq 1
      expect(subject.copyright[0]).to be_instance_of Relaton::Bib::Copyright
      expect(subject.copyright[0].owner[0]).to be_instance_of Relaton::Bib::ContributionInfo
      expect(subject.copyright[0].owner[0].organization.name[0].content).to eq "IOP Publishing Ltd"
    end

    it "parse_abstract" do
      expect(subject.abstract.size).to eq 1
      expect(subject.abstract[0]).to be_instance_of Relaton::Bib::Abstract
      expect(subject.abstract[0].content).to include "detector-based"
    end

    context "parse_relation" do
      it { expect(subject.relation.size).to eq 2 }
      it { expect(subject.relation[0].type).to eq "hasManifestation" }
      it { expect(subject.relation[0].bibitem.date[0].type).to eq "ppub" }
      it { expect(subject.relation[1].bibitem.date[0].type).to eq "epub" }
    end

    context "parse_series" do
      it { expect(subject.series.size).to eq 1 }
      it { expect(subject.series[0]).to be_instance_of Relaton::Bib::Series }
      it { expect(subject.series[0].title[0].content).to eq "Metrologia" }
    end

    it "parse_type" do
      expect(subject.type).to eq "article"
    end

    context "parse_source" do
      it { expect(subject.source.size).to eq 2 }
      it { expect(subject.source[0]).to be_instance_of Relaton::Bib::Uri }
      it { expect(subject.source[0].type).to eq "src" }
      it { expect(subject.source[0].content.to_s).to eq "https://doi.org/10.1088/0026-1394/49/3/273" }
      it { expect(subject.source[1]).to be_instance_of Relaton::Bib::Uri }
      it { expect(subject.source[1].type).to eq "doi" }
    end

    it "parse_ext" do
      expect(subject.ext.doctype).to be_instance_of Relaton::Bipm::Doctype
      expect(subject.ext.doctype.content).to eq "article"
    end
  end

  context "met_52_1_155" do
    let(:source) { File.read("spec/fixtures/rawdata-bipm/met_52_1_155.xml", encoding: "UTF-8") }
    subject { described_class.new(doc, "52", "1", "155").parse }

    it { expect(subject).to be_instance_of Relaton::Bipm::ItemData }
    it { expect(subject.docidentifier[0].content).to eq "Metrologia 52 1 155" }

    context "parse_affiliation" do
      it "parses affiliation without subdivision" do
        aff = subject.contributor[0].person.affiliation[0]
        expect(aff.organization.name[0].content).to eq "Bureau International des Poids et Mesures (BIPM)"
        expect(aff.organization.subdivision).to be_empty
        expect(aff.organization.address[0].formatted_address).to include "Pavillon de Breteuil"
      end
    end

    context "parse_extent" do
      it { expect(subject.extent[0]).to be_instance_of Relaton::Bib::Extent }
      it { expect(subject.extent[0].locality[0].type).to eq "volume" }
      it { expect(subject.extent[0].locality[0].reference_from).to eq "52" }
      it { expect(subject.extent[0].locality[1].type).to eq "issue" }
      it { expect(subject.extent[0].locality[1].reference_from).to eq "1" }
      it { expect(subject.extent[0].locality[2].type).to eq "page" }
      it { expect(subject.extent[0].locality[2].reference_from).to eq "155" }
      it { expect(subject.extent[0].locality[2].reference_to).to eq "162" }
    end
  end

  context "met12_2_S17" do
    let(:source) { File.read("spec/fixtures/rawdata-bipm/met12_2_S17.xml", encoding: "UTF-8") }
    subject { described_class.new(doc, "12", "2", "S17").parse }

    it { expect(subject).to be_instance_of Relaton::Bipm::ItemData }
    it { expect(subject.docidentifier[0].content).to eq "Metrologia 12 2 S17" }
    it { expect(subject.contributor.size).to eq 16 }

    it "handles organization contributor" do
      org_contrib = subject.contributor.find { |c| c.organization }
      expect(org_contrib).not_to be_nil
      expect(org_contrib.organization.name[0].content).to eq "Sentinel-3 L2 Products and Algorithm Team"
    end

    it "parses copyright with multiple owners" do
      expect(subject.copyright[0].owner.size).to eq 2
      expect(subject.copyright[0].owner[0].organization.name[0].content).to eq "BIPM"
      expect(subject.copyright[0].owner[1].organization.name[0].content).to eq "IOP Publishing Ltd"
    end
  end

  # Regression: relaton/relaton-data-bipm#38 — titles with inline markup were
  # serialised as the literal stringified Array '["text", ", ", ...]' because
  # niso-jats Title#content is a collection of text fragments around the
  # inline children. Verify the parser now reconstructs marked-up strings
  # for both titles and abstract paragraphs. Note that Relaton::Bib's
  # sanitizer renames <italic> to <em> on the way into Title/Abstract.
  context "preserves inline markup in mixed_content (issue 38)" do
    let(:source) do
      <<~XML
        <article>
          <front>
            <article-meta>
              <title-group>
                <article-title>The CODATA 2017 values of <italic>h</italic>, <italic>e</italic>, <italic>k</italic>, and <italic>N</italic><sub>A</sub> for the revision of the SI</article-title>
              </title-group>
              <abstract><p>Result: <italic>x</italic><sub>0</sub> with precision.</p></abstract>
            </article-meta>
          </front>
        </article>
      XML
    end
    let(:parser) { described_class.new(doc, "55", "1", "L13") }

    it "reconstructs the marked-up title as a String" do
      title = parser.parse_title[0]
      expect(title.content).to be_a(String)
      expect(title.content).to eq(
        "The CODATA 2017 values of <em>h</em>, <em>e</em>, <em>k</em>, " \
        "and <em>N</em><sub>A</sub> for the revision of the SI",
      )
    end

    it "keeps inline markup in abstract paragraphs" do
      expect(parser.parse_abstract[0].content).to eq(
        "<p>Result: <em>x</em><sub>0</sub> with precision.</p>",
      )
    end
  end

  describe "#format_pub_date" do
    let(:parser) { described_class.new(double("doc"), "1", "1", "1") }

    it "returns YYYY-MM-DD when full date is present" do
      pd = Niso::Jats::PubDate.new(
        year: Niso::Jats::Year.new(content: "2023"),
        month: Niso::Jats::Month.new(content: "5"),
        day: Niso::Jats::Day.new(content: "7"),
      )
      expect(parser.send(:format_pub_date, pd)).to eq "2023-05-07"
    end

    it "returns YYYY-MM when day is missing" do
      pd = Niso::Jats::PubDate.new(
        year: Niso::Jats::Year.new(content: "2023"),
        month: Niso::Jats::Month.new(content: "5"),
      )
      expect(parser.send(:format_pub_date, pd)).to eq "2023-05"
    end

    it "returns YYYY when only year is present" do
      pd = Niso::Jats::PubDate.new(year: Niso::Jats::Year.new(content: "2023"))
      expect(parser.send(:format_pub_date, pd)).to eq "2023"
    end

    it "returns nil when year is missing" do
      pd = Niso::Jats::PubDate.new(month: Niso::Jats::Month.new(content: "5"))
      expect(parser.send(:format_pub_date, pd)).to be_nil
    end

    it "round-trips as Relaton::Bib::Date for partial precision" do
      pd = Niso::Jats::PubDate.new(
        year: Niso::Jats::Year.new(content: "2023"),
        month: Niso::Jats::Month.new(content: "5"),
      )
      formatted = parser.send(:format_pub_date, pd)
      date = Relaton::Bib::Date.new(type: "ppub", at: formatted)
      expect(date.at.to_s).to eq "2023-05"
    end
  end

  describe "#division_address" do
    let(:parser) { described_class.new(double("doc"), "1", "1", "1") }

    it "returns empty strings when affiliation has no institution and no content" do
      aff = Niso::Jats::Aff.new(content: [])
      div, addr = parser.send(:division_address, aff)
      expect(div).to be_nil
      expect(addr).to eq ""
    end

    it "returns empty strings when affiliation has no institution and only whitespace content" do
      aff = Niso::Jats::Aff.new(content: ["   "])
      div, addr = parser.send(:division_address, aff)
      expect(div).to be_nil
      expect(addr).to eq ""
    end
  end

  describe "#extract_paragraph_text" do
    let(:source) do
      File.read("spec/fixtures/rawdata-bipm/met12_3_273.xml", encoding: "UTF-8")
    end
    let(:parser) { described_class.new(doc, "52", "1", "155") }
    let(:paragraph) { doc.front.article_meta.abstract.first.p.first }

    it "extracts text from mixed content with inline elements" do
      text = parser.send(:extract_paragraph_text, paragraph)
      expect(text).to include("<italic>k</italic>\u00A0=\u00A02")
    end

    it "preserves text sequence from element_order" do
      text = parser.send(:extract_paragraph_text, paragraph)
      expect(text).to match(%r{\(<italic>k</italic>\u00A0=\u00A02\)})
    end
  end
end
