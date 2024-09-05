# frozen_string_literal: true

module RelatonBipm
  module RawdataBipmMetrologia
    class Fetcher
      DIR = "rawdata-bipm-metrologia/data/*content/0026-1394"

      # @param data_fetcher [RelatonBipm::DataFetcher]
      def self.fetch(data_fetcher)
        new(data_fetcher).fetch
      end

      # @param data_fetcher [RelatonBipm::DataFetcher]
      def initialize(data_fetcher)
        @data_fetcher = WeakRef.new data_fetcher
      end

      #
      # Fetch documents from rawdata-bipm-metrologia and save to files
      #
      def fetch
        fetch_metrologia
        fetch_volumes
        fetch_issues
        fetch_articles
      end

      #
      # Fetch articles from rawdata-bipm-metrologia and save to files
      #
      def fetch_articles # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        # aff = Affiliations.parse DIR
        Dir["#{DIR}/**/*.xml"].each do |path|
          item = ArticleParser.parse path # , aff
          file = "#{item.docidentifier.first.id.downcase.tr(' ', '-')}.#{@data_fetcher.ext}"
          out_path = File.join(@data_fetcher.output, file)
          key = Id.new.parse(item.docidentifier.first.id).to_hash
          @data_fetcher.index2.add_or_update key, out_path
          @data_fetcher.write_file out_path, item
        end
      end

      #
      # Fetch volumes from rawdata-bipm-metrologia and save to files
      #
      def fetch_volumes
        Dir["#{DIR}/*"].map { |path| path.split("/").last }.uniq.each do |volume|
          fetch_metrologia volume
        end
      end

      #
      # Fetch issues from rawdata-bipm-metrologia and save to files
      #
      def fetch_issues
        Dir["#{DIR}/*/*"].each do |path|
          volume, issue = path.split("/").last(2)
          fetch_metrologia volume, issue
        end
      end

      #
      # Fetch metrologia root document from rawdata-bipm-metrologia and save to a file
      #
      # @overload set(volume, issue)
      #   @param [String] volume volume number
      #   @param [String] issue issue number
      # @overload set(volume)
      #   @param [String] volume volume number
      #
      def fetch_metrologia(*args) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        id = identifier(*args)
        item = BipmBibliographicItem.new(
          type: "article", formattedref: formattedref(id), docid: docidentifier(id),
          language: ["en"], script: ["Latn"], relation: relation(*args),
          link: typed_uri(*args)
        )
        file = "#{id.downcase.gsub(' ', '-')}.#{@data_fetcher.ext}"
        path = File.join(@data_fetcher.output, file)
        @data_fetcher.index2.add_or_update Id.new.parse(id).to_hash, path
        @data_fetcher.write_file path, item
      end

      #
      # Create formattedref
      #
      # @param [String] id document identifier
      #
      # @return [RelatonBib::FormattedRef] formattedref
      #
      def formattedref(id)
        RelatonBib::FormattedRef.new content: id, language: "en", script: "Latn"
      end

      #
      # Create docidentifier
      #
      # @param [String] id document identifier
      #
      # @return [Array<RelatonBib::DocumentIdentifier>] docidentifier
      #
      def docidentifier(id)
        [RelatonBib::DocumentIdentifier.new(id: id, type: "BIPM", primary: true)]
      end

      #
      # Create identifier
      #
      # @overload set(volume, issue, article)
      #   @param [String] volume volume number
      #   @param [String] issue issue number
      #   @param [String] article article number
      # @overload set(volume, issue)
      #   @param [String] volume volume number
      #   @param [String] issue issue number
      # @overload set(volume)
      #   @param [String] volume volume number
      #
      # @return [String] document identifier
      #
      def identifier(*args)
        ["Metrologia", *id_parts(*args)].join(" ")
      end

      def id_parts(*args)
        args.map { |p| p.match(/[^_]+$/).to_s }
      end

      #
      # Fetch relations
      #
      # @see #fetch_metrologia
      #
      # @return [Array<RelatonBib::DocumentRelation>] relations
      #
      def relation(*args)
        dir = [DIR, *args].join("/")
        ids = Set.new
        Dir["#{dir}/*"].each do |path|
          part = path.split("/").last
          ids << identifier(*args, part)
        end
        ids.map { |id| RelatonBib::DocumentRelation.new(type: "partOf", bibitem: rel_bibitem(id)) }
      end

      #
      # Create relation bibitem
      #
      # @param [String] id document identifier
      #
      # @return [RelatonBipm::BipmBibliographicItem] bibitem
      #
      def rel_bibitem(id)
        BipmBibliographicItem.new(
          formattedref: formattedref(id), docid: docidentifier(id),
        )
      end

      def typed_uri(*args)
        [RelatonBib::TypedUri.new(type: "src", content: link(*args))]
      end

      def link(*args)
        params = id_parts(*args).join("/")
        case args.size
        when 0 then "https://iopscience.iop.org/journal/0026-1394"
        when 1 then "https://iopscience.iop.org/volume/0026-1394/#{params}"
        when 2 then "https://iopscience.iop.org/issue/0026-1394/#{params}"
        end
      end
    end
  end
end
