describe RelatonBipm::RawdataBipmMetrologia::NisoJatsParser do
  # let(:doc) { Nokogiri::XML(File.read("spec/fixtures/met12_3_273.xml", encoding: "UTF-8")) }
  # subject { described_class.new doc, "12", "3", "273" }

  it "call parser method" do
    path = "rawdata-bipm-metrologia//data/2022-04-05T10_55_52_content/0026-1394/0026-1394_55/0026-1394_55_1/0026-1394_55_1_L13/met_55_1_L13.xml"
    expect(File).to receive(:read).with(path, encoding: "UTF-8").and_return :xml
    expect(Niso::Jats::Article).to receive(:from_xml).with(:xml).and_return :doc
    parser = double "parser"
    expect(parser).to receive(:parse)
    expect(described_class).to receive(:new).with(:doc, "55", "1", "L13").and_return parser
    described_class.parse path
  end

  let(:doc) { Niso::Jats::Article.from_xml source }
  subject { described_class.new(doc, "52", "1", "155").parse }

  shared_examples "parse" do |file_name|
    let(:source) { File.read("spec/fixtures/rawdata-bipm/#{file_name}.xml", encoding: "UTF-8") }

    it do
      xml = subject.to_xml bibdata: true
      file = "spec/fixtures/#{file_name}.xml"
      File.write file, xml, encoding: "UTF-8" unless File.exist? file
      expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
    end
  end

  it_behaves_like "parse", "met_52_1_155"
  it_behaves_like "parse", "met12_3_273"
  it_behaves_like "parse", "met12_2_S17"
end
