module RelatonBipm
  class DataFetcher
    def initialize(output, format)
      @output = output
      @format = format
      @ext = format.sub(/^bib/, "")
    end
  end
end
