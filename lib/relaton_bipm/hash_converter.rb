require "yaml"

module RelatonBipm
  class HashConverter < RelatonBib::HashConverter
    class << self
      # @override RelatonIsoBib::HashConverter.hash_to_bib
      # @param args [Hash]
      # @param nested [TrueClass, FalseClass]
      # @return [Hash]
      def hash_to_bib(args, nested = false)
        ret = super
        return if ret.nil?

        project_group_hash_to_bib ret
        commentperiod_hash_to_bib ret
        ret
      end

      private

      # @param item_hash [Hash]
      # @return [RelatonBib::BibliographicItem]
      def bib_item(item_hash)
        BipmBibliographicItem.new item_hash
      end

      # @param ret [Hash]
      def title_hash_to_bib(ret)
        ret[:title] &&= array(ret[:title]).map do |t|
          if t.is_a? Hash
            RelatonBib::FormattedString.new t
          else
            RelatonBib::FormattedString.new content: t
          end
        end
      end

      # @param ret [Hash]
      def docstatus_hash_to_bib(ret)
        ret[:docstatus] &&= DocumentStatus.new ret[:docstatus]
      end

      # @param ret [Hash]
      def commentperiod_hash_to_bib(ret)
        ret[:commentperiod] &&= CommentPeriond.new(ret[:commentperiod])
      end

      # @param ret [Hash]
      def project_group_hash_to_bib(ret)
        ret[:project_group] &&= array(ret[:project_group]).map do |pg|
          wg = RelatonBib::FormattedString.new pg[:workgroup]
          ProjectTeam.new(committee: pg[:committee], workgroup: wg)
        end
      end

      # @param ret [Hash]
      def dates_hash_to_bib(ret)
        super
        ret[:date] &&= ret[:date].map do |d|
          BibliographicDate.new d
        end
      end

      # @param ret [Hash]
      def relations_hash_to_bib(ret)
        super
        ret[:relation] &&= ret[:relation].map do |r|
          RelatonBipm::DocumentRelation.new r
        end
      end
    end
  end
end
