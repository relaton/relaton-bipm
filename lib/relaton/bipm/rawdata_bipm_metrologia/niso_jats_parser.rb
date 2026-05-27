require "niso-jats"

module Relaton::Bipm
  module RawdataBipmMetrologia
    class NisoJatsParser
      ATTRS = %i[docidentifier title contributor date copyright abstract relation series
                 extent type source ext].freeze

      # JATS inline phrasing children handled by #serialize_mixed_content
      INLINE_TYPES = %i[italic bold fixed_case monospace overline roman
                        sans_serif sc strike underline sub sup].freeze
      private_constant :INLINE_TYPES

      # @param [Niso::Jats::Article] doc document
      # @param [String] journal journal
      # @param [String] volume volume
      # @param [String] article article
      # @param [Hash] errors errors hash
      def initialize(doc, journal, volume, article, errors = {})
        @doc = doc
        @journal = journal
        @volume = volume
        @article = article
        @errors = errors
      end

      # @param [String] path path to XML file
      # @param [Hash] errors errors hash
      #
      # @return [Relaton::Bipm::ItemData] document
      def self.parse(path, errors = {})
        doc = Niso::Jats::Article.from_xml(File.read(path, encoding: "UTF-8"))
        journal, volume, article = path.split("/")[-2].split("_")[1..]
        new(doc, journal, volume, article, errors).parse
      end

      # @return [Relaton::Bipm::ItemData] document
      def parse
        attrs = ATTRS.to_h { |a| [a, send("parse_#{a}")] }
        ItemData.new(**attrs)
      end

      # @return [Array<Relaton::Bib::Docidentifier>] array of document identifiers
      def parse_docidentifier
        ids = [create_docidentifier(pubid, "BIPM", true)]
        ids << create_docidentifier(@doc.doi, "doi") if @doc.doi
        @errors[:article_docidentifier] &&= ids.empty?
        ids
      end

      # @return [String] primary BIPM publication identifier
      def pubid
        @pubid ||= "#{@doc.journal_title} #{volume_issue_article}"
      end

      # @return [String] volume issue page
      def volume_issue_article
        [@journal, @volume, @article].compact.join(" ")
      end

      # @return [Array<Relaton::Bib::Title>] array of title strings
      def parse_title
        title = @doc.front.article_meta.title_group.article_title
        result = [Relaton::Bib::Title.new(
          content: serialize_mixed_content(title), language: title.lang, script: "Latn",
        )]
        @errors[:article_title] &&= result.empty?
        result
      end

      # @return [Array<Relaton::Bib::Contributor>] array of contributors
      def parse_contributor
        result = @doc.contributors.map do |contrib|
          role = Relaton::Bib::Contributor::Role.new(type: contrib.contrib_type)
          attrs = { person: create_person(contrib), organization: create_organization(contrib), role: [role] }
          Relaton::Bib::Contributor.new(**attrs)
        end
        @errors[:article_contributor] &&= result.empty?
        result
      end

      # @return [Array<Relaton::Bib::Date>] array of dates
      def parse_date
        on = @doc.pub_dates.min
        @errors[:article_date] &&= on.nil?
        return [] unless on

        [Relaton::Bib::Date.new(type: "published", at: on)]
      end

      # @return [Array<Relaton::Bib::Copyright>] array of copyright associations
      def parse_copyright
        permissions = @doc.front.article_meta.permissions
        return [] unless permissions

        from = permissions.copyright_year.first
        return [] unless from

        owner = permissions.copyright_statement.inject([]) do |acc, cs|
          acc + Array(cs.content).join.split(" & ").map do |c|
            /(?<name>[A-Za-z]+(?:\s[A-Za-z]+)*)/ =~ c
            org_name = Relaton::Bib::TypedLocalizedString.new(content: name, language: "en", script: "Latn")
            org = Relaton::Bib::Organization.new name: [org_name]
            Relaton::Bib::ContributionInfo.new(organization: org)
          end
        end
        result = [Relaton::Bib::Copyright.new(owner: owner, from: from.content)]
        @errors[:article_copyright] &&= result.empty?
        result
      end

      # @return [Array<Relaton::Bib::Abstract>] array of abstracts
      def parse_abstract
        abstracts = @doc.front.article_meta.abstract
        return [] unless abstracts

        result = abstracts.filter_map do |a|
          content_parts = []
          content_parts << Array(a.title.content).join if a.title
          a.p&.each do |paragraph|
            content_parts << "<p>#{extract_paragraph_text(paragraph)}</p>"
          end
          next if content_parts.empty?

          Relaton::Bib::Abstract.new(
            content: content_parts.join, language: a.lang, script: "Latn",
          )
        end
        @errors[:article_abstract] &&= result.empty?
        result
      end

      def extract_paragraph_text(paragraph)
        serialize_mixed_content(paragraph)
      end

      # Reconstruct the marked-up string of a niso-jats mixed_content element
      # (Title, Paragraph, …) by walking element_order in document order.
      # Text nodes are emitted verbatim; recognised inline children are
      # wrapped in their original XML tag so JATS markup like <italic> and
      # <sub> survives into the relaton-bib payload instead of being
      # flattened (paragraphs) or serialised as a stringified Array (titles).
      def serialize_mixed_content(element)
        return "" unless element.respond_to?(:element_order) && element.element_order

        pools  = INLINE_TYPES.to_h { |t| [t, element.send(t).to_a.dup] }
        cursor = Hash.new(0)
        out    = []
        element.element_order.each do |el|
          case el.type
          when "Text"
            out << el.text_content
          when "Element"
            attr = el.name.tr("-", "_").to_sym
            next unless pools.key?(attr)

            inst = pools[attr][cursor[attr]]
            cursor[attr] += 1
            next unless inst.respond_to?(:content)

            inner = inst.content
            inner = inner.join if inner.is_a?(Array)
            out << "<#{el.name}>#{inner}</#{el.name}>"
          end
        end
        out.join
      end

      # @return [Array<Relaton::Bib::Relation>] array of document relations
      def parse_relation
        pub_dates = @doc.front.article_meta.pub_date
        rels = if pub_dates
                 pub_dates.sort_by { |pd| pd.pub_type == "ppub" ? 0 : 1 }.map do |pd|
                   type = pd.pub_type == "epub" ? "epub" : "ppub"
                   Relaton::Bib::Relation.new(type: "hasManifestation", bibitem: bibitem(pd, type))
                 end
               else
                 []
               end
        @errors[:article_relation] &&= rels.empty?
        rels
      end

      # @return [Array<Relaton::Bib::Series>] array of series
      def parse_series
        title = Relaton::Bib::Title.new(content: @doc.journal_title, language: "en", script: "Latn")
        [Relaton::Bib::Series.new(title: [title])]
      end

      # @return [Array<Relaton::Bib::Extent>] array of extents
      def parse_extent
        locality = @doc.locality.map { |e| Relaton::Bib::Locality.new(type: e[0], reference_from: e[1], reference_to: e[2]) }
        @errors[:article_extent] &&= locality.empty?
        return [] if locality.empty?

        [Relaton::Bib::Extent.new(locality: locality)]
      end

      def parse_type = "article"

      def parse_source
        result = @doc.doi_links.map { |link| Relaton::Bib::Uri.new(**link) }
        @errors[:article_source] &&= result.empty?
        result
      end

      def parse_ext = Ext.new(doctype: parse_doctype)

      def parse_doctype = Doctype.new(content: "article")

      private

      # @param [String] id document id
      # @param [String] type id type
      # @param [Boolean, nil] primary is primary id
      #
      # @return [Relaton::Bib::Docidentifier] document identifier
      def create_docidentifier(id, type, primary = nil)
        Relaton::Bib::Docidentifier.new content: id, type: type, primary: primary
      end

      def create_person(contrib)
        return unless contrib.name&.any?

        @errors[:article_contributor_person] &&= false
        fullname = fullname(contrib.name[0])
        Relaton::Bib::Person.new name: fullname, affiliation: affiliation(contrib)
      end

      def create_organization(contrib)
        return unless contrib.collab&.any?

        @errors[:article_contributor_organization] &&= false
        name = Relaton::Bib::TypedLocalizedString.new(content: contrib.collab.flat_map { |c| Array(c.content) }.join)
        Relaton::Bib::Organization.new name: [name]
      end

      # @param [Niso::Jats::Name] name name element
      #
      # @return [Relaton::Bib::FullName] full name
      def fullname(name)
        cname = [name.given_names, name.surname].compact.map(&:content).join(" ")
        @errors[:article_fullname] &&= cname.empty?
        return if cname.empty?

        completename = Relaton::Bib::LocalizedString.new content: cname, language: "en", script: "Latn"
        Relaton::Bib::FullName.new completename: completename
      end

      # @param [Niso::Jats::Contrib] contrib contributor element
      #
      # @return [Array<Relaton::Bib::Affiliation>] array of affiliations
      def affiliation(contrib)
        aff = contrib.aff_xrefs.filter_map do |xref|
          a = @doc.affiliation(xref.rid)
          parse_affiliation(a[0]) if a.any?
        end
        @errors[:article_affiliation] &&= aff.empty?
        aff
      end

      def parse_affiliation(aff) # rubocop:disable Metrics/MethodLength
        div, addr = division_address(aff)
        return if addr.include?("Permanent address:") || addr == "Germany" ||
          addr.start_with?("Guest") || addr.start_with?("Deceased") ||
          addr.include?("Author to whom any correspondence should be addressed")

        args = {}
        institutions = aff.institution || []
        if institutions.any?
          name = Array(institutions[0].content).join
          return if name == "1005 Southover Lane"

          args[:subdivision] = parse_division(div) if div
          args[:address] = parse_address(aff, addr)
        else
          name = div
        end
        args[:name] = [Relaton::Bib::TypedLocalizedString.new(content: name)]
        org = Relaton::Bib::Organization.new(**args)
        Relaton::Bib::Affiliation.new(organization: org)
      end

      def division_address(aff)
        div_addr = aff.content.map do |c|
          CGI.unescapeHTML(c.strip.gsub(/^\W*|\W*$/, ""))
        end.reject(&:empty?)

        institutions = aff.institution || []
        if div_addr.size > 1 && institutions.any?
          # Multiple text nodes around institution: first ones are division, last is address
          div = div_addr[0..-2].join(", ")
          addr = div_addr[-1]
        elsif institutions.any?
          # Single text node with institution: no division text, it's all address
          div = nil
          addr = div_addr[0] || ""
        else
          # No institution: the whole text is the organization name; no address split
          joined = div_addr.join(", ")
          div = joined.empty? ? nil : joined
          addr = ""
        end
        [div, addr]
      end

      def parse_division(div)
        @errors[:article_affiliation_division] &&= div.empty?
        return [] if div.empty?

        name = Relaton::Bib::TypedLocalizedString.new(content: div, language: "en", script: "Latn")
        [Relaton::Bib::Subdivision.new(name: [name])]
      end

      def parse_address(_aff, addr)
        address = []
        address << addr unless addr.empty?
        # niso-jats parses country into aff.country but we fold it into the formatted address
        @errors[:article_affiliation_address] &&= address.empty?
        return [] if address.empty?

        [Relaton::Bib::Address.new(formatted_address: address.join(", "))]
      end

      # @param [Niso::Jats::PubDate] pd pub date object
      # @param [String] type date type
      #
      # @return [Relaton::Bipm::ItemData] bibitem
      def bibitem(pd, type)
        dt = Relaton::Bib::Date.new(type: type, at: format_pub_date(pd))
        carrier = type == "epub" ? "online" : "print"
        medium = Relaton::Bib::Medium.new carrier: carrier
        fref = Relaton::Bib::Formattedref.new(content: pubid)
        docid = [create_docidentifier(pubid, "BIPM", true)]
        ItemData.new(formattedref: fref, docidentifier: docid, date: [dt], medium: medium)
      end

      def format_pub_date(pd)
        year = pd.year&.content
        return nil unless year&.match?(/\A\d{1,4}\z/)

        parts = [year.rjust(4, "0")]
        month = pd.month&.content
        if month&.match?(/\A\d{1,2}\z/)
          parts << month.rjust(2, "0")
          day = pd.day&.content
          parts << day.rjust(2, "0") if day&.match?(/\A\d{1,2}\z/)
        end
        parts.join("-")
      end
    end
  end
end
