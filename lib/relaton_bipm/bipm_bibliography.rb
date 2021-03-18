require "mechanize"

module RelatonBipm
  class BipmBibliography
    GH_ENDPOINT = "https://raw.githubusercontent.com/relaton/relaton-data-bipm/master/data/".freeze
    IOP_DOMAIN = "https://iopscience.iop.org".freeze
    USERAGENTS = [
      "Mozilla/5.0 CK={} (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko",
      "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36",
      "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)",
      "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko",
      "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0; KTXN)",
      "Mozilla/5.0 (Windows NT 5.1; rv:7.0.1) Gecko/20100101 Firefox/7.0.1",
      "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)",
      "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:54.0) Gecko/20100101 Firefox/54.0",
      "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1",
      "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0)",
      "Mozilla/5.0 (Windows NT 10.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_5) AppleWebKit/605.1.15 (KHTML, like Gecko)",
      "Mozilla/5.0 (Windows NT 10.0; WOW64; Trident/7.0; rv:11.0) like Gecko",
      "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:18.0) Gecko/20100101 Firefox/18.0",
      "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/605.1.15 (KHTML, like Gecko)",
      "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; .NET CLR 1.1.4322)",
      "Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko",
      "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0)",
      "Mozilla/5.0 (Linux; U; Android 2.2) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1",
      "Mozilla/5.0 (Windows NT 5.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.71 Safari/537.36",
      "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.1 (KHTML, like Gecko) Chrome/21.0.1180.83 Safari/537.1",
      "Mozilla/4.0 (compatible; MSIE 9.0; Windows NT 6.1)",
    ].freeze

    class << self
      # @param text [String]
      # @return [RelatonBipm::BipmBibliographicItem]
      def search(text, _year = nil, _opts = {})
        warn "[relaton-bipm] (\"#{text}\") fetching..."
        ref = text.sub(/^BIPM\s/, "")
        item = ref.match?(/^Metrologia/i) ? get_metrologia(ref, magent) : get_bipm(ref, magent)
        return unless item

        warn("[relaton-bipm] (\"#{text}\") found #{item.docidentifier[0].id}")
        item
      rescue Mechanize::ResponseCodeError => e
        raise RelatonBib::RequestError, e.message unless e.response_code == "404"
      end

      # @return [Mechanize]
      def magent
        a = Mechanize.new
        a.request_headers = {
          "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,"\
            "*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
          "Accept-Encoding" => "gzip, deflate, br",
          "Accept-Language" => "en-US,en;q=0.9,ru-RU;q=0.8,ru;q=0.7",
          "Cache-Control" => "max-age=0",
          "Upgrade-Insecure-Requests" => "1",
          "User-Agent" => USERAGENTS.shuffle.first,
        }
        a
      end

      # @param ref [String]
      # @param agent [Mechanize]
      # @return [RelatonBipm::BipmBibliographicItem]
      def get_bipm(ref, agent)
        url = "#{GH_ENDPOINT}#{ref.downcase.split(' ').join '-'}.yaml"
        resp = agent.get url
        return unless resp.code == "200"

        bib_hash = HashConverter.hash_to_bib YAML.safe_load(resp.body, [Date])
        BipmBibliographicItem.new **bib_hash
      end

      # @param ref [String]
      # @param agent [Mechanize]
      # @return [RelatonBipm::BipmBibliographicItem]
      def get_metrologia(ref, agent)
        agent.redirect_ok = false
        ref_arr = ref.split(" ")
        case ref_arr.size
        when 1 then get_journal agent
        when 2 then get_volume ref_arr[1], agent
        when 3 then get_issue(*ref_arr[1..2], agent)
        when 4 then get_article_from_issue(*ref_arr[1..3], agent)
        end
      end

      # @param agent [Mechanize]
      # @return [RelatonBipm::BipmBibliographicItem]
      def get_journal(agent)
        url = IOP_DOMAIN + "/journal/0026-1394"
        rsp = agent.get url
        rel = rsp.xpath('//select[@id="allVolumesSelector"]/option').map do |v|
          { type: "partOf", bibitem: journal_rel(v) }
        end
        did = doc_id []
        bibitem(formattedref: fref(did.id), docid: [did], link: blink(url), relation: rel)
      end

      # @param elm [Nokogiri::XML::Element]
      def journal_rel(elm)
        vol = elm[:value].split("/").last
        did = doc_id [vol]
        url = IOP_DOMAIN + elm[:value]
        BipmBibliographicItem.new(formattedref: fref(did.id), docid: [did], link: blink(url))
      end

      # @param vol [String]
      # @param agent [Mechanize]
      # @return [RelatonBipm::BipmBibliographicItem]
      def get_volume(vol, agent)
        url = "#{IOP_DOMAIN}/volume/0026-1394/#{vol}"
        rsp = agent.get url
        rel = rsp.xpath('//li[@itemprop="hasPart"]').map do |i|
          { type: "partOf", bibitem: volume_rel(i, vol) }
        end
        did = doc_id [vol]
        bibitem(formattedref: fref(did.id), docid: [did], link: blink(url), date: bdate(rsp), relation: rel,
                extent: btextent(vol), series: series)
      end

      def volume_rel(elm, vol) # rubocop:disable Metrics/AbcSize
        a = elm.at 'a[@itemprop="issueNumber"]'
        ish = a[:href].split("/").last
        url = IOP_DOMAIN + a[:href]
        docid = doc_id [vol, ish]
        t = elm.at "p"
        title_fref = t ? { title: titles(t.text) } : { formattedref: fref(docid.id) }
        BipmBibliographicItem.new **title_fref, docid: [docid], link: blink(url)
      end

      # @param title [String]
      # @return [RelatonBib::TypedTitleStringCollection]
      def titles(title)
        RelatonBib::TypedTitleString.from_string title, "en", "Latn"
      end

      # @param vol [String]
      # @param ish [String]
      # @param agent [Mechanize]
      # @return [RelatonBipm::BipmBibliographicItem]
      def get_issue(vol, ish, agent) # rubocop:disable Metrics/AbcSize
        url = issue_url vol, ish
        rsp = agent.get url
        rel = rsp.xpath('//div[@class="art-list-item-body"]').map do |a|
          { type: "partOf", bibitem: issue_rel(a, vol, ish) }
        end
        did = doc_id [vol, ish]
        title_fref = { title: issue_title(rsp) }
        title_fref[:formattedref] = fref did.id unless title_fref[:title].any?
        bibitem(**title_fref, link: blink(url), relation: rel, docid: [did],
                              date: bdate(rsp), extent: btextent(vol, ish), series: series)
      end

      # @param ref [String]
      # @return [RelatonBib::FormattedRef]
      def fref(ref)
        RelatonBib::FormattedRef.new content: ref, language: "en", script: "Latn"
      end

      # @param rsp [Mechanize::Page]
      # @return [RelatonBib::TypedTitleStringCollection]
      def issue_title(rsp)
        t = rsp.at('//div[@id="wd-jnl-issue-title"]/h4')
        return RelatonBib::TypedTitleStringCollection.new [] unless t

        titles(t.text)
      end

      # @oaran vol [String]
      # @param ish [String]
      # @return [String]
      def issue_url(vol, ish)
        "#{IOP_DOMAIN}/issue/0026-1394/#{vol}/#{ish}"
      end

      # @param elm [Nokogiri::XML::Element]
      # @param vol [String]
      # @param ish [String]
      # @return [RelatonBipm::BipmBibliographicItem]
      def issue_rel(elm, vol, ish)
        art = elm.at('div[@class="indexer"]').text
        ref = elm.at('div/a[@class="art-list-item-title"]')
        title = titles ref.text.strip
        docid = doc_id [vol, ish, art]
        link = blink IOP_DOMAIN + ref[:href]
        BipmBibliographicItem.new(title: title, docid: [docid], link: link)
      end

      # @param content [RelatonBib::TypedTitleString]
      # @return [RelatonBib::TypedTitleString]
      def btitle(content)
        RelatonBib::TypedTitleString.new type: "main", content: content, language: "en", script: "Latn"
      end

      # @param url [String]
      # @return [String]
      def blink(url)
        [RelatonBib::TypedUri.new(type: "src", content: url)]
      end

      # @param rsp [Mechanize::Page]
      # @return [Array<RelatonBib::BibliographicDate>]
      def bdate(rsp)
        date = rsp.at('//p[@itemprop="issueNumber"]|//h2[@itemprop="volumeNumber"]').text.split(", ").last
        on = date.match?(/^\d{4}$/) ? date : Date.parse(date).strftime("%Y-%m")
        [RelatonBib::BibliographicDate.new(type: "published", on: on)]
      end

      # @param args [Array<String>]
      # @return [RelatonBib::DocumentIdentifier]
      def doc_id(args)
        id = args.clone.unshift "Metrologia"
        RelatonBib::DocumentIdentifier.new(type: "BIPM", id: id.join(" "))
      end

      # @param vol [String]
      # @param ish [String]
      # @param art [String]
      # @param agent [Mechanize]
      # @return [RelatonBipm::BipmBibliographicItem]
      def get_article_from_issue(vol, ish, art, agent)
        url = issue_url vol, ish
        rsp = agent.get url
        get_article rsp.at("//div[@class='indexer'][.='#{art}']/../div/a")[:href], vol, ish, agent
      end

      # @param path [String]
      # @param vol [String]
      # @param ish [String]
      # @param agent [Mechanize]
      # @return [RelatonBipm::BipmBibliographicItem]
      def get_article(path, vol, ish, agent) # rubocop:disable Metrics/AbcSize
        url = URI IOP_DOMAIN + path
        rsp = agent.get url
        bib = rsp.link_with(text: "BibTeX").href
        rsp = agent.get URI IOP_DOMAIN + bib
        bt = BibTeX.parse(rsp.body).first
        bibitem(docid: btdocid(bt), title: titles(bt.title.to_s), abstract: btabstract(bt), doctype: bt.type.to_s,
                link: btlink(bt, url), date: btdate(bt), contributor: btcontrib(bt), series: series,
                extent: btextent(vol, ish, bt))
      end

      # @param args [Hash]
      # @return [RelatonBipm::BipmBibliographicItem]
      def bibitem(**args)
        BipmBibliographicItem.new(
          fetched: Date.today.to_s, type: "standard", language: ["en"], script: ["Latn"], **args
        )
      end

      # @return [Array<RelatonBib::Series>]
      def series
        [RelatonBib::Series.new(title: btitle("Metrologia"))]
      end

      # @param bibtex [BibTeX::Entry]
      # @return [Array<RelatonBib::DocumentIdentifier>]
      def btdocid(bibtex)
        id = "#{bibtex.journal} #{bibtex.volume} #{bibtex.number} #{bibtex.pages.match(/^\d+/)}"
        [RelatonBib::DocumentIdentifier.new(type: "BIPM", id: id)]
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

      # @param vol [String]
      # @param ish [String]
      # @param bibtex [BibTeX::Entry]
      # @return [Array<RelatonBib::BibItemLocality>]
      def btextent(vol, ish = nil, bibtex = nil)
        ext = [RelatonBib::BibItemLocality.new("volume", vol)]
        ext << RelatonBib::BibItemLocality.new("issue", ish) if ish
        ext << RelatonBib::BibItemLocality.new("page", *bibtex.pages.split("--")) if bibtex
        ext
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
