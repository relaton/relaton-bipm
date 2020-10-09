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
        data
      end

      # @param item_hash [Hash]
      # @return [RelatonBipm::BipmBibliographicItem]
      def bib_item(item_hash)
        BipmBibliographicItem.new item_hash
      end

      # @param item [Nokogiri::XML::Element]
      # @return [Array<RelatonBib::FormattedString>]
      def fetch_titles(item)
        item.xpath("./title").map do |t|
          RelatonBib::TypedTitleString.new(
            content: t.text, language: t[:language], script: t[:script],
            format: t[:format]
          )
        end
      end

      def fetch_dates(item) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        item.xpath("./date").reduce([]) do |a, d|
          type = d[:type].to_s.empty? ? "published" : d[:type]
          if (on = d.at("on"))
            a << BibliographicDate.new(type: type, on: on.text,
                                       to: d.at("to")&.text)
          elsif (from = d.at("from"))
            a << BibliographicDate.new(type: type, from: from.text,
                                       to: d.at("to")&.text)
          end
        end
      end

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
      def fetch_editorialgroup(ext)
        return unless ext && (eg = ext.at "editorialgroup")

        cm = eg.xpath("committee").map &:text
        wg = eg.xpath("workgroup").map &:text
        EditorialGroup.new committee: cm, workgroup: wg
      end

      # @param ext [Nokogiri::XML::Element]
      # @return [RelatonBipm::StructuredIdentifier]
      def fetch_structuredidentifier(ext)
        return unless ext && (sid = ext.at("structuredidentifier"))

        StructuredIdentifier.new(
          docnumber: sid.at("docnumber").text, part: sid.at("part")&.text,
          appendix: sid.at("appendix")&.text
        )
      end
    end
  end
end
