require "yaml"

module RelatonBipm
  class HashConverter < RelatonBib::HashConverter
    @@acronyms = nil

    class << self
      # @override RelatonIsoBib::HashConverter.hash_to_bib
      # @param args [Hash]
      # @param nested [TrueClass, FalseClass]
      # @return [Hash]
      def hash_to_bib(args)
        ret = super
        return if ret.nil?

        # project_group_hash_to_bib ret
        commentperiod_hash_to_bib ret
        ret
      end

      private

      # @param item_hash [Hash]
      # @return [RelatonBib::BibliographicItem]
      def bib_item(item_hash)
        BipmBibliographicItem.new(**item_hash)
      end

      # @param ret [Hash]
      def title_hash_to_bib(ret)
        ret[:title] &&= RelatonBib.array(ret[:title])
          .reduce(RelatonBib::TypedTitleStringCollection.new) do |m, t|
          m << if t.is_a? Hash
                 RelatonBib::TypedTitleString.new(**t)
               else
                 RelatonBib::TypedTitleString.new(content: t)
               end
        end
      end

      # @param ret [Hash]
      def commentperiod_hash_to_bib(ret)
        ret[:comment_period] &&= CommentPeriond.new(**ret[:comment_period])
      end

      # @param ret [Hash]
      # def project_group_hash_to_bib(ret)
      #   ret[:project_group] &&= RelatonBib.array(ret[:project_group]).map do |pg|
      #     wg = RelatonBib::FormattedString.new pg[:workgroup]
      #     ProjectTeam.new(committee: pg[:committee], workgroup: wg)
      #   end
      # end

      # @param ret [Hash]
      def dates_hash_to_bib(ret)
        super
        ret[:date] &&= ret[:date].map { |d| BibliographicDate.new(**d) }
      end

      # @param ret [Hash]
      def relations_hash_to_bib(ret)
        super
        ret[:relation] &&= ret[:relation].map do |r|
          RelatonBipm::DocumentRelation.new(**r)
        end
      end

      # @param ret [Hash]
      def editorialgroup_hash_to_bib(ret) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        return unless ret[:editorialgroup]

        cmt = ret[:editorialgroup][:committee].map do |c|
          if (vars = committee_variants c).any?
            content = RelatonBib::LocalizedString.new vars
            Committee.new acronym: c[:acronym], content: content
          else
            Committee.new(**c)
          end
        end
        wg = RelatonBib.array(ret[:editorialgroup][:workgroup]).map do |w|
          w.is_a?(Hash) ? WorkGroup.new(**w) : WorkGroup.new(content: w)
        end
        ret[:editorialgroup] = EditorialGroup.new committee: cmt, workgroup: wg
      end

      def committee_variants(cmt)
        RelatonBib.array(cmt[:variants]).each_with_object([]) do |v, a|
          c = v[:content] || (ac = acronyms[cmt[:acronym]]) && ac[v[:language]]
          a << RelatonBib::LocalizedString.new(c, v[:language], v[:script]) if c
        end
      end

      def acronyms
        @@acronyms ||= YAML.load_file File.join __dir__, "acronyms.yaml"
      end

      # @param ret [Hash]
      def structuredidentifier_hash_to_bib(ret)
        ret[:structuredidentifier] &&= StructuredIdentifier.new(
          **ret[:structuredidentifier],
        )
      end
    end
  end
end
