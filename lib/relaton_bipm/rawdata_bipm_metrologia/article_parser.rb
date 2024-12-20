module RelatonBipm
  module RawdataBipmMetrologia
    class ArticleParser
      ATTRS = %i[docid title contributor date copyright abstract relation series
                 extent type doctype link].freeze
      #
      # Create new parser and parse document
      #
      # @param [String] path path to XML file
      #
      # @return [RelatonBipm::BipmBibliographicItem] document
      #
      def self.parse(path)
        doc = Nokogiri::XML(File.read(path, encoding: "UTF-8"))
        journal, volume, article = path.split("/")[-2].split("_")[1..]
        new(doc, journal, volume, article).parse
      end

      #
      # Initialize parser
      #
      # @param [Nokogiri::XML::Document] doc XML document
      # @param [String] journal journal
      # @param [String] volume volume
      # @param [String] article article
      #
      def initialize(doc, journal, volume, article)
        @doc = doc.at "/article"
        @journal = journal
        @volume = volume
        @article = article
        @meta = doc.at("/article/front/article-meta")
      end

      #
      # Create new document
      #
      # @return [RelatonBipm::BipmBibliographicItem] document
      #
      def parse
        attrs = ATTRS.to_h { |a| [a, send("parse_#{a}")] }
        BipmBibliographicItem.new(**attrs)
      end

      #
      # Parse docid
      #
      # @return [Array<RelatonBib::DocumentIdentifier>] array of document identifiers
      #
      def parse_docid
        pubid = "#{journal_title} #{volume_issue_article}"
        primary_id = create_docid pubid, "BIPM", true
        @meta.xpath("./article-id[@pub-id-type='doi']")
          .each_with_object([primary_id]) do |id, m|
          m << create_docid(id.text, id["pub-id-type"])
        end
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
        @doc.at("./front/journal-meta/journal-title-group/journal-title").text
      end

      #
      # Create document identifier
      #
      # @param [String] id document id
      # @param [String] type id type
      # @param [Boolean, nil] primary is primary id
      #
      # @return [RelatonBib::DocumentIdentifier] document identifier
      #
      def create_docid(id, type, primary = nil)
        RelatonBib::DocumentIdentifier.new id: id, type: type, primary: primary
      end

      #
      # Parse title
      #
      # @return [Array<RelatonBib::TypedTitleString>] array of title strings
      #
      def parse_title
        @meta.xpath("./title-group/article-title").map do |t|
          next if t.text.empty?

          format = CGI.escapeHTML(t.inner_html) == t.inner_html ? "text/plain" : "text/html"
          RelatonBib::TypedTitleString.new(
            content: t.inner_html, language: t[:"xml:lang"], script: "Latn", format: format,
          )
        end.compact
      end

      #
      # Parse contributor
      #
      # @return [Array<RelatonBib::Contributor>] array of contributors
      #
      def parse_contributor
        @meta.xpath("./contrib-group/contrib").map do |c|
          entity = create_person(c) || create_organization(c)
          RelatonBib::ContributionInfo.new(entity: entity, role: [type: c[:"contrib-type"]])
        end
      end

      def create_person(contrib)
        name = contrib.at("./name")
        return unless name

        RelatonBib::Person.new name: fullname(name), affiliation: affiliation(contrib)
      end

      def create_organization(contrib)
        RelatonBib::Organization.new name: contrib.at("./collab").text
      end

      #
      # Parse affiliations
      #
      # @param [Nokogiri::XML::Element] contrib contributor element
      #
      # @return [Array<RelatonBib::Affiliation>] array of affiliations
      #
      def affiliation(contrib)
        contrib.xpath("./xref[@ref-type='aff']").map do |x|
          a = @meta.at("./contrib-group/aff[@id='#{x[:rid]}']") # /label/following-sibling::node()")
            parse_affiliation a
        end.compact
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
          args[:contact] = parse_address(aff)
        else
          name = text
        end
        args[:name] = [RelatonBib::LocalizedString.new(name)]
        org = RelatonBib::Organization.new(**args)
        RelatonBib::Affiliation.new(organization: org)
      end

      def parse_division(aff)
        div = aff.xpath("text()[following-sibling::institution]").text.gsub(/^\W*|\W*$/, "")
        return [] if div.empty?

        [RelatonBib::LocalizedString.new(div)]
      end

      def parse_address(aff)
        address = []
        addr = aff.xpath("text()[preceding-sibling::institution]").text.gsub(/^\W*|\W*$/, "")
        address << addr unless addr.empty?
        country = aff.at('country')
        address << country.text if country && !country.text.empty?
        address = address.join(", ")
        return [] if address.empty?

        [RelatonBib::Address.new(formatted_address: address)]
      end

      #
      # Create full name
      #
      # @param [Nokogiri::XML::Element] contrib contributor element
      #
      # @return [RelatonBib::FullName] full name
      #
      def fullname(name)
        cname = [name.at("./given-names"), name.at("./surname")].compact.map(&:text).join(" ")
        completename = RelatonBib::LocalizedString.new cname, "en", "Latn"
        RelatonBib::FullName.new completename: completename
      end

      #
      # Parse forename
      #
      # @param [String] given_name given name
      #
      # @return [Array<RelatonBib::Forename>] array of forenames
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
      #     RelatonBib::Forename.new(content: name, language: ["en"], script: ["Latn"], initial: init)
      #   end
      # end

      #
      # Parse date
      #
      # @return [Array<RelatonBib::BibliographicDate>] array of dates
      #
      def parse_date
        on = dates.min
        [RelatonBib::BibliographicDate.new(type: "published", on: on)]
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
      # @return [Array<RelatonBib::CopyrightAssociation>] array of copyright associations
      #
      def parse_copyright
        @meta.xpath("./permissions").each_with_object([]) do |l, m|
          from = l.at("./copyright-year")
          next unless from

          owner = l.at("./copyright-statement").text.split(" & ").map do |c|
            /(?<name>[A-z]+(?:\s[A-z]+)*)/ =~ c
            org = RelatonBib::Organization.new name: name
            RelatonBib::ContributionInfo.new(entity: org)
          end
          m << RelatonBib::CopyrightAssociation.new(owner: owner, from: from.text)
        end
      end

      #
      # Parse abstract
      #
      # @return [Array<RelatonBib::FormattedString>] array of abstracts
      #
      def parse_abstract
        @meta.xpath("./abstract").map do |a|
          RelatonBib::FormattedString.new(
            content: a.inner_html, language: a[:"xml:lang"], script: ["Latn"], format: "text/html",
          )
        end
      end

      #
      # Parese relation
      #
      # @return [Array<RelatonBib::DocumentRelation>] array of document relations
      #
      def parse_relation
        dates do |d, t|
          RelatonBib::DocumentRelation.new(type: "hasManifestation", bibitem: bibitem(d, t))
        end
      end

      #
      # Create bibitem
      #
      # @param [String] date
      # @param [String] type date type
      #
      # @return [RelatonBipm::BipmBibliographicItem] bibitem
      #
      def bibitem(date, type)
        dt = RelatonBib::BibliographicDate.new(type: type, on: date)
        carrier = type == "epub" ? "online" : "print"
        medium = RelatonBib::Medium.new carrier: carrier
        BipmBibliographicItem.new title: parse_title, date: [dt], medium: medium
      end

      #
      # Parse series
      #
      # @return [Array<RelatonBib::Series>] array of series
      #
      def parse_series
        title = RelatonBib::TypedTitleString.new(
          content: journal_title, language: ["en"], script: ["Latn"],
        )
        [RelatonBib::Series.new(title: title)]
      end

      #
      # Parse extent
      #
      # @return [Array<RelatonBib::Extent>] array of extents
      #
      def parse_extent
        locs = @meta.xpath("./volume|./issue|./fpage").map do |e|
          if e.name == "fpage"
            type = "page"
            to = @meta.at("./lpage")&.text
          else
            type = e.name
          end
          RelatonBib::Locality.new type, e.text, to
        end
        [RelatonBib::Extent.new(locs)]
        # %w[volume issue page].map.with_index do |t, i|
        #   RelatonBib::Locality.new t, volume_issue_page[i]
        # end
      end

      def parse_type
        "article"
      end

      def parse_doctype
        DocumentType.new type: "article"
      end

      def parse_link
        @meta.xpath("./article-id[@pub-id-type='doi']").each_with_object([]) do |l, a|
          url = "https://doi.org/#{l.text}"
          a << RelatonBib::TypedUri.new(content: url, type: "src")
          a << RelatonBib::TypedUri.new(content: url, type: "doi")
        end
      end
    end
  end
end
