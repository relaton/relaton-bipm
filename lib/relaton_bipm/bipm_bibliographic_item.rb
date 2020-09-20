module RelatonBipm
  class BipmBibliographicItem < RelatonBib::BibliographicItem
    include RelatonBib

    TYPES = %w[brochure mise-en-pratique rapport monographie guide
               meeting-report technical-report working-party-note strategy
               cipm-mra resolutions].freeze

    STATUSES = %w[draft-proposal draft-development in-force retired].freeze

    # @return [Array<RelatonBipm::BipmProjectTeam>]
    attr_reader :project_group

    # @return [RelatonIho::CommentPeriod, NilClass]
    attr_reader :commentperiod

    # @param project_group [Array<RelatonBipm::ProjectTeam>]
    # @param title [Array<RelatonBib::FormattedString>]
    # @param date [Array<RelatonBipm::BibliographicDate>]
    # @param relation [Array<RelatonBipm::DocumentRelation>]
    # @param docstatus [RelatonBipm::DocumentStatus, nil]
    # @param commentperiod [RelatonBipm::CommentPeriod, NilClass]
    def initialize(**args)
      if args[:docstatus] && !STATUSES.include?(args[:docstatus].status)
        warn "[relaton-bipm] Warning: invalid docstatus #{args[:docstatus]}. "\
        "It should be one of: #{STATUSES}"
      end
      @project_group = args.delete(:project_group) || []
      # @status = args.delete :docstatus
      @commentperiod = args.delete :commentperiod
      super
    end

    # @param builder [Nokogiri::XML::Builder]
    # @param bibdata [TrueClasss, FalseClass, NilClass]
    def to_xml(builer = nil, **opts) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      opts[:ext] = !commentperiod.nil?
      super do |b|
        if opts[:bibdata] && (doctype || editorialgroup&.presence? ||
                              ics.any? || commentperiod)
          b.ext do
            b.doctype doctype if doctype
            editorialgroup&.to_xml b
            ics.each { |i| i.to_xml b }
            project_group.each { |pg| pg.to_xml b }
            commentperiod&.to_xml b
          end
        end
      end
    end

    # @return [Hash]
    def to_hash
      hash = super
      hash["project_group"] = single_element_array project_group
      hash["commentperiod"] = commentperiod.to_hash if commentperiod
      hash
    end

    # @param prefix [String]
    # @return [String]
    def to_asciibib(prefix = "")
      out = super
      project_group.each { |p| out += p.to_asciibib prefix, project_group.size }
      out += commentperiod.to_asciibib prefix if commentperiod
      out
    end
  end
end
