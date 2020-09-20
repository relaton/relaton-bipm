RSpec.describe RelatonBipm::XMLParser do
  it "create item from XML" do
    xml = File.read "spec/fixtures/bipm_item.xml", encoding: "UTF-8"
    item = RelatonBipm::XMLParser.from_xml xml
    expect(item.to_xml(bibdata: true)).to be_equivalent_to xml
  end
end
