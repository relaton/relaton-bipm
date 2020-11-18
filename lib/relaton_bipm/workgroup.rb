module RelatonBipm
  class WorkGroup
    # @return [String]
    attr_reader :content

    # @return [String, nil]
    attr_reader :acronym

    # @param content [String]
    # @param acronym [String, nil]
    def initialize(content:, acronym: nil)
      @content = content
      @acronym = acronym
    end

    # @param builder [Nokogiri::XML::Builder]
    def to_xml(builder)
      xml = builder.workgroup content
      xml[:acronym] = acronym if acronym
    end

    # @param prefix [String]
    # @param count [Integer]
    # @return [String]
    def to_asciibib(prefix, count = 1)
      pref = prefix.empty? ? prefix : prefix + "."
      pref += "workgroup"
      if acronym
        out = count > 1 ? "#{pref}::\n" : ""
        out += "#{pref}.acronym:: #{acronym}\n"
        out + "#{pref}.content:: #{content}\n"
      else "#{pref}:: #{content}\n"
      end
    end

    # @return [Hash, String]
    def to_hash
      if acronym
        hash = { "content" => content }
        hash["acronym"] = acronym
        hash
      else content
      end
    end
  end
end
