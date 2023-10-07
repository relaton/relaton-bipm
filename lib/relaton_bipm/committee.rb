module RelatonBipm
  class Committee
    # @return [String]
    attr_reader :acronym

    # @return [RelatonBib::LocalizedString]
    attr_reader :content

    # @param acronym [String]
    # @param content [RelatonBib::LocalisedString, String, nil]
    def initialize(acronym:, content: nil)
      acronyms = YAML.load_file File.join(__dir__, "acronyms.yaml")
      unless acronyms[acronym]
        Util.warn "WARNING: Invalid acronym: `#{acronym}`. Allowed " \
                  "values: `#{acronyms.map { |k, _v| k }.join '`, `'}`"
      end

      @acronym = acronym
      @content = localized_content content, acronyms[acronym]
    end

    # @param builder [Nokogiri::XML::Builder]
    def to_xml(builder)
      builder.committee(acronym: acronym) { |b| content.to_xml b }
    end

    # @param prefix [String]
    # @param count [Integer]
    # @return [String]
    def to_asciibib(prefix, count = 1)
      pref = prefix.empty? ? prefix : "#{prefix}."
      pref += "committee"
      out = count > 1 ? "#{pref}::\n" : ""
      out += "#{pref}.acronym:: #{acronym}\n"
      out + content.to_asciibib(pref)
    end

    # @return [Hash]
    def to_hash
      hash = { "acronym" => acronym }
      cnt = content.to_hash
      case cnt
      when Array then hash["variants"] = cnt
      when Hash then hash.merge! cnt
      else hash["content"] = cnt
      end
      hash
    end

    private

    def localized_content(cnt, acr)
      if cnt.is_a? String
        RelatonBib::LocalizedString.new cnt
      elsif (cnt.nil? || cnt.empty?) && acr && acr["en"]
        RelatonBib::LocalizedString.new(acr["en"], "en", "Latn")
      else cnt
      end
    end
  end
end
