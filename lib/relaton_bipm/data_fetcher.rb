module RelatonBipm
  class DataFetcher
    #
    # Initialize fetcher
    #
    # @param [String] output output directory to save files
    # @param [String] format format of output files (xml, yaml, bibxml)
    #
    def initialize(output, format)
      @output = output
      @format = format
      @ext = format.sub(/^bib/, "")
      @files = []
      @index_path = "index.yaml"
      @index = File.exist?(@index_path) ? YAML.load_file(@index_path) : {}
    end

    #
    # Initialize fetcher and run fetching
    #
    # @param [String] source Source name
    # @param [Strin] output directory to save files, default: "data"
    # @param [Strin] format format of output files (xml, yaml, bibxml), default: yaml
    #
    def self.fetch(source, output: "data", format: "yaml")
      t1 = Time.now
      puts "Started at: #{t1}"
      FileUtils.mkdir_p output
      new(output, format).fetch(source)
      t2 = Time.now
      puts "Stopped at: #{t2}"
      puts "Done in: #{(t2 - t1).round} sec."
    end

    #
    # Fetch bipm-data-outcomes or si-brochure
    #
    # @param [String] source Source name
    #
    def fetch(source)
      case source
      when "bipm-data-outcomes" then parse_bipm_data_outcomes
      when "bipm-si-brochure" then parse_si_brochure
      end
      File.write @index_path, @index.to_yaml, encoding: "UTF-8"
    end

    #
    # Parse BIPM meeting and write them to YAML files
    #
    def parse_bipm_data_outcomes
      source_path = File.join "bipm-data-outcomes", "{cctf,cgpm,cipm}"
      Dir[source_path].each { |body_dir| fetch_body(body_dir) }
    end

    #
    # Parse SI brochure and write them to YAML files
    #
    def parse_si_brochure # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      puts "Parsing SI brochure..."
      puts "Ls #{Dir['*']}"
      puts "Ls #{Dir['bipm-si-brochure/*']}"
      puts "Ls #{Dir['bipm-si-brochure/site/*']}"
      puts "Ls #{Dir['bipm-si-brochure/site/documents/*']}"
      Dir["bipm-si-brochure/site/documents/*.rxl"].each do |f|
        puts "Parsing #{f}"
        docstd = Nokogiri::XML File.read f
        doc = docstd.at "/bibdata"
        hash1 = RelatonBipm::XMLParser.from_xml(doc.to_xml).to_hash
        hash1["fetched"] = Date.today.to_s
        hash1["docid"].detect { |id| id["type"] == "BIPM" }["primary"] = true
        outfile = File.join @output, File.basename(f).sub(/(?:-(?:en|fr))?\.rxl$/, ".yaml")
        @index[[hash1["docnumber"] || File.basename(outfile, ".yaml")]] = outfile
        hash = if File.exist? outfile
                 warn_duplicate = false
                 hash2 = YAML.load_file outfile
                 deep_merge hash1, hash2
               else
                 warn_duplicate = true
                 hash1
               end
        item = RelatonBipm::BipmBibliographicItem.from_hash(**hash)
        write_file outfile, item, warn_duplicate: warn_duplicate
        puts "Saved to #{outfile}"
      end
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
          oldval | newval
        else
          newval || oldval
        end
      end
    end

    #
    # Search for English meetings in the body directory
    #
    # @param [String] dir body directory
    #
    def fetch_body(dir)
      body = dir.split("/").last.upcase
      Dir[File.join(dir, "*-en")].each { |type_dir| fetch_type type_dir, body }
    end

    #
    # Search for meetings
    #
    # @param [String] dir meeting directory
    # @param [String] body name of body
    #
    def fetch_type(dir, body) # rubocop:disable Metrics/AbcSize
      type = dir.split("/").last.split("-").first.sub(/s$/, "")
      body_dir = File.join @output, body.downcase
      FileUtils.mkdir_p body_dir
      outdir = File.join body_dir, type.downcase
      FileUtils.mkdir_p outdir
      Dir[File.join(dir, "*.{yml,yaml}")].each { |en_file| fetch_meeting en_file, body, type, outdir }
    end

    #
    # Create and write BIPM meeting/resolution
    #
    # @param [String] en_file Path to English file
    # @param [String] body Body name
    # @param [String] type Type of Recommendation/Decision/Resolution
    # @param [String] dir output directory
    #
    def fetch_meeting(en_file, body, type, dir) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      en = RelatonBib.parse_yaml File.read(en_file, encoding: "UTF-8"), [Date]
      en_md = en["metadata"]
      fr_file = en_file.sub "en", "fr"
      fr = RelatonBib.parse_yaml File.read(fr_file, encoding: "UTF-8"), [Date]
      fr_md = fr["metadata"]
      gh_src = "https://raw.githubusercontent.com/metanorma/bipm-data-outcomes/"
      src_en = gh_src + en_file.split("/")[-3..].unshift("main").join("/")
      src_fr = gh_src + fr_file.split("/")[-3..].unshift("main").join("/")
      src = [{ type: "src", content: src_en }, { type: "src", content: src_fr }]

      /^(?<num>\d+)(?:-_(?<part>\d+))?-\d{4}$/ =~ en_md["url"].split("/").last
      id = "#{body} #{type.capitalize} #{num}"
      file = "#{num}.yaml"
      path = File.join dir, file
      link = "https://raw.githubusercontent.com/relaton/relaton-data-bipm/master/#{path}"
      hash = bibitem type: type, en: en_md, fr: fr_md, id: id, num: num, src: src, pdf: en["pdf"]
      if @files.include?(path) && part
        add_part hash, part
        item = RelatonBipm::BipmBibliographicItem.new(**hash)
        yaml = RelatonBib.parse_yaml(File.read(path, encoding: "UTF-8"), [Date])
        has_part_item = RelatonBipm::BipmBibliographicItem.from_hash(yaml)
        has_part_item.relation << RelatonBib::DocumentRelation.new(type: "partOf", bibitem: item)
        write_file path, has_part_item, warn_duplicate: false
        path = File.join dir, "#{num}-#{part}.yaml"
      elsif part
        hash[:title].each { |t| t[:content] = t[:content].sub(/\s\(.+\)$/, "") }
        hash[:link] = [{ type: "src", content: link }]
        h = bibitem type: type, en: en_md, fr: fr_md, id: id, num: num, src: src, pdf: en["pdf"]
        add_part h, part
        part_item = RelatonBipm::BipmBibliographicItem.new(**h)
        part_item_path = File.join dir, "#{num}-#{part}.yaml"
        write_file part_item_path, part_item
        @index[[h[:docnumber]]] = part_item_path
        hash[:relation] = [RelatonBib::DocumentRelation.new(type: "partOf", bibitem: part_item)]
        item = RelatonBipm::BipmBibliographicItem.new(**hash)
      else
        item = RelatonBipm::BipmBibliographicItem.new(**hash)
      end
      write_file path, item
      @index[[hash[:docnumber]]] = path
      fetch_resolution body: body, en: en, fr: fr, dir: dir, src: src, num: num
    end

    #
    # Parse BIPM resolutions and write them to YAML files
    #
    # @param [String] body body name
    # @param [Hash] eng English metadata
    # @param [Hash] frn French metadata
    # @param [String] dir output directory
    # @param [Array<Hash>] src links to bipm-data-outcomes
    # @param [String] num number of meeting
    #
    def fetch_resolution(**args) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      args[:en]["resolutions"].each.with_index do |r, i| # rubocop:disable Metrics/BlockLength
        hash = { fetched: Date.today.to_s, title: [], doctype: r["type"] }
        hash[:title] << title(r["title"], "en") if r["title"]
        fr_resolution = args[:fr]["resolutions"].fetch(i, nil)
        if fr_resolution
          fr_title = fr_resolution["title"]
          hash[:title] << title(fr_title, "fr") if fr_title
        end
        date = r["dates"].first.to_s
        hash[:date] = [{ type: "published", on: date }]
        num = r["identifier"].to_s.split("-").last
        year = date.split("-").first
        num = "0" if num == year
        num_justed = num.rjust 2, "0"
        type = r["type"].capitalize
        id = "#{args[:body]} #{type}"
        hash[:id] = "#{args[:body]}-#{type}-#{year}"
        if num.to_i.positive?
          id += " #{num}"
          hash[:id] += "-#{num_justed}"
        end
        id += " (#{year})"
        hash[:docid] = [
          make_docid(id: id, type: "BIPM", primary: true),
          make_docid(id: id, type: "BIPM", primary: true, language: "en", script: "Latn"),
          id_fr(id),
        ]
        hash[:docnumber] = id
        hash[:link] = [{ type: "src", content: r["url"] }] + args[:src]
        hash[:link] << { type: "pdf", content: r["reference"] } if r["reference"]
        hash[:language] = %w[en fr]
        hash[:script] = ["Latn"]
        hash[:contributor] = [{
          entity: { url: "www.bipm.org", name: "Bureau International des Poids et Mesures", abbreviation: "BIPM" },
          role: [{ type: "publisher" }],
        }]
        hash[:structuredidentifier] = RelatonBipm::StructuredIdentifier.new docnumber: num
        item = RelatonBipm::BipmBibliographicItem.new(**hash)
        file = year
        file += "-#{num_justed}" if num.size < 4
        file += ".yaml"
        out_dir = File.join args[:dir], r["type"].downcase
        FileUtils.mkdir_p out_dir
        path = File.join out_dir, file
        write_file path, item
        @index[["#{args[:body]} #{type} #{year}-#{num_justed}", "#{args[:body]} #{type} #{args[:num]}-#{num_justed}"]] = path
      end
    end

    def title(content, language)
      { content: content, language: language, script: "Latn" }
    end

    #
    # Add part to ID and structured identifier
    #
    # @param [Hash] hash Hash of BIPM meeting
    # @param [String] session number of meeting
    #
    def add_part(hash, part)
      hash[:id] += "-#{part}"
      hash[:docnumber] += "-#{part}"
      id = hash[:docid][0].instance_variable_get(:@id)
      id += "-#{part}"
      hash[:docid][0].instance_variable_set(:@id, id)
      hash[:structuredidentifier].instance_variable_set :@part, part
    end

    #
    # Create hash from BIPM meeting/resolution
    #
    # @param [Hash] **args Hash of arguments
    # @option args [String] :type Type of meeting/resolution
    # @option args [Hash] :en Hash of English metadata
    # @option args [Hash] :fr Hash of French metadata
    # @option args [String] :id ID of meeting/resolution
    # @option args [String] :num Number of meeting/resolution
    # @option args [Array<Hash>] :src Array of links to bipm-data-outcomes
    # @option args [String] :pdf link to PDF
    #
    # @return [Hash] Hash of BIPM meeting/resolution
    #
    def bibitem(**args) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
      hash = { title: [], doctype: args[:type], fetched: Date.today.to_s }
      hash[:title] << title(args[:en]["title"], "en") if args[:en]["title"]
      hash[:title] << title(args[:fr]["title"], "fr") if args[:fr]["title"]
      hash[:date] = [{ type: "published", on: args[:en]["date"] }]
      hash[:docid] = [
        make_docid(id: args[:id], type: "BIPM", primary: true),
        make_docid(id: args[:id], type: "BIPM", primary: true, language: "en", script: "Latn"),
        id_fr(args[:id]),
      ]
      hash[:id] = args[:id].gsub " ", "-"
      hash[:docnumber] = args[:id]
      hash[:link] = [{ type: "src", content: args[:en]["url"] }]
      RelatonBib.array(args[:pdf]).each { |pdf| hash[:link] << { type: "pdf", content: pdf } }
      hash[:link] += args[:src] if args[:src]&.any?
      hash[:language] = %w[en fr]
      hash[:script] = ["Latn"]
      hash[:contributor] = [{
        entity: { url: "www.bipm.org", name: "Bureau International des Poids et Mesures", abbreviation: "BIPM" },
        role: [{ type: "publisher" }],
      }]
      hash[:structuredidentifier] = RelatonBipm::StructuredIdentifier.new docnumber: args[:num]
      hash
    end

    def id_fr(en_id)
      tr = BipmBibliography::TRANSLATIONS.detect { |_, v| en_id.include? v }
      id = en_id.sub tr[1], tr[0]
      make_docid(id: id, type: "BIPM", primary: true, language: "fr", script: "Latn")
    end

    #
    # Create doucment ID
    #
    # @param [String] id ID of document
    # @param [String] type Type of document
    # @param [Boolean] primary Primary document
    # @param [String] language Language of document
    # @param [String] script Script of document
    #
    # @return [RelatonBib::DocumentIdentifier] Document ID
    #
    def make_docid(**args)
      RelatonBib::DocumentIdentifier.new(**args)
    end

    #
    # Save document to file
    #
    # @param [String] path Path to file
    # @param [RelatonBipm::BipmBibliographicItem] item document to save
    # @param [Boolean, nil] warn_duplicate Warn if document already exists
    #
    # @return [<Type>] <description>
    #
    def write_file(path, item, warn_duplicate: true)
      if @files.include?(path)
        warn "File #{path} already exists" if warn_duplicate
      else
        @files << path
      end
      File.write path, item.to_hash.to_yaml, encoding: "UTF-8"
    end
  end
end
