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

        data[:project_group] = fetch_project_group ext
        data[:commentperiod] = fetch_commentperiond ext
        data
      end

      # @param item_hash [Hash]
      # @return [RelatonBipm::BipmBibliographicItem]
      def bib_item(item_hash)
        BipmBibliographicItem.new item_hash
      end

      def fetch_project_group(ext)
        ext.xpath("./project-group").map do |pg|
          wg = pg.at "workgroup"
          workgroup = RelatonBib::FormattedString.new(
            content: wg.text, language: wg[:language], script: wg[:script],
            format: wg[:format]
          )
          ProjectTeam.new(committee: pg.at("committee").text,
                          workgroup: workgroup)
        end
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
      # @return [Array<RelatonBib::DocumentRelation>]
      def fetch_relations(item, klass = DocumentRelation)
        super
      end

      # @param item [Nokogiri::XML::Element]
      # @return [RelatonBipm::DocumentStatus]
      def fetch_status(item)
        status = item.at("./status")
        return unless status

        DocumentStatus.new status.text
      end

      # @param ext [Nokogiri::XML::Element]
      # @return [RelatonIho::CommentPeriod, nil]
      def fetch_commentperiond(ext)
        return unless ext && (cp = ext.at "commentperiod")

        CommentPeriond.new from: cp.at("from")&.text, to: cp.at("to")&.text
      end
    end
  end
end
