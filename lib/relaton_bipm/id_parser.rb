module RelatonBipm
  class Id
    class Parser < Parslet::Parser
      rule(:space) { match("\s").repeat(1) }
      rule(:space?) { space.maybe }
      rule(:comma) { str(",") >> space? }
      rule(:lparen) { str("(") }
      rule(:rparen) { str(")") }
      rule(:slash) { str("/") }

      rule(:delimeter) { str("--") >> space }
      rule(:delimeter?) { delimeter.maybe }

      rule(:lang) { comma >> match["A-Z"].repeat(2, 2).as(:lang) }
      rule(:lang?) { lang.maybe }

      rule(:number) { match["0-9-"].repeat(1).as(:number) >> space? }
      rule(:number?) { number.maybe }

      rule(:year) { match["0-9"].repeat(4, 4).as(:year) }
      rule(:year_paren) { lparen >> year >> lang? >> rparen }
      rule(:num_year) { number? >> year_paren }
      rule(:year_num) { year >> str("-") >> number }
      rule(:num_and_year) { num_year | year_num | number }

      rule(:sect) { lparen >> match["IVX"].repeat >> rparen }
      rule(:suff) { match["a-zA-Z-"].repeat(1) }
      rule(:cgmp) { str("CGPM") }
      rule(:cipm) { str("CIPM") >> (str(" MRA") | match["A-Z-"]).maybe }
      rule(:cc) { str("CC") >> suff >> sect.maybe }
      rule(:jc) { str("JC") >> suff }
      rule(:cec) { str("CEC") }
      rule(:wgms) { str("WG-MS") }
      rule(:group) { (cgmp | cipm | cc | jc | cec | wgms).as(:group) }

      rule(:type) { match["[:alpha:]"].repeat(1).as(:type) >> space }

      rule(:type_group) { type >> group >> slash >> num_and_year }
      rule(:group_type) { group >> space >> delimeter? >> type >> num_and_year }
      rule(:outcome) { group_type | type_group }

      rule(:append) { comma >> str("Appendix") >> space >> number }
      rule(:brochure) { str("SI").as(:group) >> space >> str("Brochure").as(:type) >> append.maybe }

      rule(:metrologia) { str("Metrologia").as(:group) >> (space >> match["a-zA-Z0-9\s"].repeat(1).as(:number)).maybe }

      rule(:result) { outcome | brochure | metrologia }

      root :result
    end

    TYPES = {
      "Resolution" => "RES",
      "Résolution" => "RES",
      "Recommendation" => "REC",
      "Recommandation" => "REC",
      "Decision" => "DECN",
      "Décision" => "DECN",
      "Declaration" => "Déclaration",
      "Réunion" => "Meeting",
    }.freeze

    # @return [Hash] the parsed id components
    attr_accessor :id

    #
    # Create a new Id object
    #
    # @param [String] id id string
    #
    def initialize(id)
      @id = Parser.new.parse(id)
    rescue Parslet::ParseFailed => e
      warn "[relaton-bipm] Incorrect reference: #{id}"
      # warn "[relaton-bipm] #{e.parse_failure_cause.ascii_tree}"
      raise RelatonBib::RequestError, e
    end

    #
    # Compare two Id objects
    #
    # @param [RelatonBipm::Id, Hash] other the other Id object
    #
    # @return [Boolean] true if the two Id objects are equal
    #
    def ==(other)
      other_hash = other.is_a?(Id) ? other.normalized_hash : other
      hash = normalized_hash
      hash.delete(:year) unless other_hash[:year]
      other_hash.delete(:year) unless hash[:year]
      hash.delete(:lang) unless other_hash[:lang]
      other_hash.delete(:lang) unless hash[:lang]
      hash == other_hash
    end

    #
    # Transform ID parts.
    # Traslate type into abbreviation, remove leading zeros from number
    #
    # @return [Hash] the normalized ID parts
    #
    def normalized_hash # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      @normalized_hash ||= begin
        hash = { group: id[:group].to_s.sub("CCDS", "CCTF") }
        hash[:type] = normalized_type if id[:type]
        norm_num = normalized_number
        hash[:number] = norm_num unless norm_num.nil? || norm_num.empty?
        hash[:year] = id[:year].to_s if id[:year]
        hash[:lang] = id[:lang].to_s if id[:lang]
        hash
      end
    end

    #
    # Translate type into abbreviation
    #
    # @return [String] the normalized type
    #
    def normalized_type
      TYPES[id[:type].to_s] || id[:type].to_s
    end

    #
    # Remove leading zeros from number
    #
    # @return [String, nil] the normalized number
    #
    def normalized_number
      return unless id[:number]

      id[:number].to_s.sub(/^0+/, "")
    end
  end
end
