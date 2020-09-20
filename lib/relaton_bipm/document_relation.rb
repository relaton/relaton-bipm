module RelatonBipm
  class DocumentRelation < RelatonBib::DocumentRelation
    TYPES = superclass::TYPES + %w[supersedes supersededBy]
  end
end
