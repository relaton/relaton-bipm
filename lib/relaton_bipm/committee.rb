module RelatonBipm
  class Committee
    # @return [String]
    attr_reader :acronym

    # @return [RelatonBib::LocalizedString]
    attr_reader :content

    # @param acronym [String]
    # @param content [RelatonBib::LocalisedString, nil]
    def initialize(acronym:, content: nil)
      acronyms = YAML.load_file File.join(__dir__, "acronyms.yaml")
      unless acronyms[acronym]
        warn "[relaton-bipm] WARNING: invalid acronym: #{acronym}. Allowed "\
        "values: #{acronyms.map { |k, _v| k }.join ', '}"
      end

      @acronym = acronym
      return unless acronyms[acronym]

      @content = content || RelatonBib::LocalizedString.new(
        acronyms[acronym]["en"].to_s, "en", "Latn"
      )
    end

    # @param builder [Nokogiri::XML::Builder]
    def to_xml(builder)
      builder.committee(acronym: acronym) { |b| content.to_xml b }
    end

    # @param prefix [String]
    # @param count [Integer]
    # @return [String]
    def to_asciibib(prefix, count = 1)
      pref = prefix.empty? ? prefix : prefix + "."
      pref += "committee"
      out = count > 1 ? "#{pref}::\n" : ""
      out += "#{pref}.acronym:: #{acronym}\n"
      out + content.to_asciibib(pref)
    end

    # @return [Hash]
    def to_hash
      hash = { "acronym" => acronym }
      hash.merge content.to_hash
    end
  end
end
