describe Relaton::Bipm::Bibdata do
  let(:file) { "spec/fixtures/bibdata.xml" }
  let(:input_xml) { File.read file, encoding: "UTF-8" }
  let(:item) { described_class.from_xml input_xml }

  it "round trip" do
    output_xml = described_class.to_xml item
    expect(output_xml).to be_equivalent_to input_xml
    schema = Jing.new "grammars/relaton-bipm-compile.rng"
    errors = schema.validate file
    expect(errors).to eq []
  end
end
