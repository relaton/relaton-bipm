module RelatonBipm
  class DataOutcomesParser
    SHORTTYPE = {
      "Resolution" => "RES",
      "Recommendation" => "REC",
      "Decision" => "DECN",
      "Statement" => "DECL",
      "Declaration" => "DECL",
      "Action" => "ACT",
    }.freeze

    TRANSLATIONS = {
      "Declaration" => "Déclaration",
      "Meeting" => "Réunion",
      "Recommendation" => "Recommandation",
      "Resolution" => "Résolution",
      "Decision" => "Décision",
    }.freeze

    #
    # Create data-outcomes parser
    #
    # @param [RelatonBipm::DataFetcher] data_fetcher data fetcher
    #
    def initialize(data_fetcher)
      @data_fetcher = WeakRef.new data_fetcher
    end

    #
    # Parse documents from data-outcomes dataset and write them to YAML files
    #
    # @param [RelatonBipm::DataFetcher] data_fetcher data fetcher
    #
    def self.parse(data_fetcher)
      new(data_fetcher).parse
    end

    #
    # Parse BIPM meeting and write them to YAML files
    #
    def parse
      dirs = "cctf,cgpm,cipm,ccauv,ccem,ccl,ccm,ccpr,ccqm,ccri,cct,ccu,jcgm,jcrb"
      source_path = File.join "bipm-data-outcomes", "{#{dirs}}"
      Dir[source_path].each { |body_dir| fetch_body(body_dir) }
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
      body_dir = File.join @data_fetcher.output, body.downcase
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
      _, en, fr_file, fr = read_files en_file
      en_md, fr_md, num, part = meeting_md en, fr
      src = meeting_links en_file, fr_file

      file = "#{num}.#{@data_fetcher.ext}"
      path = File.join dir, file
      hash = bibitem body: body, type: type, en: en_md, fr: fr_md, num: num, src: src, pdf: en["pdf"]
      if @data_fetcher.files.include?(path) && part
        add_part hash, part
        item = RelatonBipm::BipmBibliographicItem.new(**hash)
        yaml = RelatonBib.parse_yaml(File.read(path, encoding: "UTF-8"), [Date])
        has_part_item = RelatonBipm::BipmBibliographicItem.from_hash(yaml)
        has_part_item.relation << RelatonBib::DocumentRelation.new(type: "partOf", bibitem: item)
        @data_fetcher.write_file path, has_part_item, warn_duplicate: false
        path = File.join dir, "#{num}-#{part}.#{@data_fetcher.ext}"
      elsif part
        hash[:title].each { |t| t[:content] = t[:content].sub(/\s\(.+\)$/, "") }
        h = bibitem body: body, type: type, en: en_md, fr: fr_md, num: num, src: src, pdf: en["pdf"]
        add_part h, part
        part_item = RelatonBipm::BipmBibliographicItem.new(**h)
        part_item_path = File.join dir, "#{num}-#{part}.#{@data_fetcher.ext}"
        @data_fetcher.write_file part_item_path, part_item
        add_to_index part_item, part_item_path
        hash[:relation] = [RelatonBib::DocumentRelation.new(type: "partOf", bibitem: part_item)]
        item = RelatonBipm::BipmBibliographicItem.new(**hash)
      else
        item = RelatonBipm::BipmBibliographicItem.new(**hash)
      end
      @data_fetcher.write_file path, item
      add_to_index item, path
      fetch_resolution body: body, en: en, fr: fr, dir: dir, src: src, num: num
    end

    #
    # Read English and French files
    #
    # @param [String] en_file Path to English file
    #
    # @return [Array<Hash, String, nil>] English / French metadata and file path
    #
    def read_files(en_file)
      fr_file = en_file.sub "en", "fr"
      [en_file, fr_file].map do |file|
        if File.exist? file
          data = RelatonBib.parse_yaml(File.read(file, encoding: "UTF-8"), [Date])
          path = file
        end
        [path, data]
      end.flatten
    end

    def meeting_md(eng, frn)
      en_md = eng["metadata"]
      num, part = en_md["identifier"].to_s.split("-")
      [en_md, frn&.dig("metadata"), num, part]
    end

    def meeting_links(en_file, fr_file)
      gh_src = "https://raw.githubusercontent.com/metanorma/bipm-data-outcomes/"
      { "en" => en_file, "fr" => fr_file }.map do |lang, file|
        next unless file

        src = gh_src + file.split("/")[-3..].unshift("main").join("/")
        { type: "src", content: src, language: lang, script: "Latn" }
      end.compact
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
        hash = {
          type: "proceedings", title: [],
          doctype: r["type"], place: [RelatonBib::Place.new(city: "Paris")]
        }
        fr_r = args[:fr]["resolutions"].fetch(i, nil)
        hash[:title] = resolution_title r, fr_r
        hash[:link] = resolution_link r, fr_r, args[:src]
        date = r["dates"].first.to_s
        hash[:date] = [{ type: "published", on: date }]
        num = r["identifier"].to_s # .split("-").last
        year = date.split("-").first
        num = "0" if num == year
        num_justed = num.rjust 2, "0"
        type = r["type"].capitalize
        docnum = create_docnum args[:body], type, num, date
        hash[:id] = create_id(args[:body], type, num_justed, date)
        hash[:docid] = create_docids docnum
        hash[:docnumber] = docnum
        hash[:language] = %w[en fr]
        hash[:script] = ["Latn"]
        hash[:contributor] = contributors date, args[:body]
        hash[:structuredidentifier] = RelatonBipm::StructuredIdentifier.new docnumber: num
        item = RelatonBipm::BipmBibliographicItem.new(**hash)
        file = "#{year}-#{num_justed}.#{@data_fetcher.ext}"
        out_dir = File.join args[:dir], r["type"].downcase
        FileUtils.mkdir_p out_dir
        path = File.join out_dir, file
        @data_fetcher.write_file path, item
        add_to_index item, path
      end
    end

    #
    # Parse resolution titles
    #
    # @param [Hash] en_r english resolution
    # @param [Hash] fr_r french resolution
    #
    # @return [Array<Hash>] titles
    #
    def resolution_title(en_r, fr_r)
      title = []
      title << create_title(en_r["title"], "en") if en_r["title"] && !en_r["title"].empty?
      title << create_title(fr_r["title"], "fr") if fr_r && fr_r["title"] && !fr_r["title"].empty?
      title
    end

    #
    # Parse resolution links
    #
    # @param [Hash] en_r english resolution
    # @param [Hash] fr_r french resolution
    # @param [Array<Hash>] src data source links
    #
    # @return [Array<Hash>] links
    #
    def resolution_link(en_r, fr_r, src)
      link = [{ type: "citation", content: en_r["url"], language: "en", script: "Latn" }]
      if fr_r
        link << { type: "citation", content: fr_r["url"], language: "fr", script: "Latn" }
      end
      link += src
      link << { type: "pdf", content: en_r["reference"] } if en_r["reference"]
      link
    end

    #
    # Add item to index
    #
    # @param [RelatonBipm::BipmBibliographicItem] item bibliographic item
    # @param [String] path path to YAML file
    #
    def add_to_index(item, path) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      # key = [item.docnumber]
      # SHORTTYPE.each do |k, v|
      #   if item.docnumber.include? k
      #     key << item.docnumber.sub(k, v)
      #     key << item.docnumber.sub(k, v).sub(/(\(\d{4})(\))/, "\\1, EN\\2")
      #     key << item.docnumber.sub(k, v).sub(/(\(\d{4})(\))/, "\\1, FR\\2")
      #     break
      #   end
      # end
      key = item.docidentifier.select { |i| i.type == "BIPM" }.map &:id
      @data_fetcher.index[key] = path
      @data_fetcher.index_new.add_or_update key, path
      key2 = Id.new(item.docnumber).to_hash
      @data_fetcher.index2.add_or_update key2, path
    end

    #
    # Create contributors
    #
    # @param [Strign] date date of publication
    # @param [Strign] body organization abbreviation (CCTF, CIPM, CGPM)
    #
    # @return [Array<Hash>] contributors
    #
    def contributors(date, body) # rubocop:disable Metrics/MethodLength
      case body
      when "CCTF" then cctf_org date
      when "CGPM" then cgpm_org
      when "CIPM" then cipm_org
      else []
      end.reduce(
        [{ entity: {
             url: "www.bipm.org",
             name: "Bureau International des Poids et Mesures",
             abbreviation: "BIPM",
           },
           role: [{ type: "publisher" }] }],
      ) { |a, e| a << { entity: e, role: [{ type: "author" }] } }
    end

    #
    # Create CCTF organization
    #
    # @param [String] date date of meeting
    #
    # @return [Array<Hash>] CCTF organization
    #
    def cctf_org(date) # rubocop:disable Metrics/MethodLength
      if Date.parse(date).year < 1999
        nms = [
          { content: "Consultative Committee for the Definition of the Second", language: "en" },
          { content: "Comité Consultatif pour la Définition de la Seconde", language: "fr" },
        ]
        organization nms, "CCDS"
      else
        nms = [
          { content: "Consultative Committee for Time and Frequency", language: "en" },
          { content: "Comité consultatif du temps et des fréquences", language: "fr" },
        ]
        organization nms, "CCTF"
      end
    end

    #
    # Create organization
    #
    # @param [Array<Hash>] names organization names in different languages
    # @param [String] abbr abbreviation
    #
    # @return [Array<Hash>] organization
    #
    def organization(names, abbr)
      names.each { |ctrb| ctrb[:script] = "Latn" }
      [{ name: names, abbreviation: { content: abbr, language: ["en", "fr"], script: "Latn" } }]
    end

    #
    # Create CGPM organization
    #
    # @return [Array<Hash>] CGPM organization
    #
    def cgpm_org
      nms = [
        { content: "General Conference on Weights and Measures", language: "en" },
        { content: "Conférence Générale des Poids et Mesures", language: "fr" },
      ]
      organization nms, "CGPM"
    end

    #
    # Create CIPM organization
    #
    # @return [Array<Hash>] CIPM organization
    #
    def cipm_org
      names = [
        { content: "International Committee for Weights and Measures", language: "en" },
        { content: "Comité International des Poids et Mesures", language: "fr" },
      ]
      organization names, "CIPM"
    end

    #
    # Create a title
    #
    # @param [String] content title content
    # @param [String] language language code (en, fr)
    #
    # @return [Hash] title
    #
    def create_title(content, language)
      { content: content, language: language, script: "Latn" }
    end

    #
    # Add part to ID and structured identifier
    #
    # @param [Hash] hash Hash of BIPM meeting
    # @param [String] session number of meeting
    #
    def add_part(hash, part)
      regex = /(\p{L}+\s(?:\w+\/)?\d+)(?![\d-])/
      hash[:id] += "-#{part}"
      hash[:docnumber].sub!(regex) { |m| "#{m}-#{part}" }
      hash[:docid].select { |id| id.type == "BIPM" }.each do |did|
        did.instance_variable_get(:@id).sub!(regex) { "#{$1}-#{part}" }
        # did.instance_variable_set(:@id, id)
      end
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
      docnum = create_meeting_docnum args[:body], args[:type], args[:num], args[:en]["date"]
      hash = { title: [], type: "proceedings", doctype: args[:type],
               place: [RelatonBib::Place.new(city: "Paris")] }
      hash[:title] = create_titles args.slice(:en, :fr)
      hash[:date] = [{ type: "published", on: args[:en]["date"] }]
      hash[:docid] = create_meeting_docids docnum
      hash[:docnumber] = docnum # .sub(" --", "").sub(/\s\(\d{4}\)/, "")
      hash[:id] = create_id(args[:body], args[:type], args[:num], args[:en]["date"])
      hash[:link] = create_links(**args)
      hash[:language] = %w[en fr]
      hash[:script] = ["Latn"]
      hash[:contributor] = contributors args[:en]["date"], args[:body]
      hash[:structuredidentifier] = RelatonBipm::StructuredIdentifier.new docnumber: args[:num]
      hash
    end

    def create_titles(data)
      data.each_with_object([]) do |(lang, md), mem|
        mem << create_title(md["title"], lang.to_s) if md && md["title"]
      end
    end

    #
    # Create links
    #
    # @param [Hash] **args Hash of arguments
    #
    # @return [Array<Hash>] Array of links
    #
    def create_links(**args)
      links = args.slice(:en, :fr).each_with_object([]) do |(lang, md), mem|
        next unless md && md["url"]

        mem << { type: "citation", content: md["url"], language: lang.to_s, script: "Latn" }
      end
      RelatonBib.array(args[:pdf]).each { |pdf| links << { type: "pdf", content: pdf } }
      links += args[:src] if args[:src]
      links
    end

    #
    # Creata a document number
    #
    # @param [<Type>] body <description>
    # @param [<Type>] type <description>
    # @param [<Type>] num <description>
    # @param [<Type>] date <description>
    #
    # @return [<Type>] <description>
    #
    def create_docnum(body, type, num, date)
      year = Date.parse(date).year
      # if special_id_case? body, type, year
      #   id = "#{type.capitalize} #{body}"
      #   id += "/#{num}" if num.to_i.positive?
      # else
      id = "#{body} #{SHORTTYPE[type.capitalize]}"
      id += " #{num}" if num.to_i.positive?
      # end
      "#{id} (#{year})"
    end

    def create_meeting_docnum(body, type, num, date)
      year = Date.parse(date).year
      "#{body} #{num}th #{type} (#{year})"
    end

    #
    # Create ID
    #
    # @param [String] body body of meeting
    # @param [String] type type of meeting
    # @param [String, nil] num part number
    # @param [String] date published date
    #
    # @return [String] ID
    #
    def create_id(body, type, num, date)
      year = Date.parse(date).year
      # if special_id_case?(body, type, year)
      #   [type.capitalize, body, year]
      # else
      [body, SHORTTYPE[type.capitalize], year, num].compact.join("-")
      # end
    end

    #
    # Check if ID is special case
    #
    # @param [String] body body of meeting
    # @param [String] type type of meeting
    # @param [String] year published year
    #
    # @return [Boolean] is special case
    #
    # def special_id_case?(body, type, year)
    #   (body == "CIPM" && type == "Decision" && year.to_i > 2011) ||
    #     (body == "JCRB" && %w[recomendation resolution descision].include?(type))
    # end

    #
    # Create documetn IDs
    #
    # @param [String] en_id document ID in English
    #
    # @return [Array<RelatonBib::DocumentIdentifier>] document IDs
    #
    def create_docids(id)
      en_id = id.sub(/(\s\(\d{4})(\))$/, '\1, E\2')
      fr_id = id.sub(/(\s\(\d{4})(\))$/, '\1, F\2')
      [
        make_docid(id: id, type: "BIPM", primary: true),
        make_docid(id: en_id, type: "BIPM", primary: true, language: "en", script: "Latn"),
        make_docid(id: fr_id, type: "BIPM", primary: true, language: "fr", script: "Latn"),
        # create_docid_fr(en_id),
      ]
    end

    def create_meeting_docids(en_id)
      fr_id = en_id.sub(/(\d+)th/, '\1e').sub("meeting", "réunion")
      [
        make_docid(id: en_id, type: "BIPM", primary: true, language: "en", script: "Latn"),
        make_docid(id: fr_id, type: "BIPM", primary: true, language: "fr", script: "Latn"),
      ]
    end

    #
    # Create French document ID
    #
    # @param [String] en_id English document ID
    #
    # @return [RelatonBib::DocumentIdentifier] french document ID
    #
    # def create_docid_fr(en_id)
    #   tr = TRANSLATIONS.detect { |_, v| en_id.include? v }
    #   id = tr ? en_id.sub(tr[1], tr[0]) : en_id
    #   make_docid(id: id, type: "BIPM", primary: true, language: "fr", script: "Latn")
    # end

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
  end
end
