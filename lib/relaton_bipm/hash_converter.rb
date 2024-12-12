require "yaml"

module RelatonBipm
  module HashConverter
    include RelatonBib::HashConverter
    extend self

    @@acronyms = nil

    # @override RelatonIsoBib::HashConverter.hash_to_bib
    # @param args [Hash]
    # @param nested [TrueClass, FalseClass]
    # @return [Hash]
    def hash_to_bib(args)
      ret = super
      return if ret.nil?

      # project_group_hash_to_bib ret
      commentperiod_hash_to_bib ret
      ret[:si_aspect] = args["ext"]["si_aspect"] if args.dig("ext", "si_aspect")
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
      compr = ret.dig(:ext, :comment_period) || ret[:comment_period] # @TODO: remove ret[:comment_period] after all data is updated
      return unless compr

      ret[:comment_period] &&= CommentPeriond.new(**compr)
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
      ed = ret.dig(:ext, :editorialgroup) || ret[:editorialgroup] # @TODO: remove ret[:editorialgroup] after all data is updated
      return unless ed

      cmt = ed[:committee].map do |c|
        if (vars = committee_variants c).any?
          Committee.new acronym: c[:acronym], content: vars
        else
          Committee.new(**c)
        end
      end
      wg = RelatonBib.array(ed[:workgroup]).map do |w|
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
      struct_id = ret.dig(:ext, :structuredidentifier) || ret[:structuredidentifier] # @TODO: remove ret[:structuredidentifier] after all data is updated
      return unless struct_id

      ret[:structuredidentifier] = StructuredIdentifier.new(**struct_id)
    end

    def create_doctype(**args)
      DocumentType.new(**args)
    end
  end
end
