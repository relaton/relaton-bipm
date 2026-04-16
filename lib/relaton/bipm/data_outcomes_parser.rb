module Relaton::Bipm
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
    # @param [Relaton::Bipm::DataFetcher] data_fetcher data fetcher
    #
    def initialize(data_fetcher)
      @data_fetcher = WeakRef.new data_fetcher
    end

    #
    # Parse documents from data-outcomes dataset and write them to YAML files
    #
    # @param [Relaton::Bipm::DataFetcher] data_fetcher data fetcher
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
      type = dir.split("/").last.split("-").first.sub(/s$/, "").capitalize
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
    # @param [String] type meeting
    # @param [String] dir output directory
    #
    def fetch_meeting(en_file, body, type, dir) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      _, en, fr_file, fr = read_files en_file
      en_md, fr_md, num, part = meeting_md en, fr
      src = meeting_links en_file, fr_file

      file = "#{num}.#{@data_fetcher.ext}"
      path = File.join dir, file
      hash = meeting_bibitem body: body, type: type, en: en_md, fr: fr_md, num: num, src: src, pdf: en["pdf"]
      if @data_fetcher.files.include?(path) && part
        add_part hash, body, type, num, part
        item = ItemData.new(**hash)
        has_part_item = parse_file path
        has_part_item.relation << Relaton::Bib::Relation.new(type: "partOf", bibitem: item)
        @data_fetcher.write_file path, has_part_item, warn_duplicate: false
        path = File.join dir, "#{num}-#{part}.#{@data_fetcher.ext}"
      elsif part
        hash[:title].each { |t| t.content.sub!(/\s\(.+\)$/, "") }
        h = meeting_bibitem body: body, type: type, en: en_md, fr: fr_md, num: num, src: src, pdf: en["pdf"]
        add_part h, body, type, num, part
        part_item = ItemData.new(**h)
        part_item_path = File.join dir, "#{num}-#{part}.#{@data_fetcher.ext}"
        @data_fetcher.write_file part_item_path, part_item
        add_to_index part_item, part_item_path
        hash[:relation] = [Relaton::Bib::Relation.new(type: "partOf", bibitem: part_item)]
        item = ItemData.new(**hash)
      else
        item = ItemData.new(**hash)
      end
      @data_fetcher.write_file path, item
      add_to_index item, path
      fetch_resolution body: body, en: en, fr: fr, dir: dir, src: src, num: num
    end

    def parse_file(path)
        case @data_fetcher.format
        when "yaml"
          Item.from_yaml(File.read(path, encoding: "UTF-8"))
        when "xml"
          Item.from_xml(File.read(path, encoding: "UTF-8"))
        end
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
          data = YAML.safe_load(File.read(file, encoding: "UTF-8"))
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
        Relaton::Bib::Uri.new(type: "src", content: src, language: lang, script: "Latn")
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
        num = r["identifier"].to_s # .split("-").last
        date = r["dates"].first.to_s
        @data_fetcher.errors[:resolution_date] &&= date.nil? || date.empty?
        year = date.split("-").first
        num = "0" if num == year

        hash = {
          type: "proceedings",
          title: [],
          place: [Relaton::Bib::Place.new(city: "Paris")],
          ext: create_ext(r["type"], num),
        }

        fr_r = args.dig(:fr, "resolutions", i) # @TODO: create a GH issue when fr is missing
        hash[:title] = resolution_title r, fr_r
        hash[:source] = resolution_source r, fr_r, args[:src]
        hash[:date] = create_date(type: "published", at: date)
        num_justed = num.rjust 2, "0"
        type = r["type"].capitalize
        docnum = create_resolution_docnum args[:body], type, num, date
        hash[:id] = create_id(body: args[:body], type: type, num: num_justed, date: date)
        hash[:docidentifier] = create_resolution_docids args[:body], type, num, date
        hash[:docnumber] = docnum
        hash[:language] = %w[en fr]
        hash[:script] = ["Latn"]
        hash[:contributor] = contributors date, args[:body]
        @data_fetcher.errors[:resolution_contributor] &&= hash[:contributor].size < 2 # BIPM + committee
        item = ItemData.new(**hash)
        file = "#{year}-#{num_justed}.#{@data_fetcher.ext}"
        out_dir = File.join args[:dir], r["type"].downcase
        FileUtils.mkdir_p out_dir
        path = File.join out_dir, file
        @data_fetcher.write_file path, item
        add_to_index item, path
      end
    end

    def create_ext(type, num)
      doctype = Doctype.new(content: parse_doctype(type))
      strid = StructuredIdentifier.new docnumber: num
      Ext.new(doctype: doctype, structuredidentifier: strid)
    end

    def parse_doctype(type)
      case type
      when "Meeting" then "meeting-report"
      else type.downcase
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
      @data_fetcher.errors[:resolution_title] &&= title.empty?
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
    def resolution_source(en_r, fr_r, src)
      source = []
      if en_r["url"] && !en_r["url"].empty?
        source << Relaton::Bib::Uri.new(type: "citation", content: en_r["url"], language: "en", script: "Latn")
        @data_fetcher.errors[:resolution_source_citation_en] = false
      else
        @data_fetcher.errors[:resolution_source_citation] &&= true
      end
      if fr_r && fr_r["url"] && !fr_r["url"].empty?
        source << Relaton::Bib::Uri.new(type: "citation", content: fr_r["url"], language: "fr", script: "Latn")
        @data_fetcher.errors[:resolution_source_citation_fr] = false
      else
        @data_fetcher.errors[:resolution_source_citation_fr] &&= true
      end
      source += src if src
      if en_r["reference"]
        source << Relaton::Bib::Uri.new(type: "pdf", content: en_r["reference"])
        @data_fetcher.errors[:resolution_source_pdf] = false
      else
        @data_fetcher.errors[:resolution_source_pdf] &&= true
      end
      source
    end

    #
    # Add item to index
    #
    # @param [Relaton::Bipm::ItemData] item bibliographic item
    # @param [String] path path to YAML file
    #
    def add_to_index(item, path) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      key = Id.new.parse(item.docnumber).to_hash
      @data_fetcher.index.add_or_update key, path
    end

    #
    # Create contributors
    #
    # @param [Strign] date date of publication
    # @param [Strign] body organization abbreviation (CCTF, CIPM, CGPM)
    #
    # @return [Array<Hash>] contributors
    #
    def contributors(date, body)
      contribs = [bipm_contrib]
      subdiv = committee_subdivision date, body
      return contribs unless subdiv

      bipm_name = [Relaton::Bib::TypedLocalizedString.new(content: "BIPM", script: "Latn")]
      org = Relaton::Bib::Organization.new(name: bipm_name, subdivision: [subdiv])
      desc = Relaton::Bib::LocalizedMarkedUpString.new(content: "committee")
      role = Relaton::Bib::Contributor::Role.new(type: "author", description: [desc])
      contribs << Relaton::Bib::Contributor.new(organization: org, role: [role])
    end

    #
    # Create committee subdivision
    #
    # @param [String] date date of publication
    # @param [String] body organization abbreviation (CCTF, CIPM, CGPM)
    #
    # @return [Relaton::Bib::Subdivision, nil] committee subdivision
    #
    def committee_subdivision(date, body)
      case body
      when "CCTF" then cctf_subdivision date
      when "CGPM" then cgpm_subdivision
      when "CIPM" then cipm_subdivision
      end
    end

    #
    # Create BIPM contributor
    #
    # @return [Relaton::Bipm::Contributor] BIPM organization
    #
    def bipm_contrib
      nms = [
        { content: "International Bureau of Weights and Measures", language: "en" },
        { content: "Bureau international des poids et mesures", language: "fr" },
      ]
      bipm_org = organization(nms, "BIPM", abbr_lang: "fr", url: ["www.bipm.org"])
      role = Relaton::Bib::Contributor::Role.new(type: "publisher")
      Relaton::Bib::Contributor.new(organization: bipm_org, role: [role])
    end

    #
    # Create CCTF subdivision
    #
    # @param [String] date date of meeting
    #
    # @return [Relaton::Bib::Subdivision] CCTF subdivision
    #
    def cctf_subdivision(date) # rubocop:disable Metrics/MethodLength
      if ::Date.parse(date).year < 1999
        nms = [
          { content: "Consultative Committee for the Definition of the Second", language: "en" },
          { content: "Comité Consultatif pour la Définition de la Seconde", language: "fr" },
        ]
        subdivision nms, "CCDS"
      else
        nms = [
          { content: "Consultative Committee for Time and Frequency", language: "en" },
          { content: "Comité consultatif du temps et des fréquences", language: "fr" },
        ]
        subdivision nms, "CCTF"
      end
    end

    #
    # Create organization
    #
    # @param [Array<Hash>] names organization names in different languages
    # @param [String] abbr abbreviation
    # @param [String] abbr_lang language of abbreviation
    # @param [Array<String>] url array of organization URLs
    #
    # @return [Relaton::Bib::Organization] organization
    #
    def organization(names, abbr, abbr_lang: "en", url: [])
      name = names.map { |ctrb| Relaton::Bib::TypedLocalizedString.new(**ctrb, script: "Latn") }
      abbreviation = Relaton::Bib::LocalizedString.new(content: abbr, language: abbr_lang, script: "Latn")
      uri = url.map { |u| Relaton::Bib::Uri.new(content: u) }
      Relaton::Bib::Organization.new(name: name, abbreviation: abbreviation, uri: uri)
    end

    #
    # Create subdivision
    #
    # @param [Array<Hash>] names subdivision names in different languages
    # @param [String] abbr abbreviation
    # @param [String] abbr_lang language of abbreviation
    #
    # @return [Relaton::Bib::Subdivision] subdivision
    #
    def subdivision(names, abbr, abbr_lang: "en")
      name = names.map { |n| Relaton::Bib::TypedLocalizedString.new(**n, script: "Latn") }
      abbreviation = Relaton::Bib::LocalizedString.new(content: abbr, language: abbr_lang, script: "Latn")
      Relaton::Bib::Subdivision.new(type: "committee", name: name, abbreviation: abbreviation)
    end

    #
    # Create CGPM subdivision
    #
    # @return [Relaton::Bib::Subdivision] CGPM subdivision
    #
    def cgpm_subdivision
      nms = [
        { content: "General Conference on Weights and Measures", language: "en" },
        { content: "Conférence Générale des Poids et Mesures", language: "fr" },
      ]
      subdivision nms, "CGPM", abbr_lang: "fr"
    end

    #
    # Create CIPM subdivision
    #
    # @return [Relaton::Bib::Subdivision] CIPM subdivision
    #
    def cipm_subdivision
      names = [
        { content: "International Committee for Weights and Measures", language: "en" },
        { content: "Comité international des poids et mesures", language: "fr" },
      ]
      subdivision names, "CIPM", abbr_lang: "fr"
    end

    #
    # Create a title
    #
    # @param [String] content title content
    # @param [String] language language code (en, fr)
    #
    # @return [Hash] title
    #
    def create_title(content, language, format = "text/plain")
      if language == "fr"
        content.sub!(/(\d+)(e)/, '\1<sup>\2</sup>')
      end
      Relaton::Bib::Title.new(content: content, language: language, script: "Latn")
    end

    #
    # Add part to ID and structured identifier
    #
    # @param [Hash] hash Hash of BIPM meeting
    # @param [String] session number of meeting
    #
    def add_part(hash, body, type, num, part)
      regex = /(\p{L}+\s(?:\w+\/)?\d+)(?![\d-])/
      date = hash[:date].first.at.to_s
      hash[:id] = create_id(body: body, type: type, num: num, part: part, date: date) # += "#{part}"
      hash[:docnumber].sub!(regex) { |m| "#{m}-#{part}" }
      hash[:docidentifier].select { |id| id.type == "BIPM" }.each do |did|
        did.content.sub!(regex) { "#{$1}-#{part}" }
        # did.instance_variable_set(:@id, id)
      end
      hash[:ext].structuredidentifier.part = part
    end

    #
    # Create hash from BIPM meeting
    #
    # @param [Hash] **args Hash of arguments
    # @option args [String] :type meeting
    # @option args [Hash] :en Hash of English metadata
    # @option args [Hash] :fr Hash of French metadata
    # @option args [String] :id ID of meeting
    # @option args [String] :num Number of meeting
    # @option args [Array<Hash>] :src Array of links to bipm-data-outcomes
    # @option args [String] :pdf link to PDF
    #
    # @return [Hash] Hash of BIPM meeting/resolution
    #
    def meeting_bibitem(**args) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
      docnum = create_meeting_docnum args[:body], args[:type], args[:num], args[:en]["date"]
      hash = {
        title: [],
        type: "proceedings",
        place: [Relaton::Bib::Place.new(city: "Paris")],
        ext: create_ext(args[:type], args[:num]),
      }
      hash[:title] = create_titles args.slice(:en, :fr)
      hash[:date] = create_date(type: "published", at: args[:en]["date"])
      @data_fetcher.errors[:meeting_date] &&= hash[:date].empty?
      hash[:docidentifier] = create_meeting_docids docnum
      hash[:docnumber] = docnum # .sub(" --", "").sub(/\s\(\d{4}\)/, "")
      hash[:id] = create_id(body: args[:body], type: args[:type], num: args[:num], date: args[:en]["date"])
      hash[:source] = create_links(**args)
      @data_fetcher.errors[:meeting_source] &&= hash[:source].empty?
      hash[:language] = %w[en fr]
      hash[:script] = ["Latn"]
      hash[:contributor] = contributors args[:en]["date"], args[:body]
      @data_fetcher.errors[:meeting_contributor] &&= hash[:contributor].size < 2 # BIPM + committee
      hash
    end

    def create_date(**args)
      return [] if args[:at].nil? || args[:at].empty?

      [Relaton::Bib::Date.new(**args)]
    end

    def create_titles(data)
      result = data.each_with_object([]) do |(lang, md), mem|
        mem << create_title(md["title"], lang.to_s) if md && md["title"]
      end
      @data_fetcher.errors[:meeting_title] &&= result.empty?
      result
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

        mem << Relaton::Bib::Uri.new(type: "citation", content: md["url"], language: lang.to_s, script: "Latn")
      end
      Array(args[:pdf]).each { |pdf| links << Relaton::Bib::Uri.new(type: "pdf", content: pdf) }
      links += args[:src] if args[:src]
      links
    end

    #
    # Creata resolution document number
    #
    # @param [String] body CIPM, CGPM, CCTF
    # @param [String] type Recommendation, Resolution, Decision
    # @param [String] num number of recommendation, resolution, decision
    # @param [String] date date of publication
    #
    # @return [String] document number
    #
    def create_resolution_docnum(body, type, num, date)
      year = ::Date.parse(date).year
      id = "#{body} #{SHORTTYPE[type.capitalize]}"
      id += " #{num}" if num.to_i.positive?
      "#{id} (#{year})"
    end

    #
    # Create meeting document number
    #
    # @param [String] body CIPM, CGPM, CCTF
    # @param [String] type meeting
    # @param [String] num number of meeting
    # @param [String] date date of publication
    #
    # @return [String] <description>
    #
    def create_meeting_docnum(body, type, num, date)
      year = ::Date.parse(date).year
      ord = %w[th st nd rd th th th th th th][num.to_i % 10]
      "#{body} #{num}#{ord} #{type} (#{year})"
    end

    #
    # Create ID
    #
    # @param [String] body CIPM, CGPM, CCTF
    # @param [String] type meeting, recommendation, resolution, decision
    # @param [String, nil] num number of meeting, recommendation, resolution, decision
    # @param [String] date published date
    #
    # @return [String] ID
    #
    def create_id(body:, type:, num:, part: nil, date:)
      year = ::Date.parse(date).year
      [body, SHORTTYPE[type.capitalize] || type, num, part, year].compact.join.gsub("-", "")
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
    def special_id_case?(body, type, year)
      (body == "CIPM" && type == "Decision" && year.to_i > 2011) ||
        (body == "JCRB" && %w[Recomendation Resolution Descision].include?(type))
    end

    #
    # Create documetn IDs
    #
    # @param [String] en_id document ID in English
    #
    # @return [Array<Relaton::Bib::Docidentifier>] document IDs
    #
    def create_resolution_docids(body, type, num, date)
      year = ::Date.parse(date).year
      ids = []
      resolution_short_ids(body, type, num, year) { |id| ids << id }
      resolution_long_ids(body, type, num, year) { |id| ids << id }
      @data_fetcher.errors[:resolution_docidentifier] &&= ids.empty?
      ids
    end

    def resolution_short_ids(body, type, num, year, &_block)
      short_type = SHORTTYPE[type]
      id = "#{body} #{short_type}"
      id += " #{num}" if num.to_i.positive?

      short = "#{id} (#{year})"
      yield make_docid(content: short, type: "BIPM", primary: true)

      en = "#{id} (#{year}, E)"
      yield make_docid(content: en, type: "BIPM", primary: true, language: "en", script: "Latn")

      fr = "#{id} (#{year}, F)"
      yield make_docid(content: fr, type: "BIPM", primary: true, language: "fr", script: "Latn")
    end

    def resolution_long_ids(body, type, num, year, &_block)
      en = "#{body} #{type}"
      en += " #{num}" if num.to_i.positive?
      en += " (#{year})"
      yield make_docid content: en, type: "BIPM-long", language: "en", script: "Latn"

      fr = resolution_fr_long_id(body, type, num, year)
      yield make_docid content: fr, type: "BIPM-long", language: "fr", script: "Latn"

      yield make_docid(content: "#{en} / #{fr}", type: "BIPM-long")
    end

    def resolution_fr_long_id(body, type, num, year)
      fr = TRANSLATIONS[type] || type
      if special_id_case? body, type, year
        fr += " #{body}"
        fr += "/#{num}" if num.to_i.positive?
      else
        fr += " #{num}" if num.to_i.positive?
        fr += body == "CGPM" ? " de la" : " du"
        fr += " #{body}"
      end
      "#{fr} (#{year})"
    end

    def create_meeting_docids(en_id)
      fr_id = en_id.sub(/(\d+)(?:st|nd|rd|th)/, '\1e').sub("Meeting", "réunion")
      fr_id_sup = fr_id.sub(/(\d+)(e)/, '\1<sup>\2</sup>')
      result = [
        make_docid(content: en_id, type: "BIPM", primary: true, language: "en", script: "Latn"),
        make_docid(content: fr_id_sup, type: "BIPM", primary: true, language: "fr", script: "Latn"),
        make_docid(content: "#{en_id} / #{fr_id_sup}", type: "BIPM", primary: true),
      ]
      @data_fetcher.errors[:meeting_docidentifier] &&= result.empty?
      result
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
    # @return [Relaton::Bib::Docidentifier] Document ID
    #
    def make_docid(**args)
      Relaton::Bib::Docidentifier.new(**args)
    end
  end
end
