describe RelatonBipm do
  after { RelatonBipm.instance_variable_set :@configuration, nil }

  it "configure" do
    RelatonBipm.configure do |conf|
      conf.logger = :logger
    end
    expect(RelatonBipm.configuration.logger).to eq :logger
  end
end
