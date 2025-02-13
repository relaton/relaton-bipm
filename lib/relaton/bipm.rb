require "zip"
require "fileutils"
require "parslet"
require "relaton/bib"
require "relaton/index"
require_relative "bipm/util"
require_relative "bipm/item"
require_relative "bipm/bibitem"
require_relative "bipm/bibdata"

module Relaton
  module Bipm
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
end
