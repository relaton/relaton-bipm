require_relative "doctype"
require_relative "comment_period"
require_relative "structured_identifier"

module Relaton
  module Bipm
    class Ext < Bib::Ext
      SI_ASPECTS = %w[
        A_e_deltanu A_e cd_Kcd_h_deltanu cd_Kcd full K_k_deltanu K_k
        kg_h_c_deltanu kg_h m_c_deltanu m_c mol_NA s_deltanu
      ]

      attribute :doctype, Doctype
      attribute :structuredidentifier, StructuredIdentifier
      attribute :comment_period, CommentPeriod
      attribute :si_aspect, :string, values: SI_ASPECTS
      attribute :meeting_note, :string

      xml do
        map_element "comment-period", to: :comment_period
        map_element "si-aspect", to: :si_aspect
        map_element "meeting-note", to: :meeting_note
      end

      key_value do
        map_element "comment_period", to: :comment_period
        map_element "si_aspect", to: :si_aspect
        map_element "meeting_note", to: :meeting_note
      end

      def get_schema_version = Relaton.schema_versions["relaton-model-bipm"]
    end
  end
end
