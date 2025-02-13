describe Relaton::Bipm::Item do
  let(:input_yaml) { File.read "spec/fixtures/item.yaml" }
  let(:item) { described_class.from_yaml input_yaml }

  it "round trip" do
    input_hash = YAML.safe_load input_yaml
    output_yaml = described_class.to_yaml item
    output_hash = YAML.safe_load output_yaml
    expect(output_hash).to eq input_hash
  end
end
