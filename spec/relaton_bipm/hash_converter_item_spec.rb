RSpec.describe RelatonBipm::HashConverter do
  it "create BipmBibliographicItem from Hash" do
    hash = YAML.load_file "spec/fixtures/bipm_item.yml"
    item = RelatonBipm::BipmBibliographicItem.from_hash hash
    xml = item.to_xml bibdata: true
    file = "spec/fixtures/bipm_item.xml"
    File.write file, xml, encoding: "UTF-8" unless File.exist? file
    expect(xml).to be_equivalent_to File.read file, encoding: "UTF-8"
  end
end
