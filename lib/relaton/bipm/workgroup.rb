module Relaton
  module Bipm
    class WorkGroup < Lutaml::Model::Serializable
      attribute :acronym, :string
      attribute :content, :string

      xml do
        map_attribute "acronym", to: :acronym
        map_content to: :content
      end
    end
  end
end
