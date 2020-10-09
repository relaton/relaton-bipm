module RelatonBipm
  class StructuredIdentifier
    # @return [String]
    attr_reader :docnumber

    # @return [String, nil]
    attr_reader :part, :appendix

    # @param docnumber [String]
    # @param part [String]
    # @param appendix [String]
    def initialize(docnumber:, part: nil, appendix: nil)
      @docnumber = docnumber
      @part = part
      @appendix = appendix
    end

    # @param builder [Nokogiri::XML::Builder]
    def to_xml(builder)
      builder.structuredidentifier do |b|
        b.docnumber docnumber
        b.part part if part
        b.appendix appendix if appendix
      end
    end

    # @return [Hash]
    def to_hash
      hash = { "docnumber" => docnumber }
      hash["part"] = part if part
      hash["appendix"] = appendix if appendix
      hash
    end

    # @param prefix [String]
    # @return [String]
    def to_asciibib(prefix = "")
      pref = prefix.empty? ? prefix : prefix + "."
      pref += "structuredidentifier"
      out = "#{pref}.docnumber:: #{docnumber}\n"
      out += "#{pref}.part:: #{part}\n" if part
      out += "#{pref}.appendix:: #{appendix}\n" if appendix
      out
    end

    # @return [true]
    def presence?
      true
    end
  end
end
