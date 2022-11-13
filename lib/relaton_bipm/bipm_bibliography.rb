require "mechanize"

module RelatonBipm
  class BipmBibliography
    GH_ENDPOINT = "https://raw.githubusercontent.com/relaton/relaton-data-bipm/master/".freeze
    IOP_DOMAIN = "https://iopscience.iop.org".freeze
    TRANSLATIONS = {
      "Déclaration" => "Declaration",
      "Réunion" => "Meeting",
      "Recommandation" => "Recommendation",
      "Résolution" => "Resolution",
      "Décision" => "Decision",
    }.freeze

    class << self
      # @param text [String]
      # @return [RelatonBipm::BipmBibliographicItem]
      def search(text, _year = nil, _opts = {}) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        warn "[relaton-bipm] (\"#{text}\") fetching..."
        ref = text.sub(/^BIPM\s/, "")
        item = ref.match?(/^Metrologia/i) ? get_metrologia(ref, magent) : get_bipm(ref, magent)
        unless item
          warn "[relaton-bipm] (\"#{text}\") not found."
          return
        end

        warn("[relaton-bipm] (\"#{text}\") found #{item.docidentifier[0].id}")
        item.fetched = Date.today.to_s
        item
      rescue Mechanize::ResponseCodeError => e
        raise RelatonBib::RequestError, e.message unless e.response_code == "404"
      end

      # @return [Mechanize]
      def magent # rubocop:disable Metrics/MethodLength
        a = Mechanize.new
        a.request_headers = {
          "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9," \
                      "image/avif,image/webp,image/apng," \
                      "*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
          "Accept-Encoding" => "gzip, deflate, br",
          "Accept-Language" => "en-US,en;q=0.9,ru-RU;q=0.8,ru;q=0.7",
          "Cache-Control" => "max-age=0",
          "Upgrade-Insecure-Requests" => "1",
        }
        a.user_agent_alias = Mechanize::AGENT_ALIASES.map(&:first).shuffle.first
        # a.user_agent_alias = "Mac Safari"
        a
      end

      # @param ref [String]
      # @param agent [Mechanize]
      # @return [RelatonBipm::BipmBibliographicItem]
      def get_bipm(ref, agent) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        # rf = ref.sub(/(?:(\d{1,2})\s)?\(?(\d{4})(?!-)\)?/) do
        #   "#{$2}-#{$1.to_s.rjust(2, '0')}"
        # end
        ref.sub!("CCDS", "CCTF")
        # TRANSLATIONS.each { |fr, en| rf.sub! fr, en }
        path = Index.new.search ref
        return unless path

        url = "#{GH_ENDPOINT}#{path}"
        resp = agent.get url
        check_response resp
        return unless resp.code == "200"

        yaml = RelatonBib.parse_yaml resp.body, [Date]
        yaml["fetched"] = Date.today.to_s
        bib_hash = HashConverter.hash_to_bib yaml
        BipmBibliographicItem.new(**bib_hash)
      end

      # @param ref [String]
      # @param agent [Mechanize]
      # @return [RelatonBipm::BipmBibliographicItem]
      def get_metrologia(ref, agent)
        agent.redirect_ok = false
        ref_arr = ref.split
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
        url = "#{IOP_DOMAIN}/journal/0026-1394"
        rsp = agent.get url
        check_response rsp
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
        check_response rsp
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
        BipmBibliographicItem.new(**title_fref, docid: [docid], link: blink(url))
      end

      # @param title [String]
      # @return [RelatonBib::TypedTitleStringCollection]
      def titles(title)
        RelatonBib::TypedTitleString.from_string title, "en", "Latn", "text/html"
      end

      # @param vol [String]
      # @param ish [String]
      # @param agent [Mechanize]
      # @return [RelatonBipm::BipmBibliographicItem]
      def get_issue(vol, ish, agent) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        url = issue_url vol, ish
        rsp = agent.get url
        check_response rsp
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
        RelatonBib::DocumentIdentifier.new(type: "BIPM", id: id.join(" "), primary: true)
      end

      # @param vol [String]
      # @param ish [String]
      # @param art [String]
      # @param agent [Mechanize]
      # @return [RelatonBipm::BipmBibliographicItem]
      def get_article_from_issue(vol, ish, art, agent) # rubocop:disable Metrics/MethodLength
        url = issue_url vol, ish
        rsp = agent.get url
        check_response rsp
        link = rsp.at("//div[@class='indexer'][.='#{art}']/../div/a")
        unless link
          arts = rsp.xpath("//div[@class='indexer']").map(&:text)
          warn "[relaton-bipm] No article is available at the specified start page \"#{art}\" in issue \"BIPM Metrologia #{vol} #{ish}\"."
          warn "[relaton-bipm] Available articles in the issue start at the following pages: (#{arts.join(', ')})"
          return
        end

        get_article link[:href], vol, ish, agent
      end

      # @param path [String]
      # @param vol [String]
      # @param ish [String]
      # @param agent [Mechanize]
      # @return [RelatonBipm::BipmBibliographicItem]
      def get_article(path, vol, ish, agent) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        agent.agent.allowed_error_codes = [403]
        rsp = agent.get path
        check_response rsp
        title = rsp.at("//h1[@itemprop='headline']").children.to_xml
        url = rsp.uri
        bib = rsp.link_with(text: "BibTeX").href
        rsp = agent.get bib
        check_response rsp
        bt = BibTeX.parse(rsp.body).first
        bibitem(
          docid: btdocid(bt), title: titles(title), date: btdate(bt),
          abstract: btabstract(bt), doctype: bt.type.to_s, series: series,
          link: btlink(bt, url), contributor: btcontrib(bt),
          extent: btextent(vol, ish, bt.pages.to_s)
        )
      end

      # @param args [Hash]
      # @return [RelatonBipm::BipmBibliographicItem]
      def bibitem(**args)
        BipmBibliographicItem.new(
          fetched: Date.today.to_s, type: "article", language: ["en"], script: ["Latn"], **args,
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
        [
          RelatonBib::DocumentIdentifier.new(type: "BIPM", id: id, primary: true),
          RelatonBib::DocumentIdentifier.new(type: "DOI", id: bibtex.doi),
        ]
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
      def btcontrib(bibtex) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        contribs = []
        if bibtex.publisher && !bibtex.publisher.empty?
          org = RelatonBib::Organization.new name: bibtex.publisher.to_s
          contribs << { entity: org, role: [{ type: "publisher" }] }
        end
        return contribs unless bibtex.author && !bibtex.author.empty?

        bibtex.author.split(" and ").inject(contribs) do |mem, name|
          cname = RelatonBib::LocalizedString.new name, "en", "Latn"
          name = RelatonBib::FullName.new completename: cname
          author = RelatonBib::Person.new name: name
          mem << { entity: author, role: [{ type: "author" }] }
        end
      end

      #
      # @param vol [String] volume
      # @param ish [String] issue
      # @param pgs [String] pages
      #
      # @return [Array<RelatonBib::BibItemLocality>]
      #
      def btextent(vol, ish = nil, pgs = nil)
        ext = [RelatonBib::Locality.new("volume", vol)]
        ext << RelatonBib::Locality.new("issue", ish) if ish
        ext << RelatonBib::Locality.new("page", *pgs.split("--")) if pgs
        ext
      end

      # @param ref [String] the BIPM standard Code to look up (e..g "BIPM B-11")
      # @param year [String] not used
      # @param opts [Hash] not used
      # @return [RelatonBipm::BipmBibliographicItem]
      def get(ref, year = nil, opts = {})
        search(ref, year, opts)
      end

      private

      #
      # Check HTTP response. Warn and rise error if response is not 200
      #   or redirect to CAPTCHA.
      #
      # @param [Mechanize] rsp response
      #
      # @raise [RelatonBib::RequestError] if response is not 200
      #
      def check_response(rsp) # rubocop:disable Metrics/AbcSize
        if rsp.code == "302"
          warn "[relaton-bipm] This source employs anti-DDoS measures that unfortunately affects automated requests."
          warn "[relaton-bipm] Please visit this link in your browser to resolve the CAPTCHA, then retry: #{rsp.uri}"
          # warn "[relaton-bipm] #{rsp.uri} is redirected to #{rsp.header['location']}"
          raise RelatonBib::RequestError, "cannot access #{rsp.uri}"
        elsif rsp.code != "200" && rsp.code != "403"
          warn "[read_bipm] can't acces #{rsp.uri} #{rsp.code}"
          raise RelatonBib::RequestError, "cannot acces #{rsp.uri} #{rsp.code}"
        end
      end
    end
  end
end
