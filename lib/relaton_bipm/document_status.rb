# frozen_string_literal: true

module RelatonBipm
  # Document status.
  class DocumentStatus
    # @return [String]
    attr_reader :status

    # @param status [String]
    def initialize(status)
      @status = status
    end

    # @param [Nokogiri::XML::Builder]
    def to_xml(builder)
      builder.status status
    end

    # @return [String]
    def to_hash
      status
    end

    # @param prefix [String]
    # @return [String]
    def to_asciibib(prefix = "")
      pref = prefix.empty? ? prefix : prefix + "."
      "#{pref}docstatus:: #{status}\n"
    end
  end
end
