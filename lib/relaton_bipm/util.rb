module RelatonBipm
  module Util
    extend RelatonBib::Util

    def self.logger
      RelatonBipm.configuration.logger
    end
  end
end
