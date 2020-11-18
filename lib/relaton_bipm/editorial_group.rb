module RelatonBipm
  class EditorialGroup
    include RelatonBib

    # @return [Array<String>]
    attr_reader :committee, :workgroup

    # @param committee [Array<RelatonBipm::Committee>]
    # @param workgroup [Array<RelatonBipm::WorkGroup>]
    def initialize(committee:, workgroup: [])
      @committee = committee
      @workgroup = workgroup
    end

    # @param builder [Nokogiri::XML::Builder]
    def to_xml(builder)
      builder.editorialgroup do |b|
        committee.each { |c| c.to_xml b }
        workgroup.each { |c| c.to_xml b }
      end
    end

    # @param prefix [String]
    # @return [String]
    def to_asciibib(prefix = "") # rubocop:disable Metrics/AbcSize
      pref = prefix.empty? ? prefix : prefix + "."
      pref += "editorialgroup"
      out = ""
      committee.each { |c| out += c.to_asciibib pref, committee.size }
      workgroup.each { |w| out += w.to_asciibib pref, workgroup.size }
      out
    end

    # @return [Hash]
    def to_hash
      {
        "committee" => single_element_array(committee),
        "workgroup" => single_element_array(workgroup),
      }
    end

    # @return [true]
    def presence?
      true
    end
  end
end
