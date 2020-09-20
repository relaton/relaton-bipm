module RelatonBipm
  class BibliographicDate < RelatonBib::BibliographicDate
    TYPES = superclass::TYPES + %w[effective supreseded]
  end
end
