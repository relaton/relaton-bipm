# encoding: UTF-8

describe RelatonBipm::RawdataBipmMetrologia::Affiliations do
  subject { described_class.parse("rawdata-bipm-metrologia") }

  context "parse affiliations" do
    before do
      expect(Dir).to receive(:[]).with("rawdata-bipm-metrologia/*.xml").and_return(["spec/fixtures/met12_3_273.xml"])
    end

    it do
      expect(subject.affiliations).to be_instance_of Array
      expect(subject.affiliations.size).to eq 2
      expect(subject.affiliations.first).to be_instance_of RelatonBib::Affiliation
    end
  end

  context "parse affiliation" do
    it "with institution & subdivision" do
      aff = Nokogiri::XML(<<~XML).at("aff")
        <aff id="affiliation01">
          <label>1</label>
Division of Physical Metrology, <institution xlink:type="simple">Korea Research Institute of Standards and Science</institution>, 267 Gajeong-ro, Yuseong-gu, Daejeon 305-340, <country>Republic of Korea</country>
        </aff>
      XML
      affiliation = described_class.parse_affiliation aff
      expect(affiliation).to be_instance_of RelatonBib::Affiliation
      expect(affiliation.organization).to be_instance_of RelatonBib::Organization
      expect(affiliation.organization.name.first.content).to eq "Korea Research Institute of Standards and Science"
      expect(affiliation.organization.subdivision.first.content).to eq "Division of Physical Metrology"
      expect(affiliation.organization.contact.first.formatted_address).to eq(
        "267 Gajeong-ro, Yuseong-gu, Daejeon 305-340, Republic of Korea"
      )
    end

    it "with institution only" do
      aff = Nokogiri::XML(<<~XML).at("aff")
        <aff id="affiliation01">
          <label>1</label>
          <institution xlink:type="simple">Bureau International des Poids et Mesures (BIPM)</institution>, Pavillon de Breteuil, 92312 CEDEX, Sèvres, <country>France</country>
        </aff>
      XML
      affiliation = described_class.parse_affiliation aff
      expect(affiliation).to be_instance_of RelatonBib::Affiliation
      expect(affiliation.organization).to be_instance_of RelatonBib::Organization
      expect(affiliation.organization.name.first.content).to eq "Bureau International des Poids et Mesures (BIPM)"
      expect(affiliation.organization.subdivision).to be_empty
      expect(affiliation.organization.contact.first.formatted_address).to eq(
        "Pavillon de Breteuil, 92312 CEDEX, S\u00E8vres, France"
      )
    end

    it "without institution" do
      aff = Nokogiri::XML(<<~XML).at("aff")
        <aff id="aff1">
          <label>1</label>Division of Applied Physics, National Research Council, Ottawa, Canada</aff>
      XML
      affiliation = described_class.parse_affiliation aff
      expect(affiliation).to be_instance_of RelatonBib::Affiliation
      expect(affiliation.organization).to be_instance_of RelatonBib::Organization
      expect(affiliation.organization.name.first.content).to eq "National Research Council"
      expect(affiliation.organization.subdivision.first.content).to eq "Division of Applied Physics"
      expect(affiliation.organization.contact.first.city).to eq "Ottawa"
      expect(affiliation.organization.contact.first.country).to eq "Canada"
    end

    it "name only" do
      aff = Nokogiri::XML(<<~XML).at("aff")
        <aff id="aff1">
          <label>1</label>University of Cambridge</aff>
      XML
      affiliation = described_class.parse_affiliation aff
      expect(affiliation).to be_instance_of RelatonBib::Affiliation
      expect(affiliation.organization).to be_instance_of RelatonBib::Organization
      expect(affiliation.organization.name.first.content).to eq "University of Cambridge"
      expect(affiliation.organization.subdivision).to be_empty
    end
  end
end
