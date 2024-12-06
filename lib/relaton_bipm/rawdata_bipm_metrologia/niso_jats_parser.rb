require "niso-jats"

module RelatonBipm
  module RawdataBipmMetrologia
    class NisoJatsParser
      ATTRS = %i[docid title contributor date copyright abstract relation series
                 extent type doctype link].freeze

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
        @doc.title.map { |args| RelatonBib::TypedTitleString.new(**args) }
      end

      #
      # Parse contributor
      #
      # @return [Array<RelatonBib::Contributor>] array of contributors
      #
      def parse_contributor
        @doc.contributor.map do |contrib|
          entity = create_person(contrib) || create_organization(contrib)
          RelatonBib::ContributionInfo.new(entity: entity, role: [type: contrib.contrib_type])
        end
      end

      #
      # Parse date
      #
      # @return [Array<RelatonBib::BibliographicDate>] array of dates
      #
      def parse_date
        on = @doc.date.min
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
            /(?<name>[A-z]+(?:\s[A-z]+)*)/ =~ c
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
        @doc.front.article_meta.abstract.map do |a|
          RelatonBib::FormattedString.new(
            content: a.inner_html, language: a[:"xml:lang"], script: ["Latn"], format: "text/html",
          )
        end
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
        return unless contrib.name.any?

        RelatonBib::Person.new name: fullname(contrib.name[0]), affiliation: affiliation(contrib)
      end

      def create_organization(contrib)
        RelatonBib::Organization.new name: contrib.collab
      end

      #
      # Create full name
      #
      # @param [Nokogiri::XML::Element] contrib contributor element
      #
      # @return [RelatonBib::FullName] full name
      #
      def fullname(name)
        cname = [name.given_names, name.surname].compact.map(&:content).join(" ")
        completename = RelatonBib::LocalizedString.new cname, "en", "Latn"
        RelatonBib::FullName.new completename: completename
      end


      #
      # Parse affiliations
      #
      # @param [Nokogiri::XML::Element] contrib contributor element
      #
      # @return [Array<RelatonBib::Affiliation>] array of affiliations
      #
      def affiliation(contrib)
        contrib.aff_xref.map do |xref|
          aff = @doc.affiliation(xref.rid)
          parse_affiliation aff[0] if aff.any?
        end.compact
      end

      def parse_affiliation(aff)
        div, addr = division_address aff
        return if addr.include?("Permanent address:") || addr == "Germany" ||
          addr.start_with?("Guest") || addr.start_with?("Deceased") ||
          addr.include?("Author to whom any correspondence should be addressed")

        args = {}
        if aff.institution.any?
          name = aff.institution[0].content
          return if name == "1005 Southover Lane"

          args[:subdivision] = parse_division(div) if div
          args[:contact] = parse_address(aff, addr)
        else
          name = text
        end
        args[:name] = [RelatonBib::LocalizedString.new(name)]
        org = RelatonBib::Organization.new(**args)
        RelatonBib::Affiliation.new(organization: org)
      end

      def division_address(aff)
        div_addr = aff.content.map do |c|
          CGI::unescapeHTML c.strip.gsub(/^\W*|\W*$/, "")
        end.reject(&:empty?)

        if div_addr.size > 1 && aff.institution.any?
          div = div_addr[0..-2].join(", ")
          addr = div_addr[-1]
        else
          div = nil
          addr = div_addr[0]
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
    end
  end
end
