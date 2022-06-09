module RelatonBipm
  class BipmBibliographicItem < RelatonBib::BibliographicItem
    include RelatonBib

    TYPES = %w[brochure mise-en-pratique rapport monographie guide
               meeting-report technical-report working-party-note strategy
               cipm-mra resolutions].freeze

    STATUSES = %w[draft-proposal draft-development in-force retired].freeze

    SI_ASPECTS = %w[
      A_e_deltanu A_e cd_Kcd_h_deltanu cd_Kcd full K_k_deltanu K_k
      kg_h_c_deltanu kg_h m_c_deltanu m_c mol_NA s_deltanu
    ].freeze

    # @return [RelatonBipm::CommentPeriod, nil]
    attr_reader :comment_period

    # @return [String, nil]
    attr_reader :si_aspect, :meeting_note

    # @param relation [Array<RelatonBipm::DocumentRelation>]
    # @param editorialgroup [RelatonBipm::EditorialGroup]
    # @param comment_period [RelatonBipm::CommentPeriod, nil]
    # @param si_aspect [String, nil]
    # @param meeting_note [String, nil]
    # @param structuredidentifier [RelatonBipm::StructuredIdentifier]
    def initialize(**args) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      if args[:docstatus] && !STATUSES.include?(args[:docstatus].stage.value)
        warn "[relaton-bipm] Warning: invalid docstatus: #{args[:docstatus].stage.value}. "\
             "It should be one of: #{STATUSES}"
      end

      if args[:si_aspect] && !SI_ASPECTS.include?(args[:si_aspect])
        warn "[relaton-bipm] Warning: invalid si_aspect: #{args[:si_aspect]}. "\
             "It should be one of: #{SI_ASPECTS}"
      end

      @comment_period = args.delete :comment_period
      @si_aspect = args.delete :si_aspect
      @meeting_note = args[:meeting_note]
      super
    end

    # @param hash [Hash]
    # @return [RelatonBipm::BipmBibliographicItem]
    def self.from_hash(hash)
      item_hash = ::RelatonBipm::HashConverter.hash_to_bib(hash)
      new(**item_hash)
    end

    # @param opts [Hash]
    # @option opts [Nokogiri::XML::Builder] :builder XML builder
    # @option opts [Boolean] :bibdata
    # @option opts [String] :lang language
    # @return [String] XML
    def to_xml(**opts) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      super ext: !comment_period.nil?, **opts do |b|
        if opts[:bibdata] && (doctype || editorialgroup&.presence? ||
                              si_aspect || comment_period ||
                              structuredidentifier)
          b.ext do
            b.doctype doctype if doctype
            editorialgroup&.to_xml b
            comment_period&.to_xml b
            b.send :"si-aspect", si_aspect if si_aspect
            b.send :"meeting-note", meeting_note if meeting_note
            structuredidentifier&.to_xml b
          end
        end
      end
    end

    # @return [Hash]
    def to_hash
      hash = super
      hash["comment_period"] = comment_period.to_hash if comment_period
      hash["si_aspect"] = si_aspect if si_aspect
      hash["meeting_note"] = meeting_note if meeting_note
      hash
    end

    # @param prefix [String]
    # @return [String]
    def to_asciibib(prefix = "")
      pref = prefix.empty? ? prefix : "#{prefix}."
      out = super
      out += comment_period.to_asciibib prefix if comment_period
      out += "#{pref}si_aspect:: #{si_aspect}\n" if si_aspect
      out += "#{pref}meeting_note:: #{meeting_note}\h" if meeting_note
      out
    end
  end
end
