module RelatonBipm
  module RawdataBipmMetrologia
    class Affiliations
      attr_reader :affiliations

      #
      # Initialize parser
      #
      # @param [Array<RelatonBib::Affiliation>] affiliations directory with affiliations
      #
      def initialize(affiliations)
        @affiliations = affiliations
      end

      #
      # Parse affiliations
      #
      # @return [RelatonBipm::RawdataBipmMetrologia::Affiliations] affiliations
      #
      def self.parse(dir)
        affiliations = Dir["#{dir}/*.xml"].each_with_object([]) do |path, m|
          doc = Nokogiri::XML(File.read(path, encoding: "UTF-8"))
          doc.xpath("//aff").each do |aff|
            m << parse_affiliation(aff) if aff.at("institution")
          end
        end.uniq { |a| a.organization.name.first.content }
        new affiliations
      end

      #
      # Parse affiliation organization
      # https://github.com/relaton/relaton-data-bipm/issues/17#issuecomment-1367035444
      #
      # @param [Nokogiri::XML::Element] aff
      #
      # @return [RelatonBib::Affiliation] Organization name, country, division, street address
      #
      def self.parse_affiliation(aff)
        text = aff.at("text()").text
        return if text.include? "Permanent address:" || text.include?("1005 Southover Lane") ||
          text == "Germany" || text.starts_with?("Guest") || text.starts_with?("Deceased") ||
          text.include?("Author to whom any correspondence should be addressed")

        args = {}
        institution = aff.at('institution')
        if institution
          name = institution.text
          return if name == "1005 Southover Lane"

          args[:subdivision] = parse_division(aff)
          args[:contact] = parse_address(aff)
        else
        #   div, name, city, country = aff.xpath("text()").text.strip.split(", ")
        #   div, name = name, div if name.nil?
        #   args[:subdivision] = [RelatonBib::LocalizedString.new(div)] if div
        #   args[:contact] = [RelatonBib::Address.new(city: city, country: country)] if city && country
          name = aff.text
        end
        args[:name] = [RelatonBib::LocalizedString.new(name)]
        org = RelatonBib::Organization.new(**args)
        RelatonBib::Affiliation.new(organization: org)
      end

      def self.parse_division(aff)
        div = aff.xpath("text()[following-sibling::institution]").text.gsub(/^\W*|\W*$/, "")
        return [] if div.empty?

        [RelatonBib::LocalizedString.new(div)]
      end

      def self.parse_address(aff)
        address = []
        addr = aff.xpath("text()[preceding-sibling::institution]").text.gsub(/^\W*|\W*$/, "")
        address << addr unless addr.empty?
        country = aff.at('country')
        address << country.text if country && !country.text.empty?
        address = address.join(", ")
        return [] if address.empty?

        [RelatonBib::Address.new(formatted_address: address)]
      end

      def self.parse_elements(aff)
        elements = aff.xpath("text()").text.strip.split(", ")
        case elements.size
        when 1 then { name: RelatonBib::LocalizedString.new(elements[0]) }
        when 2
          # name, country
          { name: RelatonBib::LocalizedString.new(elements[0]),
            contact: [RelatonBib::Address.new(formatted_address: elements[1])] }
        when 3
          # it can be name, country, city or name, city, country
          # so use formatted_address instead of city and country
          { name: RelatonBib::LocalizedString.new(elements[0]),
            contact: RelatonBib::Address.new(formatted_address: elements[1, 2].join(", ")) }
        end
      end

      #
      # Find affiliation by organization name
      #
      # @param [Strign] text string with organization name in it
      #
      # @return [RelatonBib::Affiliation]
      #
      def find(text)
        @affiliations.select { |a| text.include?(a.organization.name[0].content) }.sort.last
      end
    end
  end
end
