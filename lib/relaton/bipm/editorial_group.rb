require_relative "committee"
require_relative "workgroup"

module Relaton
  module Bipm
    class EditorialGroup < Lutaml::Model::Serializable
      choice do
        attribute :committee, Committee, collection: (1..)
        attribute :workgroup, WorkGroup, collection: true
      end

      xml do
        map_element "committee", to: :committee
        map_element "workgroup", to: :workgroup
      end
    end
  end
end
