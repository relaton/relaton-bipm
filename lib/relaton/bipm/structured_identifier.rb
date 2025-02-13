module Relaton
  module Bipm
    class StructuredIdentifier < Lutaml::Model::Serializable
      attribute :docnumber, :string
      attribute :part, :string
      attribute :appendix, :string

      xml do
        map_element "docnumber", to: :docnumber
        map_element "part", to: :part
        map_element "appendix", to: :appendix
      end
    end
  end
end
