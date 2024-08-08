module RelatonBipm
  class XMLParser < RelatonBib::XMLParser
    class << self
      private

      # Override RelatonBib::XMLParser.item_data method.
      # @param item [Nokogiri::XML::Element]
      # @returtn [Hash]
      def item_data(item)
        data = super
        ext = item.at "./ext"
        return data unless ext

        data[:comment_period] = fetch_commentperiond ext
        data[:si_aspect] = ext.at("si-aspect")&.text
        data[:meeting_note] = ext.at("meeting-note")&.text
        data
      end

      # @param item_hash [Hash]
      # @return [RelatonBipm::BipmBibliographicItem]
      def bib_item(item_hash)
        BipmBibliographicItem.new(**item_hash)
      end

      # def fetch_dates(item) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      #   item.xpath("./date").reduce([]) do |a, d|
      #     type = d[:type].to_s.empty? ? "published" : d[:type]
      #     if (on = d.at("on"))
      #       a << BibliographicDate.new(type: type, on: on.text,
      #                                  to: d.at("to")&.text)
      #     elsif (from = d.at("from"))
      #       a << BibliographicDate.new(type: type, from: from.text,
      #                                  to: d.at("to")&.text)
      #     end
      #   end
      # end

      # @param item [Nokogiri::XML::Element]
      # @param klass [RelatonBipm::DocumentRelation.class]
      # @return [Array<RelatonBipm::DocumentRelation>]
      def fetch_relations(item, klass = DocumentRelation)
        super
      end

      # @param ext [Nokogiri::XML::Element]
      # @return [RelatonBipm::CommentPeriod, nil]
      def fetch_commentperiond(ext)
        return unless ext && (cp = ext.at "comment-period")

        CommentPeriond.new from: cp.at("from")&.text, to: cp.at("to")&.text
      end

      # @param ext [Nokogiri::XML::Element]
      # @return [RelatonBipm::EditorialGroup, nil]
      def fetch_editorialgroup(ext) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        return unless ext && (eg = ext.at "editorialgroup")

        cm = eg.xpath("committee").map do |c|
          vars = variants c
          cnt = vars.any? ? vars : c.text
          args = c.to_h.transform_keys(&:to_sym).select { |k, _| %i[language script locale].include?(k) }
          Committee.new acronym: c[:acronym], content: cnt, **args
        end
        wg = eg.xpath("workgroup").map do |w|
          WorkGroup.new content: w.text, acronym: w[:acronym]
        end
        EditorialGroup.new committee: cm, workgroup: wg
      end

      # @param ext [Nokogiri::XML::Element]
      # @return [RelatonBipm::StructuredIdentifier]
      def fetch_structuredidentifier(ext)
        return unless ext && (sid = ext.at("structuredidentifier"))

        StructuredIdentifier.new(
          docnumber: sid.at("docnumber")&.text, part: sid.at("part")&.text,
          appendix: sid.at("appendix")&.text
        )
      end

      #
      # Parse contacts from XML.
      #
      # @param [Nokogiri::XML::Element] contrib contributor element
      #
      # @return [Array<RelatonBib::Address, RelatonBib::Contact>] contacts
      #
      # def parse_contact(contrib)
      #   contrib.xpath("formattedAddress").each_with_object(super) do |fa, conts|
      #     city, country = fa.text.split(", ")
      #     next unless city && country

      #     conts << RelatonBib::Address.new(city: city, country: country)
      #   end
      # end

      def create_doctype(type)
        DocumentType.new type: type.text, abbreviation: type[:abbreviation]
      end
    end
  end
end
