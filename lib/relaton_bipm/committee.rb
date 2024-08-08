module RelatonBipm
  class Committee < RelatonBib::LocalizedString
    ACRONYMS = YAML.load_file File.join(__dir__, "acronyms.yaml")

    # @return [String]
    attr_reader :acronym

    # @return [RelatonBib::LocalizedString]
    attr_reader :content

    # @param [String] acronym
    # @param [Hash] args
    # @option args [RelatonBib::LocalisedString, String, nil] :content
    # @option args [String, nil] :language
    # @option args [String, nil] :script
    def initialize(acronym:, **args)
      unless ACRONYMS[acronym]
        Util.warn "Invalid acronym: `#{acronym}`. Allowed " \
                  "values: `#{ACRONYMS.map { |k, _v| k }.join '`, `'}`"
      end

      @acronym = acronym
      super(*localized_args(acronym, **args))
    end

    # @param builder [Nokogiri::XML::Builder]
    def to_xml(builder)
      builder.committee(acronym: acronym) { |b| super b }
    end

    # @param prefix [String]
    # @param count [Integer]
    # @return [String]
    def to_asciibib(prefix, count = 1)
      pref = prefix.empty? ? prefix : "#{prefix}."
      pref += "committee"
      out = count > 1 ? "#{pref}::\n" : ""
      out += "#{pref}.acronym:: #{acronym}\n"
      out + super(pref)
    end

    # @return [Hash]
    def to_hash
      hash = { "acronym" => acronym }
      cnt = super
      case cnt
      when Array then hash["variants"] = cnt
      when Hash then hash.merge! cnt
      else hash["content"] = cnt
      end
      hash
    end

    private

    def localized_args(accronym, **args)
      if args[:content].is_a? String
        [args[:content], args[:language], args[:script]]
      elsif args[:content].nil?
        lang = args[:language] || ACRONYMS.dig(acronym, "en") ? "en" : ACRONYMS[acronym]&.keys&.first
        script = args[:script] || lang == "en" ? "Latn" : nil
        [ACRONYMS.dig(accronym, lang), lang, script]
      else [args[:content]]
      end
    end
  end
end
