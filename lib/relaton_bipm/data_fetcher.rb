module RelatonBipm
  class DataFetcher
    attr_reader :output, :format, :ext, :files, :index2

    #
    # Initialize fetcher
    #
    # @param [String] output output directory to save files
    # @param [String] format format of output files (xml, yaml, bibxml)
    #
    def initialize(output, format)
      @output = output
      @format = format
      @ext = format.sub(/^bib/, "")
      @files = []
      @index2 = Relaton::Index.find_or_create :bipm, file: "index2.yaml"
    end

    #
    # Initialize fetcher and run fetching
    #
    # @param [String] source Source name
    # @param [Strin] output directory to save files, default: "data"
    # @param [Strin] format format of output files (xml, yaml, bibxml), default: yaml
    #
    def self.fetch(source, output: "data", format: "yaml")
      t1 = Time.now
      puts "Started at: #{t1}"
      FileUtils.mkdir_p output
      new(output, format).fetch(source)
      t2 = Time.now
      puts "Stopped at: #{t2}"
      puts "Done in: #{(t2 - t1).round} sec."
    end

    #
    # Fetch bipm-data-outcomes or si-brochure
    #
    # @param [String] source Source name
    #
    def fetch(source)
      case source
      when "bipm-data-outcomes" then DataOutcomesParser.parse(self)
      when "bipm-si-brochure" then BipmSiBrochureParser.parse(self)
      when "rawdata-bipm-metrologia" then RawdataBipmMetrologia::Fetcher.fetch(self)
      end
      index2.save
    end

    #
    # Save document to file
    #
    # @param [String] path Path to file
    # @param [RelatonBipm::BipmBibliographicItem] item document to save
    # @param [Boolean, nil] warn_duplicate Warn if document already exists
    #
    def write_file(path, item, warn_duplicate: true)
      content = serialize item
      if @files.include?(path)
        Util.warn "File #{path} already exists" if warn_duplicate
      else
        @files << path
      end
      File.write path, content, encoding: "UTF-8"
    end

    def serialize(item)
      case @format
      when "xml" then item.to_xml bibdata: true
      when "yaml" then item.to_hash.to_yaml
      when "bibxml" then item.to_bibxml
      end
    end
  end
end
