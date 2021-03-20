require "relaton/processor"

module RelatonBipm
  class Processor < Relaton::Processor
    attr_reader :idtype

    def initialize
      @short = :relaton_bipm
      @prefix = "BIPM"
      @defaultprefix = %r{^BIPM\s}
      @idtype = "BIPM"
    end

    # @param code [String]
    # @param date [String, NilClass] year
    # @param opts [Hash]
    # @return [RelatonBipm::BipmBibliographicItem]
    def get(code, date, opts)
      ::RelatonBipm::BipmBibliography.get(code, date, opts)
    end

    # @param xml [String]
    # @return [RelatonBipm::BipmBibliographicItem]
    def from_xml(xml)
      ::RelatonBipm::XMLParser.from_xml xml
    end

    # @param hash [Hash]
    # @return [RelatonBipm::BipmBibliographicItem]
    def hash_to_bib(hash)
      ::RelatonBipm::BipmBibliographicItem.from_hash hash
    end

    # Returns hash of XML grammar
    # @return [String]
    def grammar_hash
      @grammar_hash ||= ::RelatonBipm.grammar_hash
    end
  end
end
