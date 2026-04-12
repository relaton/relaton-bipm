require "date"
require "niso-jats"

module RelatonBipm
  module RawdataBipmMetrologia
    class NisoJatsParser
      ATTRS = %i[docid title contributor date copyright abstract relation
                 series extent type doctype link].freeze

      #
      # @param [Niso::Jats::Article] doc document
      # @param [String] journal journal
      # @param [String] volume volume
      # @param [String] article article
      #
      def initialize(doc, journal, volume, article)
        @doc = doc
        @journal = journal
        @volume = volume
        @article = article
      end

      #
      # @param [String] path path to XML file
      #
      # @return [RelatonBipm::BipmBibliographicItem] document
      #
      def self.parse(path)
        doc = Niso::Jats::Article.from_xml(File.read(path, encoding: "UTF-8"))
        journal, volume, article = path.split("/")[-2].split("_")[1..]
        new(doc, journal, volume, article).parse
      end

      #
      # @return [RelatonBipm::BipmBibliographicItem] document
      #
      def parse
        attrs = ATTRS.to_h { |a| [a, send("parse_#{a}")] }
        BipmBibliographicItem.new(**attrs)
      end

      #
      # @return [Array<RelatonBib::DocumentIdentifier>] array of document identifiers
      #
      def parse_docid
        pubid = "#{@doc.journal_title} #{volume_issue_article}"
        ids = [create_docid(pubid, "BIPM", true)]
        ids << create_docid(@doc.doi, "doi") if @doc.doi
        ids
      end

      #
      # @return [String] volume issue page
      #
      def volume_issue_article
        [@journal, @volume, @article].compact.join(" ")
      end

      #
      # @return [Array<RelatonBib::TypedTitleString>] array of title strings
      #
      def parse_title
        title = @doc.front.article_meta.title_group.article_title
        [RelatonBib::TypedTitleString.new(content: title.content,
                                          language: [title.lang], script: ["Latn"])]
      end

      #
      # Parse contributor
      #
      # @return [Array<RelatonBib::Contributor>] array of contributors
      #
      def parse_contributor
        @doc.contributors.map do |contrib|
          entity = create_person(contrib) || create_organization(contrib)
          RelatonBib::ContributionInfo.new(entity: entity,
                                           role: [{ type: contrib.contrib_type }])
        end
      end

      #
      # Parse date
      #
      # @return [Array<RelatonBib::BibliographicDate>] array of dates
      #
      def parse_date
        on = @doc.pub_dates.min
        [RelatonBib::BibliographicDate.new(type: "published", on: on)]
      end

      #
      # Parse copyright
      #
      # @return [Array<RelatonBib::CopyrightAssociation>] array of copyright associations
      #
      def parse_copyright
        permissions = @doc.front.article_meta.permissions
        return [] unless permissions

        from = permissions.copyright_year.first
        return [] unless from

        owner = permissions.copyright_statement.inject([]) do |acc, cs|
          acc + cs.content.split(" & ").map do |c|
            /(?<name>[A-Za-z]+(?:\s[A-Za-z]+)*)/ =~ c
            org = RelatonBib::Organization.new name: name
            RelatonBib::ContributionInfo.new(entity: org)
          end
        end
        [RelatonBib::CopyrightAssociation.new(owner: owner, from: from.content)]
      end

      #
      # Parse abstract
      #
      # @return [Array<RelatonBib::FormattedString>] array of abstracts
      #
      def parse_abstract
        abstracts = @doc.front.article_meta.abstract
        return [] unless abstracts

        abstracts.filter_map do |a|
          content_parts = []
          content_parts << a.title.content if a.title
          a.p&.each do |paragraph|
            content_parts << "<p>#{extract_paragraph_text(paragraph)}</p>"
          end
          next if content_parts.empty?

          RelatonBib::FormattedString.new(
            content: content_parts.join, language: a.lang, script: ["Latn"], format: "text/html",
          )
        end
      end

      def extract_paragraph_text(paragraph)
        return "" unless paragraph.respond_to?(:element_order) && paragraph.element_order

        # Build a map of inline element types to their instances
        inline_types = %i[italic bold fixed_case monospace overline roman
                          sans_serif sc strike underline sub sup]
        inline_instances = {}
        inline_types.each do |type|
          inline_instances[type] = paragraph.send(type).to_a.dup
        end

        # Track current index for each inline type
        inline_indices = Hash.new(0)

        # Iterate through element_order to build text in proper sequence
        result = []
        paragraph.element_order.each do |el|
          case el.type
          when "Text"
            result << el.text_content
          when "Element"
            type = el.name.to_sym
            if inline_instances.key?(type) && !inline_instances[type].empty?
              instances = inline_instances[type]
              instance = instances[inline_indices[type]]
              inline_indices[type] += 1
              if instance.respond_to?(:content)
                content = instance.content
                content = content.join if content.is_a?(Array)
                result << content
              end
            end
          end
        end

        result.join
      end

      #
      # Parese relation
      #
      # @return [Array<RelatonBib::DocumentRelation>] array of document relations
      #
      def parse_relation
        pub_dates = @doc.front.article_meta.pub_date
        return [] unless pub_dates

        pub_dates.sort_by { |pd| pd.pub_type == "ppub" ? 0 : 1 }.map do |pd|
          type = pd.pub_type == "epub" ? "epub" : "ppub"
          RelatonBib::DocumentRelation.new(type: "hasManifestation",
                                           bibitem: bibitem(
                                             pd, type
                                           ))
        end
      end

      #
      # Parse series
      #
      # @return [Array<RelatonBib::Series>] array of series
      #
      def parse_series
        title = RelatonBib::TypedTitleString.new(content: @doc.journal_title,
                                                 language: ["en"], script: ["Latn"])
        [RelatonBib::Series.new(title: title)]
      end

      #
      # Parse extent
      #
      # @return [Array<RelatonBib::Extent>] array of extents
      #
      def parse_extent
        locality = @doc.locality.map { |e| RelatonBib::Locality.new(*e) }
        return [] if locality.empty?

        [RelatonBib::Extent.new(locality)]
      end

      def parse_type
        "article"
      end

      def parse_doctype
        DocumentType.new type: "article"
      end

      def parse_link
        @doc.doi_links
      end

      private

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

      def create_person(contrib)
        return unless contrib.name&.any?

        RelatonBib::Person.new name: fullname(contrib.name[0]),
                               affiliation: affiliation(contrib)
      end

      def create_organization(contrib)
        RelatonBib::Organization.new name: contrib.collab.map(&:content)
      end

      #
      # Create full name
      #
      # @param [Niso::Jats::Name] name name element
      #
      # @return [RelatonBib::FullName] full name
      #
      def fullname(name)
        cname = [name.given_names,
                 name.surname].compact.map(&:content).join(" ")
        completename = RelatonBib::LocalizedString.new cname, "en", "Latn"
        RelatonBib::FullName.new completename: completename
      end

      #
      # Parse affiliations
      #
      # @param [Niso::Jats::Contrib] contrib contributor element
      #
      # @return [Array<RelatonBib::Affiliation>] array of affiliations
      #
      def affiliation(contrib)
        contrib.aff_xrefs.filter_map do |xref|
          aff = @doc.affiliation(xref.rid)
          parse_affiliation(aff[0]) if aff.any?
        end
      end

      def parse_affiliation(aff)
        div, addr = division_address(aff)
        return if addr.include?("Permanent address:") || addr == "Germany" ||
          addr.start_with?("Guest") || addr.start_with?("Deceased") ||
          addr.include?("Author to whom any correspondence should be addressed")

        args = {}
        institutions = aff.institution || []
        if institutions.any?
          name = institutions[0].content
          return if name == "1005 Southover Lane"

          args[:subdivision] = parse_division(div) if div
          args[:contact] = parse_address(aff, addr)
        else
          name = div
        end
        args[:name] = [RelatonBib::LocalizedString.new(name)]
        org = RelatonBib::Organization.new(**args)
        RelatonBib::Affiliation.new(organization: org)
      end

      def division_address(aff)
        div_addr = aff.content.map do |c|
          CGI::unescapeHTML(c.strip.gsub(/^\W*|\W*$/, ""))
        end.reject(&:empty?)

        institutions = aff.institution || []
        if div_addr.size > 1 && institutions.any?
          div = div_addr[0..-2].join(", ")
          addr = div_addr[-1]
        else
          div_addr = div_addr[0].split(",").map(&:strip)
          div = div_addr[0]
          addr = div_addr[1..].join(", ")
        end
        [div, addr]
      end

      def parse_division(div)
        # div = aff.xpath("text()[following-sibling::institution]").text.gsub(/^\W*|\W*$/, "")
        return [] if div.empty?

        [RelatonBib::LocalizedString.new(div)]
      end

      def parse_address(aff, addr)
        address = []
        # addr = aff.xpath("text()[preceding-sibling::institution]").text.gsub(/^\W*|\W*$/, "")
        address << addr unless addr.empty?
        address << aff.country[0].content if aff.country.any?
        # address = address.join(", ")
        return [] if address.empty?

        [RelatonBib::Address.new(formatted_address: address.join(", "))]
      end

      #
      # Create bibitem
      #
      # @param [Niso::Jats::PubDate] pd pub date object
      # @param [String] type date type
      #
      # @return [RelatonBipm::BipmBibliographicItem] bibitem
      #
      def bibitem(pd, type)
        dt = RelatonBib::BibliographicDate.new(type: type,
                                               on: format_pub_date(pd))
        carrier = type == "epub" ? "online" : "print"
        medium = RelatonBib::Medium.new carrier: carrier
        BipmBibliographicItem.new title: parse_title, date: [dt], medium: medium
      end

      def format_pub_date(pd)
        year = pd.year&.content&.to_i
        month = pd.month&.content&.to_i
        day = pd.day&.content&.to_i
        Date.new(year, month, day).iso8601
      rescue ArgumentError, NoMethodError
        nil
      end
    end
  end
end
