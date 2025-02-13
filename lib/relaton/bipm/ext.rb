require_relative "doctype"
require_relative "editorial_group"
require_relative "comment_period"
require_relative "structured_identifier"

module Relaton
  module Bipm
    class Ext < Lutaml::Model::Serializable
      SI_ASPECTS = %w[
        A_e_deltanu A_e cd_Kcd_h_deltanu cd_Kcd full K_k_deltanu K_k
        kg_h_c_deltanu kg_h m_c_deltanu m_c mol_NA s_deltanu
      ]

      attribute :schema_version, :string
      attribute :doctype, Doctype
      attribute :subdoctype, :string
      attribute :flavor, :string
      attribute :editorialgroup, EditorialGroup
      attribute :comment_period, CommentPeriod
      attribute :si_aspect, :string, values: SI_ASPECTS
      attribute :meeting_note, :string
      attribute :structuredidentifier, StructuredIdentifier

      xml do
        map_attribute "schema-version", to: :schema_version
        map_element "doctype", to: :doctype
        map_element "subdoctype", to: :subdoctype
        map_element "flavor", to: :flavor
        map_element "editorialgroup", to: :editorialgroup
        map_element "comment-period", to: :comment_period
        map_element "si-aspect", to: :si_aspect
        map_element "meeting-note", to: :meeting_note
        map_element "structuredidentifier", to: :structuredidentifier
      end
    end
  end
end
