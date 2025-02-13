module Relaton
  module Bipm
    class Doctype < Bib::Doctype
      TYPES = %w[
        brochure mise-en-pratique rapport monographie guide meeting-report
        technical-report working-party-note strategy cipm-mra resolution policy
      ].freeze

      attribute :content, :string, values: TYPES
    end
  end
end
