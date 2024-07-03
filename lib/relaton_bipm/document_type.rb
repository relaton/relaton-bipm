module RelatonBipm
  class DocumentType < RelatonBib::DocumentType
    DOCTYPES = %w[brochure mise-en-pratique rapport monographie guide
                  meeting-report technical-report working-party-note strategy
                  cipm-mra resolutions].freeze

    #
    # Initialize a document type object.
    #
    # @param [String] type document type
    # @param [String, nil] abbreviation abbreviation
    #
    def initialize(type:, abbreviation: nil)
      check_type type
      super
    end

    #
    # Check if document type is valid.
    #
    # @param [String] type document type
    #
    def check_type(type)
      # unless DOCTYPES.include? type
      #   Util.warn "invalid doctype: `#{type}`"
      # end
    end
  end
end
