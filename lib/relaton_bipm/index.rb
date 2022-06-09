module RelatonBipm
  class Index
    #
    # Initialize index
    #
    def initialize
      read_index_file || get_index_from_gh
    end

    #
    # Search index entry
    #
    # @param [String] ref reference
    #
    # @return [String] path to document file
    #
    def search(ref)
      @index.detect { |key, _| key.include? ref }&.last
    end

    private

    #
    # Create dir if need and return path to index file
    #
    # @return [String] path to index file
    #
    def path
      @path ||= begin
        dir = File.join Dir.home, ".relaton", "bipm"
        FileUtils.mkdir_p dir unless Dir.exist? dir
        File.join dir, "index.yaml"
      end
    end

    #
    # Read index from file if it exists and not outdated
    #
    # @return [Hash, nil] index content
    #
    def read_index_file
      return if !File.exist?(path) || File.ctime(path).to_date < Date.today

      @index = RelatonBipm.parse_yaml File.read(path, encoding: "UTF-8")
    end

    #
    # Save index to file
    #
    # @return [<Type>] <description>
    #
    def save_index_file
      File.write path, @index.to_yaml, encoding: "UTF-8"
    end

    #
    # Get index from a GitHub repository
    #
    # @return [Hash] index content
    #
    def get_index_from_gh # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      resp = Zip::InputStream.new URI("#{BipmBibliography::GH_ENDPOINT}index.zip").open
      zip = resp.get_next_entry
      @index = RelatonBipm.parse_yaml zip.get_input_stream.read
      save_index_file
    end
  end
end
