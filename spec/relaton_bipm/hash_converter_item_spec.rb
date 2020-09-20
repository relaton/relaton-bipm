RSpec.describe RelatonBipm::HashConverter do
  it "create BipmBibliographicItem from Hash" do
    hash = YAML.load_file "spec/fixtures/bipm_item.yml"
    bib = RelatonBipm::HashConverter.hash_to_bib hash
    item = RelatonBipm::BipmBibliographicItem.new bib
    xml = item.to_xml bibdata: true
    file = "spec/fixtures/bipm_item.xml"
    File.write file, xml, encoding: "UTF-8" unless File.exist? file
    expect(xml).to be_equivalent_to File.read file, encoding: "UTF-8"
  end
end
