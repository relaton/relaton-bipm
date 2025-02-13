module Relaton
  module Bipm
    class Committee < Bib::LocalizedString
      ACRONYMS = %w[
        CGPM CIPM BIPM CCAUV CCEM CCL CCM CCPR CCQM CCRI CCT CCTF CCU CCL-CCTF-WGFS JCGM JCRB JCTLM INetQI
      ].freeze

      attribute :acronym, :string, values: ACRONYMS

      xml do
        map_attribute "acronym", to: :acronym
      end
    end
  end
end
