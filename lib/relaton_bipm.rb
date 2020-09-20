require "relaton_bib"
require "relaton_bipm/version"
require "relaton_bipm/project_team"
require "relaton_bipm/bibliographic_date"
require "relaton_bipm/document_relation"
require "relaton_bipm/comment_periond"
require "relaton_bipm/document_status"
require "relaton_bipm/bipm_bibliographic_item"
require "relaton_bipm/bipm_bibliography"
require "relaton_bipm/hash_converter"
require "relaton_bipm/xml_parser"

module RelatonBipm
  class Error < StandardError; end

  # Returns hash of XML reammar
  # @return [String]
  def self.grammar_hash
    gem_path = File.expand_path "..", __dir__
    grammars_path = File.join gem_path, "grammars", "*"
    grammars = Dir[grammars_path].sort.map { |gp| File.read gp }.join
    Digest::MD5.hexdigest grammars
  end
end
