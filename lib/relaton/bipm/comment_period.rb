module Relaton
  module Bipm
    class CommentPeriod < Lutaml::Model::Serializable
      attribute :from, :date
      attribute :to, :date

      xml do
        map_element "from", to: :from
        map_element "to", to: :to
      end
    end
  end
end
