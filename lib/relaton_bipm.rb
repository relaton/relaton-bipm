require "zip"
require "fileutils"
require "relaton_bib"
require "relaton_bipm/version"
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
require "relaton_bipm/index"

module RelatonBipm
  class Error < StandardError; end

  # Returns hash of XML reammar
  # @return [String]
  def grammar_hash
    gem_path = File.expand_path "..", __dir__
    grammars_path = File.join gem_path, "grammars", "*"
    grammars = Dir[grammars_path].sort.map { |gp| File.read gp }.join
    Digest::MD5.hexdigest grammars
  end

  #
  # Parse yaml content
  #
  # @param [String] yaml content
  #
  # @return [Hash] data
  #
  def parse_yaml(yaml, classes = [])
    # Newer versions of Psych uses the `permitted_classes:` parameter
    if YAML.method(:safe_load).parameters.map(&:last).include? :permitted_classes
      YAML.safe_load(yaml, permitted_classes: classes)
    else
      YAML.safe_load(yaml, classes)
    end
  end

  extend self
end
