module RelatonBipm
  class EditorialGroup
    include RelatonBib

    COMMITTEES = %w[CGPM CIPM BIPM CCAUV CCEM CCL CCM CCPR CCQM CCRI CCT CCTF
                    CCU CCL-CCT JCGM JCRB JCTLM INetQI].freeze

    # @return [Array<String>]
    attr_reader :committee, :workgroup

    # @param committee [Array<String>]
    # @param workgroup [Array<String>]
    def initialize(committee:, workgroup:)
      committee.each do |c|
        unless COMMITTEES.include? c
          warn "[relaton-bipm] invalid committee: #{c}"
        end
      end

      @committee = committee
      @workgroup = workgroup
    end

    # @param builder [Nokogiri::XML::Builder]
    def to_xml(builder)
      builder.editorialgroup do |b|
        committee.each { |c| b.committee c }
        workgroup.each { |c| b.workgroup c }
      end
    end

    # @param prefix [String]
    # @return [String]
    def to_asciibib(prefix = "")
      pref = prefix.empty? ? prefix : prefix + "."
      pref += "editorialgroup"
      out = ""
      committee.each { |c| out += "#{pref}.committee:: #{c}\n" }
      workgroup.each { |w| out += "#{pref}.workgroup:: #{w}\n" }
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
