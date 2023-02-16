module RelatonBipm
  class CommentPeriond
    # @return [Date]
    attr_reader :from

    # @return [Date, NilClass]
    attr_reader :to

    # @param from [String] date
    # @parma to [String, NilClass] date
    def initialize(from:, to: nil)
      @from = Date.parse from
      @to = Date.parse to if to
    end

    # @param builder [Nokogiri::XML::builder]
    def to_xml(builder)
      builder.send :"comment-period" do
        builder.from from.to_s
        builder.to to.to_s if to
      end
    end

    # @return [Hash]
    def to_hash
      hash = { "from" => from.to_s }
      hash["to"] = to.to_s if to
      hash
    end

    # @param prefix [String]
    # @return [String]
    def to_asciibib(prefix)
      pref = prefix.empty? ? prefix : "#{prefix}."
      pref += "commentperiod"
      out = "#{pref}.from:: #{from}\n"
      out += "#{pref}.to:: #{to}\n" if to
      out
    end
  end
end
