module RelatonBipm
  class BipmSiBrochureParser
    #
    # Create new parser
    #
    # @param [RelatonBipm::DataFetcher] data_fetcher data fetcher
    #
    def initialize(data_fetcher)
      @data_fetcher = WeakRef.new data_fetcher
    end

    #
    # Parse documents from SI brochure dataset and write thems to YAML files
    #
    # @param [RelatonBipm::DataFetcher] data_fetcher data fetcher
    #
    def self.parse(data_fetcher)
      new(data_fetcher).parse
    end

    #
    # Parse SI brochure and write them to YAML files
    #
    def parse # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      # puts "Parsing SI brochure..."
      # puts "Ls #{Dir['*']}"
      # puts "Ls #{Dir['bipm-si-brochure/*']}"
      # puts "Ls #{Dir['bipm-si-brochure/site/*']}"
      # puts "Ls #{Dir['bipm-si-brochure/site/documents/*']}"
      Dir["bipm-si-brochure/_site/documents/*.rxl"].each do |f|
        puts "Parsing #{f}"
        docstd = Nokogiri::XML File.read f
        doc = docstd.at "/bibdata"
        hash1 = RelatonBipm::XMLParser.from_xml(doc.to_xml).to_hash
        fix_si_brochure_id hash1
        basename = File.join @data_fetcher.output, File.basename(f).sub(/(?:-(?:en|fr))?\.rxl$/, "")
        outfile = "#{basename}.#{@data_fetcher.ext}"
        key = hash1["docnumber"] || basename
        @data_fetcher.index2.add_or_update Id.new.parse(key).to_hash, outfile
        hash = if File.exist? outfile
                 warn_duplicate = false
                 hash2 = YAML.load_file outfile
                 fix_si_brochure_id hash2
                 deep_merge hash1, hash2
               else
                 warn_duplicate = true
                 hash1
               end
        item = RelatonBipm::BipmBibliographicItem.from_hash(**hash)
        @data_fetcher.write_file outfile, item, warn_duplicate: warn_duplicate
        puts "Saved to #{outfile}"
      end
    end

    #
    # Update ID of SI brochure
    #
    # @param [Hash] hash hash of bibitem
    #
    # @return [void]
    #
    def fix_si_brochure_id(hash)
      # isbn = hash["docid"].detect { |id| id["type"] == "ISBN" }
      # num = isbn && isbn["id"] == "978-92-822-2272-0" ?  "SI Brochure" : "SI Brochure, Appendix 4"

      update_id hash

      prid = primary_id hash
      if hash["docnumber"]
        hash["docnumber"].sub!(/^Brochure(?:\sConcise|\sFAQ)?$/i, prid.sub(/^BIPM\s/, ""))
      else
        hash["docnumber"] = prid.sub(/^BIPM\s/, "")
      end
      hash["id"] = prid.gsub(/[,\s]/, "")
    end

    def update_id(hash)
      hash["docid"].each do |id|
        next unless id["type"] == "BIPM" && id["id"].match?(/BIPM Brochure/i)

        id["primary"] = true
        id["id"].sub!(/(?<=^BIPM\s)(Brochure)/i, "SI \\1")
      end
    end

    def primary_id(hash)
      hash["docid"].detect do |id|
        id["primary"] && (id["language"] == "en" || id["language"].nil?)
      end["id"]
    end

    #
    # Deep merge two hashes
    #
    # @param [Hash] hash1
    # @param [Hash] hash2
    #
    # @return [Hash] Merged hash
    #
    def deep_merge(hash1, hash2) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      hash1.merge(hash2) do |_, oldval, newval|
        if oldval.is_a?(Hash) && newval.is_a?(Hash)
          deep_merge(oldval, newval)
        elsif oldval.is_a?(Array) && newval.is_a?(Array)
          (oldval + newval).uniq { |i| downcase_all i }
        else
          newval || oldval
        end
      end
    end

    #
    # Downcase all values in hash or array
    #
    # @param [Array, Hash, String] content hash, array or string
    #
    # @return [Array, Hash, String] hash, array or string with downcased values
    #
    def downcase_all(content)
      case content
      when Hash then content.transform_values { |v| downcase_all v }
      when Array then content.map { |v| downcase_all v }
      when String then content.downcase
      else content
      end
    end
  end
end
