require "net/http"
require "mechanize"

module RelatonBipm
  class BipmBibliography
    GH_ENDPOINT = "https://raw.githubusercontent.com/relaton/relaton-data-bipm/master/data/".freeze
    IOP_DOMAIN = "https://iopscience.iop.org".freeze

    class << self
      # @param text [String]
      # @return [RelatonBipm::BipmBibliographicItem]
      def search(text, _year = nil, _opts = {}) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        warn "[relaton-bipm] (\"#{text}\") fetching..."
        ref = text.sub(/^BIPM\s/, "")
        hash = if ref.match? /^Metrologia/i
                 ref_arr = ref.split(" ")[1..-1]
                 uri = URI("#{IOP_DOMAIN}/issue/0026-1394/#{ref_arr[0..1].join('/')}")
                 get_metrologia uri, ref_arr.fetch(2)
               else
                 uri = URI("#{GH_ENDPOINT}#{ref.downcase.split(' ').join '-'}.yaml")
                 get_bipm uri
               end
        if hash
          warn "[relaton-bipm] (\"#{text}\") found #{hash[:docid][0].id}"
          BipmBibliographicItem.new hash
        end
      rescue SocketError, Errno::EINVAL, Errno::ECONNRESET, EOFError,
             Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
             Net::ProtocolError, Net::ReadTimeout, # OpenSSL::SSL::SSLError,
             Errno::ETIMEDOUT => e
        raise RelatonBib::RequestError, "Could not access #{uri}: #{e.message}"
      end

      # @param uri [URI]
      # @return [Hash]
      def get_bipm(uri)
        resp = Net::HTTP.get_response uri
        return unless resp.code == "200"

        HashConverter.hash_to_bib YAML.safe_load(resp.body, [Date])
      end

      # @param uri [URI]
      # @param art [String]
      # @return [Hash]
      def get_metrologia(uri, art) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        agent = Mechanize.new
        agent.request_headers = { "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 11_1_0) AppleWebKit/537.36 "\
          "(KHTML, like Gecko) Chrome/87.0.4280.101 Safari/537.36" }
        rsp_issue = agent.get uri
        art_ref = rsp_issue.at("//div[@class='indexer'][.='#{art}']/../div/a")[:href]
        rsp_art = agent.get URI IOP_DOMAIN + art_ref
        bib_ref = rsp_art.link_with(text: "BibTeX").href
        rsp_bib = agent.get URI IOP_DOMAIN + bib_ref
        bt = BibTeX.parse(rsp_bib.body).first
        { fetched: Date.today.to_s, type: "standard", docid: btdocid(bt), title: bttitle(bt),
          abstract: btabstract(bt), language: ["en"], script: ["Latn"], doctype: bt.type.to_s,
          link: btlink(bt, art_ref), date: btdate(bt), contributor: btcontrib(bt), extent: btextent(bt) }
      end

      # @param bibtex [BibTeX::Entry]
      # @return [Array<RelatonBib::DocumentIdentifier>]
      def btdocid(bibtex)
        id = "#{bibtex.journal} #{bibtex.volume} #{bibtex.number} #{bibtex.pages.match(/^\d+/)}"
        [RelatonBib::DocumentIdentifier.new(type: "BIPM", id: id)]
      end

      # @param bibtex [BibTeX::Entry]
      # @return [RelatonBib::TypedTitleStringCollection]
      def bttitle(bibtex)
        RelatonBib::TypedTitleString.from_string bibtex.title.to_s, "en", "Latn"
      end

      # @param bibtex [BibTeX::Entry]
      # @return [Array<RelatonBib::FormattedString>]
      def btabstract(bibtex)
        [RelatonBib::FormattedString.new(content: bibtex.abstract.to_s, language: "en", script: "Latn")]
      end

      # @param bibtex [BibTeX::Entry]
      # @param ref [URI]
      # @return [Array<RelatonBib::TypedUri>]
      def btlink(bibtex, ref)
        [
          RelatonBib::TypedUri.new(type: "src", content: ref.to_s),
          RelatonBib::TypedUri.new(type: "doi", content: bibtex.url.to_s),
        ]
      end

      # @param bibtex [BibTeX::Entry]
      # @return [Array<RelatonBib::BibliographicDate>]
      def btdate(bibtex)
        on = Date.new(bibtex.year.to_i, bibtex.month_numeric)
        [RelatonBib::BibliographicDate.new(type: "published", on: on)]
      end

      # @param bibtex [BibTeX::Entry]
      # @return [Array<Hash>]
      def btcontrib(bibtex)
        surname, initial = bibtex.author.split ", "
        initial = initial.split(" ").map { |i| RelatonBib::LocalizedString.new i, "en", "Latn" }
        surname = RelatonBib::LocalizedString.new surname, "en", "Latn"
        name = RelatonBib::FullName.new surname: surname, initial: initial
        author = RelatonBib::Person.new name: name
        [
          { entity: { name: bibtex.publisher.to_s }, role: [{ type: "publisher" }] },
          { entity: author, role: [{ type: "author" }] },
        ]
      end

      # @param bibtex [BibTeX::Entry]
      # @return [Array<RelatonBib::BibItemLocality>]
      def btextent(bibtex)
        from, to = bibtex.pages.split "--"
        [RelatonBib::BibItemLocality.new("page", from, to)]
      end

      # @param ref [String] the BIPM standard Code to look up (e..g "BIPM B-11")
      # @param year [String] not used
      # @param opts [Hash] not used
      # @return [RelatonBipm::BipmBibliographicItem]
      def get(ref, year = nil, opts = {})
        search(ref, year, opts)
      end
    end
  end
end
