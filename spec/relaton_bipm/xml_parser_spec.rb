RSpec.describe RelatonBipm::XMLParser do
  it "create item from XML" do
    xml = File.read "spec/fixtures/bipm_item.xml", encoding: "UTF-8"
    item = RelatonBipm::XMLParser.from_xml xml
    expect(item.to_xml(bibdata: true)).to be_equivalent_to xml
  end

  it "create_doctype" do
    elm = Nokogiri::XML('<doctype abbreviation="BR">brochure</doctype>').root
    dt = RelatonBipm::XMLParser.send :create_doctype, elm
    expect(dt).to be_instance_of RelatonBipm::DocumentType
    expect(dt.abbreviation).to eq "BR"
    expect(dt.type).to eq "brochure"
  end
end
