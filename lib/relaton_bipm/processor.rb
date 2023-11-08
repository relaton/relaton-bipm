require "relaton/processor"

module RelatonBipm
  class Processor < Relaton::Processor
    attr_reader :idtype

    def initialize
      @short = :relaton_bipm
      @prefix = "BIPM"
      @defaultprefix = %r{^(?:BIPM|CCTF|CCDS|CGPM|CIPM|JCRB|JCGM)(?!\w)}
      @idtype = "BIPM"
      @datasets = %w[bipm-data-outcomes bipm-si-brochure rawdata-bipm-metrologia]
    end

    # @param code [String]
    # @param date [String, NilClass] year
    # @param opts [Hash]
    # @return [RelatonBipm::BipmBibliographicItem]
    def get(code, date, opts)
      ::RelatonBipm::BipmBibliography.get(code, date, opts)
    end

    #
    # Fetch all the documents from https://github.com/metanorma/bipm-data-outcomes,
    #   https://github.com/metanorma/bipm-si-brochure, https://github.com/relaton/rawdata-bipm-metrologia
    #
    # @param [String] source source name (bipm-data-outcomes, bipm-si-brochure,
    #   rawdata-bipm-metrologia)
    # @param [Hash] opts
    # @option opts [String] :output directory to output documents
    # @option opts [String] :format
    #
    def fetch_data(source, opts)
      DataFetcher.fetch(source, **opts)
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

    #
    # Remove index file
    #
    def remove_index_file
      Relaton::Index.find_or_create(:bipm, url: true, file: BipmBibliography::INDEX_FILE).remove_file
    end
  end
end
