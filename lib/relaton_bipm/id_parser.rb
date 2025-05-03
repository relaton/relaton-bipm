module RelatonBipm
  class Id
    # class Parser < Parslet::Parser
    #   rule(:space) { match("\s").repeat(1) }
    #   rule(:space?) { space.maybe }
    #   rule(:comma) { str(",") >> space? }
    #   rule(:lparen) { str("(") }
    #   rule(:rparen) { str(")") }
    #   rule(:slash) { str("/") }
    #   rule(:num) { match["0-9"].repeat(1) }

    #   rule(:delimeter) { str("--") >> space }
    #   rule(:delimeter?) { delimeter.maybe }

    #   rule(:lang) { comma >> space? >> match["A-Z"].repeat(1, 2).as(:lang) }
    #   rule(:lang?) { lang.maybe }

    #   rule(:numdash) { match["A-Z0-9-"].repeat(1).as(:number) }
    #   rule(:number) { numdash >> space? }
    #   rule(:number?) { number.maybe }
    #   rule(:num_suff) { numdash >> match["a-z"].repeat(1, 2) >> space }

    #   rule(:year) { match["0-9"].repeat(4, 4).as(:year) }
    #   rule(:year_paren) { lparen >> year >> lang? >> rparen }
    #   rule(:num_year) { number? >> year_paren }
    #   rule(:year_num) { year >> str("-") >> number }
    #   rule(:num_and_year) { num_year | year_num | number }

    #   rule(:sect) { lparen >> match["IVX"].repeat >> rparen }
    #   rule(:suff) { match["a-zA-Z-"].repeat(1) }
    #   rule(:cgmp) { str("CGPM") }
    #   rule(:cipm) { str("CIPM") >> (str(" MRA") | match["A-Z-"]).maybe }
    #   rule(:cc) { str("CC") >> suff >> sect.maybe }
    #   rule(:jc) { str("JC") >> suff }
    #   rule(:cec) { str("CEC") }
    #   rule(:wgms) { str("WG-MS") }
    #   rule(:group) { (cgmp | cipm | cc | jc | cec | wgms).as(:group) }

    #   rule(:type) { match["[:alpha:]"].repeat(1).as(:type) >> space }

    #   rule(:type_group) { type >> group >> slash >> num_and_year }
    #   rule(:group_type) { group >> space >> delimeter? >> type >> num_and_year }
    #   rule(:group_num) { group >> space >> num_suff >> type >> year_paren }
    #   rule(:outcome) { group_num | group_type | type_group }

    #   rule(:part_partie) { str("Part") | str("Partie") }
    #   rule(:part) { comma >> part_partie >> space >> num.as(:part) }
    #   rule(:append) { (comma | space) >> (str("Appendix") | str("Annexe")) >> space >> num.as(:append) }
    #   rule(:brochure) { str("SI").as(:group) >> space >> str("Brochure").as(:type) >> (part | append).maybe }

    #   rule(:metrologia) { str("Metrologia").as(:group) >> (space >> match["a-zA-Z0-9\s"].repeat(1).as(:number)).maybe }

    #   rule(:corr) { space >> str("Corrigendum").as(:corr) }
    #   rule(:corr?) { corr.maybe }
    #   rule(:jcgm) { group >> space >> numdash >> (str(":") >> year).maybe >> corr? }

    #   rule(:result) { outcome | brochure | metrologia | jcgm }

    #   root :result
    # end

    TYPES = {
      "Resolution" => "RES",
      "Résolution" => "RES",
      "Recommendation" => "REC",
      "Recommandation" => "REC",
      "Decision" => "DECN",
      "Décision" => "DECN",
      "Declaration" => "DECL",
      "Déclaration" => "DECL",
      "Réunion" => "Meeting",
      "Action" => "ACT",
    }.freeze

    # @return [Hash] the parsed id components
    attr_accessor :id

    #
    # Create a new Id object
    #
    def initialize
      # @id = Parser.new.parse(id)
      # @id = parse(id)
    # rescue Parslet::ParseFailed => e
      # Util.warn "WARNING: Incorrect reference: `#{id}`"
      # warn e.parse_failure_cause.ascii_tree
      # raise RelatonBib::RequestError, e
    end

    # @param [String] id id string
    #
    def parse(id)
      # str = StringScanner.new id
      match = parse_outcome(id) || parse_brochure(id) || parse_metrologia(id) || parse_jcgm(id)
      @id = match.named_captures.compact.transform_keys(&:to_sym)
      self
    rescue StandardError => e
      Util.warn "Incorrect reference: `#{id}`"
      raise RelatonBib::RequestError, e
    end

    def parse_outcome(id)
      parse_group_num(id) || parse_group_type(id) || parse_type_group(id)
    end

    def parse_group_num(id)
      %r{^#{group}\s#{number}[a-z]{1,2}\s#{type}\s#{year_lang}$}.match(id)
    end

    def parse_group_type(id)
      %r{^#{group}\s(?:--\s)?#{type}\s#{num_and_year}$}.match(id)
    end

    def parse_type_group(id)
      %r{^#{type}\s#{group}\/#{num_and_year}$}.match(id)
    end

    def group
      "(?<group>CGPM|CIPM(?:\\sMRA|[A-Z-])?|CC[a-zA-Z-]+[IVX]*|JC[a-zA-Z-]+|CEC|WG-MS)"
    end

    def type; "(?<type>[[:alpha:]]+)"; end
    def number; "(?<number>[A-Z0-9-]+)"; end
    def year; "(?<year>\\d{4})"; end
    def lang; ",\\s?(?<lang>[A-Z]{1,2})"; end
    def year_lang; "\\(#{year}(?:#{lang})?\\)"; end
    def num_and_year; "(?:(?:#{number}\\s)?#{year_lang}|#{year}-#{number}|#{number})"; end

    def parse_brochure(id)
      parse_si_brochure(id) || parse_brochure_other(id)
    end

    def parse_si_brochure(id)
      %r{^
        (?<group>SI)\s(?<type>Brochure)
        (?:,?\s(?:(?:Part|Partie)\s(?<part>\d+)|(?:Appendix|Annexe)\s(?<append>\d+)|(?<number>Concise|FAQ)))?
      $}x.match(id)
    end

    def parse_brochure_other(id)
      %r{^(?<group>CCEM|CCL|CCM|SI|Rapport)[-\s](?<type>GD-RSI|GD-MeP|MEP|BIPM)[-\s](?<number>\w+|\d{4}\/\d{2})$}.match(id)
    end

    def parse_metrologia(id)
      %r{^(?<group>Metrologia)(?:\s(?<number>[a-zA-Z0-9\s]+))?$}.match(id)
    end

    def parse_jcgm(id)
      %r{^#{group}\s#{number}(?::#{year})?(?:\s(?<corr>Corrigendum))?$}.match(id)
    end

    # def parse_gorup_num(str)
    #   return unless group = parse_group(str)

    #   return unless str.scan(" ") && num_suff = parse_num_suff(str)

    #   return unless type = parse_type(str)

    #   return unless year = parse_year_parent(str)

    #   { group: group, number: num_suff, type: type, year: year }
    # end

    # def parse_group(str)
    #   str.scan %r{CGPM|CIPM(?:\sMRA|[A-Z-])?|CC[a-zA-Z-]+[IVX]*|JC[a-zA-Z-]|CEC|WG-MS}
    # end

    # def parse_num_suff(str)
    #   num = parse_numdash(str)
    #   num if num && str.scan(/[a-z]{1,2}\s/)
    # end

    # def parse_number(str)
    #   parse_numdash(str)
    # end

    # def parse_numdash(str)
    #   str.scan(/[A-Z0-9-]+/)
    # end

    #
    # Compare two Id objects
    #
    # @param [RelatonBipm::Id, Hash] other the other Id object
    #
    # @return [Boolean] true if the two Id objects are equal
    #
    def ==(other) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/AbcSize
      other_hash = other.is_a?(Id) ? other.to_hash : normalize_hash(other)
      hash = to_hash.dup
      hash.delete(:number) if other_hash[:number].nil? && hash[:number] == "1" && hash[:year]
      other_hash.delete(:number) if hash[:number].nil? && other_hash[:number] == "1" && other_hash[:year]
      # hash.delete(:year) unless other_hash[:year]
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
    def to_hash
      @to_hash ||= normalize_hash id
    end

    #
    # Normalize ID parts
    # Traslate type into abbreviation, remove leading zeros from number
    #
    # @param [RelatonBipm::Id, Hash] src the ID parts
    #
    # @return [Hash] the normalized ID parts
    #
    def normalize_hash(src) # rubocop:disable Metrics/AbcSize
      hash = { group: src[:group].to_s.sub("CCDS", "CCTF") }
      hash[:type] = normalized_type(src) if src[:type]
      norm_num = normalized_number(src)
      hash[:number] = norm_num unless norm_num.nil? || norm_num.empty?
      hash[:year] = src[:year].to_s if src[:year]
      hash[:corr] = true if src[:corr]
      hash[:part] = src[:part].to_s if src[:part]
      hash[:append] = src[:append].to_s if src[:append]
      hash[:lang] = src[:lang].to_s if src[:lang]
      hash
    end

    #
    # Translate type into abbreviation
    #
    # @return [String] the normalized type
    #
    def normalized_type(src)
      type = TYPES[src[:type].to_s.capitalize] || src[:type].to_s
      type == type.upcase ? type : type.capitalize
    end

    #
    # Remove leading zeros from number
    #
    # @return [String, nil] the normalized number
    #
    def normalized_number(src)
      return unless src[:number]

      src[:number].to_s.sub(/^0+/, "")
    end
  end
end
