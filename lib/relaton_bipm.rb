require "zip"
require "fileutils"
require "parslet"
require "relaton_bib"
require "relaton/index"
require "relaton_bipm/util"
require "relaton_bipm/id_parser"
require "relaton_bipm/version"
require "relaton_bipm/document_type"
require "relaton_bipm/editorial_group"
require "relaton_bipm/committee"
require "relaton_bipm/workgroup"
require "relaton_bipm/structured_identifier"
require "relaton_bipm/bibliographic_date"
require "relaton_bipm/document_relation"
require "relaton_bipm/comment_periond"
require "relaton_bipm/bipm_bibliographic_item"
require "relaton_bipm/bipm_bibliography"
require "relaton_bipm/hash_converter"
require "relaton_bipm/xml_parser"
require "relaton_bipm/data_fetcher"
require "relaton_bipm/data_outcomes_parser"
require "relaton_bipm/bipm_si_brochure_parser"
require "relaton_bipm/rawdata_bipm_metrologia/fetcher"
require "relaton_bipm/rawdata_bipm_metrologia/article_parser"

module RelatonBipm
  class Error < StandardError; end

  # Returns hash of gems versions used to generate the data model.
  # @return [String]
  def grammar_hash
    # gem_path = File.expand_path "..", __dir__
    # grammars_path = File.join gem_path, "grammars", "*"
    # grammars = Dir[grammars_path].sort.map { |gp| File.read gp }.join
    Digest::MD5.hexdigest RelatonBipm::VERSION + RelatonBib::VERSION # grammars
  end

  extend self
end
