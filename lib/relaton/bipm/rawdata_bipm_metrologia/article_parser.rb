module Relaton::Bipm
  module RawdataBipmMetrologia
    class ArticleParser
      ATTRS = %i[docidentifier title contributor date copyright abstract relation series
                 extent type source ext].freeze
      #
      # Create new parser and parse document
      #
      # @param [String] path path to XML file
      #
      # @return [Relaton::Bipm::ItemDate] document
      #
      def self.parse(path, errors = {})
        doc = Nokogiri::XML(File.read(path, encoding: "UTF-8"))
        journal, volume, article = path.split("/")[-2].split("_")[1..]
        new(doc, journal, volume, article, errors).parse
      end

      #
      # Initialize parser
      #
      # @param [Nokogiri::XML::Document] doc XML document
      # @param [String] journal journal
      # @param [String] volume volume
      # @param [String] article article
      # @param [Hash] errors errors hash
      #
      def initialize(doc, journal, volume, article, errors = {})
        @doc = doc.at "/article"
        @journal = journal
        @volume = volume
        @article = article
        @meta = doc.at("/article/front/article-meta")
        @errors = errors
      end

      #
      # Create new document
      #
      # @return [Relaton::Bipm::ItemData] document
      #
      def parse
        attrs = ATTRS.to_h { |a| [a, send("parse_#{a}")] }
        ItemData.new(**attrs)
      end

      #
      # Parse docid
      #
      # @return [Array<Relaton::Bib::DocumentIdentifier>] array of document identifiers
      #
      def parse_docidentifier
        primary_id = create_docidentifier pubid, "BIPM", true
        result = @meta.xpath("./article-id[@pub-id-type='doi']").each_with_object([primary_id]) do |id, m|
          m << create_docidentifier(id.text, id["pub-id-type"])
        end
        @errors[:article_docidentifier] &&= result.empty?
        result
      end

      #
      # Build primary publication identifier string (e.g. "Metrologia 55 1 125")
      #
      # @return [String] pubid
      #
      def pubid
        @pubid ||= "#{journal_title} #{volume_issue_article}"
      end

      #
      # Parse volume, issue and page
      #
      # @return [String] volume issue page
      #
      def volume_issue_article
        [@journal, @volume, @article].compact.join(" ")
      end

      # def article
      #   @meta.at("./article-id[@pub-id-type='manuscript']").text.match(/[^_]+$/).to_s
      # end

      #
      # Parse journal title
      #
      # @return [String] journal title
      #
      def journal_title
        return @journal_title if defined? @journal_title

        @journal_title = @doc.at("./front/journal-meta/journal-title-group/journal-title")&.text
        @errors[:journal_title] &&= @journal_title.nil? || @journal_title.empty?
        @journal_title
      end

      #
      # Create document identifier
      #
      # @param [String] id document id
      # @param [String] type id type
      # @param [Boolean, nil] primary is primary id
      #
      # @return [Relaton::Bib::Docidentifier] document identifier
      #
      def create_docidentifier(id, type, primary = nil)
        Relaton::Bib::Docidentifier.new content: id, type: type, primary: primary
      end

      #
      # Parse title
      #
      # @return [Array<Relaton::Bib::TypedTitleString>] array of title strings
      #
      def parse_title
        result = @meta.xpath("./title-group/article-title").map do |t|
          next if t.text.empty?

          Relaton::Bib::Title.new(content: t.inner_html, language: t[:"xml:lang"], script: "Latn")
        end.compact
        @errors[:article_title] &&= result.empty?
        result
      end

      #
      # Parse contributor
      #
      # @return [Array<Relaton::Bib::Contributor>] array of contributors
      #
      def parse_contributor
        result = @meta.xpath("./contrib-group/contrib").map do |c|
          role = Relaton::Bib::Contributor::Role.new(type: c[:"contrib-type"])
          attrs = { person: create_person(c), organization: create_organization(c), role: [role] }
          Relaton::Bib::Contributor.new(**attrs)
        end
        @errors[:article_contributor] &&= result.empty?
        result
      end

      def create_person(contrib)
        name = contrib.at("./name")
        @errors[:article_contributor_person] &&= name.nil? || name.text.empty?
        return if name.nil? || name.text.empty?

        Relaton::Bib::Person.new name: fullname(name), affiliation: affiliation(contrib)
      end

      def create_organization(contrib)
        org = contrib.at("./collab")
        @errors[:article_contributor_organization] &&= org.nil? || org.text.empty?
        return if org.nil? || org.text.empty?

        name = Relaton::Bib::TypedLocalizedString.new(content: org.text)
        Relaton::Bib::Organization.new name: [name]
      end

      #
      # Parse affiliations
      #
      # @param [Nokogiri::XML::Element] contrib contributor element
      #
      # @return [Array<Relaton::Bib::Affiliation>] array of affiliations
      #
      def affiliation(contrib)
        aff = contrib.xpath("./xref[@ref-type='aff']").map do |x|
          a = @meta.at("./contrib-group/aff[@id='#{x[:rid]}']") # /label/following-sibling::node()")
            parse_affiliation a
        end.compact
        @errors[:article_affiliation] &&= aff.empty?
        aff
      end

      def parse_affiliation(aff)
        text = aff.xpath("text()|sup|sub").to_xml.split(",").map(&:strip).reject(&:empty?).join(", ")
        text = CGI::unescapeHTML(text)
        return if text.include?("Permanent address:") || text == "Germany" ||
          text.start_with?("Guest") || text.start_with?("Deceased") ||
          text.include?("Author to whom any correspondence should be addressed")

        args = {}
        institution = aff.at('institution')
        if institution
          name = institution.text
          return if name == "1005 Southover Lane"

          args[:subdivision] = parse_division(aff)
          args[:address] = parse_address(aff)
        else
          name = text
        end
        args[:name] = [Relaton::Bib::TypedLocalizedString.new(content: name)]
        org = Relaton::Bib::Organization.new(**args)
        Relaton::Bib::Affiliation.new(organization: org)
      end

      def parse_division(aff)
        div = aff.xpath("text()[following-sibling::institution]").text.gsub(/^\W*|\W*$/, "")
        @errors[:article_affiliation_division] &&= div.empty?
        return [] if div.empty?

        name = Relaton::Bib::TypedLocalizedString.new(content: div, language: "en", script: "Latn")
        [Relaton::Bib::Subdivision.new(name: [name])]
      end

      def parse_address(aff)
        address = []
        addr = aff.xpath("text()[preceding-sibling::institution]").text.gsub(/^\W*|\W*$/, "")
        address << addr unless addr.empty?
        country = aff.at('country')
        address << country.text if country && !country.text.empty?
        address = address.join(", ")
        @errors[:article_affiliation_address] &&= address.empty?
        return [] if address.empty?

        [Relaton::Bib::Address.new(formatted_address: address)]
      end

      #
      # Create full name
      #
      # @param [Nokogiri::XML::Element] contrib contributor element
      #
      # @return [Relaton::Bib::FullName] full name
      #
      def fullname(name)
        cname = [name.at("./given-names"), name.at("./surname")].compact.map(&:text).join(" ")
        @errors[:article_fullname] &&= cname.empty?
        return if cname.empty?

        completename = Relaton::Bib::LocalizedString.new content: cname, language: "en", script: "Latn"
        Relaton::Bib::FullName.new completename: completename
      end

      #
      # Parse forename
      #
      # @param [String] given_name given name
      #
      # @return [Array<Relaton::Bib::Forename>] array of forenames
      #
      # def forename(given_name) # rubocop:disable Metrics/MethodLength
      #   return [] unless given_name

      #   given_name.text.scan(/(\w+)(?:\s(\w)(?:\s|$))?/).map do |nm, int|
      #     if nm.size == 1
      #       name = nil
      #       init = nm
      #     else
      #       name = nm
      #       init = int
      #     end
      #     Relaton::Bib::Forename.new(content: name, language: ["en"], script: ["Latn"], initial: init)
      #   end
      # end

      #
      # Parse date
      #
      # @return [Array<Relaton::Bib::Date>] array of dates
      #
      def parse_date
        at = dates.min
        @errors[:article_date] &&= at.nil?
        return [] unless at

        [Relaton::Bib::Date.new(type: "published", at: at)]
      end

      #
      # Parse date
      #
      # @yield [date, type] date and type
      #
      # @return [Array<String, Object>] string date or whatever block returns
      #
      def dates
        @meta.xpath("./pub-date").map do |d|
          month = date_part(d, "month")
          day = date_part(d, "day")
          date = "#{d.at('./year').text}-#{month}-#{day}"
          block_given? ? yield(date, d[:"pub-type"]) : date
        end
      end

      def date_part(date, type)
        part = date.at("./#{type}")&.text
        return "01" if part.nil? || part.empty?

        part.rjust(2, "0")
      end

      #
      # Parse copyright
      #
      # @return [Array<Relaton::Bib::Copyright>] array of copyright associations
      #
      def parse_copyright
        result = @meta.xpath("./permissions").each_with_object([]) do |l, m|
          from = l.at("./copyright-year")
          next unless from

          owner = l.at("./copyright-statement").text.split(" & ").map do |c|
            /(?<name>\p{L}+(?:\s\p{L}+)*)/ =~ c
            org_name = Relaton::Bib::TypedLocalizedString.new(content: name, language: "en", script: "Latn")
            org = Relaton::Bib::Organization.new name: [org_name]
            Relaton::Bib::ContributionInfo.new(organization: org)
          end
          m << Relaton::Bib::Copyright.new(owner: owner, from: from.text)
        end
        @errors[:article_copyright] &&= result.empty?
        result
      end

      #
      # Parse abstract
      #
      # @return [Array<Relaton::Bib::LocalizedMarkedUpString>] array of abstracts
      #
      def parse_abstract
        result = @meta.xpath("./abstract").map do |a|
          Relaton::Bib::Abstract.new(
            content: a.inner_html, language: a[:"xml:lang"], script: "Latn",
          )
        end
        @errors[:article_abstract] &&= result.empty?
        result
      end

      #
      # Parese relation
      #
      # @return [Array<Relaton::Bib::Relation>] array of document relations
      #
      def parse_relation
        rels = dates do |d, t|
          Relaton::Bib::Relation.new(type: "hasManifestation", bibitem: bibitem(d, t))
        end
        @errors[:article_relation] &&= rels.empty?
        rels + parse_references
      end

      #
      # Parse back/ref-list references as "cites" relations
      #
      # @return [Array<Relaton::Bib::Relation>] array of "cites" relations
      #
      def parse_references
        refs = @doc.xpath("./back/ref-list/ref").filter_map do |ref|
          citation = ref.at("./element-citation")
          next unless citation

          Relaton::Bib::Relation.new(type: "cites", bibitem: citation_bibitem(citation))
        end
        @errors[:article_references] &&= refs.empty?
        refs
      end

      #
      # Build bibitem from an element-citation
      #
      # @param [Nokogiri::XML::Element] citation element-citation node
      #
      # @return [Relaton::Bipm::ItemData] bibitem
      #
      def citation_bibitem(citation)
        attrs = {}
        doi = citation.at("./pub-id[@pub-id-type='doi']")&.text
        if doi && !doi.empty?
          @errors[:article_citation_doi] &&= false
          attrs[:docidentifier] = [Relaton::Bib::Docidentifier.new(content: doi, type: "doi")]
          attrs[:source] = [Relaton::Bib::Uri.new(content: "https://doi.org/#{doi}", type: "doi")]
        else
          @errors[:article_citation_doi] &&= true
        end
        source = citation.at("./source")&.text
        if source && !source.empty?
          @errors[:article_citation_title] &&= false
          attrs[:title] = [Relaton::Bib::Title.new(content: source)]
        else
          @errors[:article_citation_title] &&= true
        end
        year = citation.at("./year")&.text
        if year && !year.empty?
          @errors[:article_citation_date] &&= false
          attrs[:date] = [Relaton::Bib::Date.new(type: "published", at: year)]
        else
          @errors[:article_citation_date] &&= true
        end
        ItemData.new(**attrs)
      end

      #
      # Create bibitem
      #
      # @param [String] date
      # @param [String] type date type
      #
      # @return [Relaton::Bipm::BipmBibliographicItem] bibitem
      #
      def bibitem(date, type)
        dt = Relaton::Bib::Date.new(type: type, at: date)
        carrier = type == "epub" ? "online" : "print"
        medium = Relaton::Bib::Medium.new carrier: carrier
        fref = Relaton::Bib::Formattedref.new(content: pubid)
        docid = [create_docidentifier(pubid, "BIPM", true)]
        ItemData.new(formattedref: fref, docidentifier: docid, date: [dt], medium: medium)
      end

      #
      # Parse series
      #
      # @return [Array<Relaton::Bib::Series>] array of series
      #
      def parse_series
        title = Relaton::Bib::Title.new(content: journal_title, language: "en", script: "Latn")
        [Relaton::Bib::Series.new(title: [title])]
      end

      #
      # Parse extent
      #
      # @return [Array<Relaton::Bib::Extent>] array of extents
      #
      def parse_extent
        locs = @meta.xpath("./volume|./issue|./fpage").map do |e|
          if e.name == "fpage"
            type = "page"
            to = @meta.at("./lpage")&.text
          else
            type = e.name
          end
          Relaton::Bib::Locality.new type: type, reference_from: e.text, reference_to: to
        end
        @errors[:article_extent] &&= locs.empty?
        return [] if locs.empty?

        [Relaton::Bib::Extent.new(locality: locs)]
      end

      def parse_type = "article"

      def parse_source
        result = @meta.xpath("./article-id[@pub-id-type='doi']").each_with_object([]) do |l, a|
          url = "https://doi.org/#{l.text}"
          a << Relaton::Bib::Uri.new(content: url, type: "src")
          a << Relaton::Bib::Uri.new(content: url, type: "doi")
        end
        @errors[:article_source] &&= result.empty?
        result
      end

      def parse_ext = Ext.new(doctype: parse_doctype)

      def parse_doctype = Doctype.new(content: "article")
    end
  end
end
