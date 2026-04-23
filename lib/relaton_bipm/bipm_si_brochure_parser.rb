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
    def parse
      parse_rxl_documents
      parse_collection_documents
    end

    #
    # Parse per-document .rxl files (guides, MEPs, concise, FAQ, appendix 3).
    #
    def parse_rxl_documents
      Dir["bipm-si-brochure/_site/documents/*.rxl"].each do |f|
        puts "Parsing #{f}"
        bibdata = Nokogiri::XML(File.read(f)).at("/bibdata")
        basename = File.basename(f).sub(/(?:-(?:en|fr))?\.rxl$/, "")
        process_bibdata bibdata, basename: basename
      end
    end

    #
    # Parse the main SI Brochure, emitted by metanorma as a collection under
    # _site/documents/brochure/ as semantic XML (no per-doc .rxl). English is
    # processed first; French merges on top, producing a single combined
    # data/si-brochure.yaml with both languages' docidentifiers and titles.
    #
    def parse_collection_documents
      Dir["bipm-si-brochure/_site/documents/brochure/si-brochure-{en,fr}.xml"].each do |f|
        puts "Parsing #{f}"
        doc = Nokogiri::XML(File.read(f))
        doc.remove_namespaces!
        bibdata = doc.at_xpath("//bibdata[@type='standard']")
        next unless bibdata

        process_bibdata bibdata,
                        basename: "si-brochure",
                        index_key: { group: "SI", type: "Brochure" }
      end
    end

    #
    # Convert a <bibdata> node into a Relaton item, merging with any previously
    # written YAML at the same path (en/fr two-pass merge), and update the
    # index.
    #
    # @param [Nokogiri::XML::Node] bibdata
    # @param [String] basename file basename (without extension) under the data dir
    # @param [Hash, nil] index_key explicit index key; when nil, derived from docnumber
    #
    def process_bibdata(bibdata, basename:, index_key: nil) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      hash1 = RelatonBipm::XMLParser.from_xml(bibdata.to_xml).to_hash
      fix_si_brochure_id hash1
      # Normalize through BibItem so shape matches a YAML-roundtripped hash
      # (e.g. default format: "text/plain" on titles). Without this, deep_merge
      # can't dedupe identical title entries between the two language passes.
      hash1 = RelatonBipm::BipmBibliographicItem.from_hash(**hash1).to_hash

      outfile = File.join(@data_fetcher.output, "#{basename}.#{@data_fetcher.ext}")
      key = index_key || Id.new.parse(hash1["docnumber"] || basename).to_hash
      @data_fetcher.index2.add_or_update key, outfile

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
