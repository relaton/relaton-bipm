module RelatonBipm
  class ProjectTeam
    COMMITTEES = %w[cgpm cipm bipm ccauv ccem ccl ccm ccpr ccqm ccri cct cctf
                    ccu ccl-cctfwg jcgm jcrb jctlm inetqi].freeze

    # @return [String]
    attr_reader :committee

    # @return [RelatonBib::FormattedString]
    attr_reader :workgroup

    # @param committee [String]
    # @param workgroup [RelatonBib::FormattedString]
    def initialize(committee:, workgroup:)
      unless COMMITTEES.include? committee
        warn "[relaton-bipm] Warning: invalid committee: #{committee}. "\
        "It should be one of: #{COMMITTEES}"
      end
      @committee = committee
      @workgroup = workgroup
    end

    # @param builder [Nokogiri::XML::Builder]
    def to_xml(builder)
      builder.send "project-group" do |b|
        b.committee committee
        b.workgroup { workgroup.to_xml b }
      end
    end

    # @return [Hash]
    def to_hash
      { "committee" => committee, "workgroup" => workgroup.to_hash }
    end

    # @param prefix [String]
    # 2param count [Integer]
    # @return [String]
    def to_asciibib(prefix = "", count = 1)
      pref = prefix.empty? ? prefix : prefix + "."
      pref += "project_group"
      out = count > 1 ? "#{pref}::\n" : ""
      out += "#{pref}.committee:: #{committee}\n"
      out += workgroup.to_asciibib prefix
      out
    end
  end
end
