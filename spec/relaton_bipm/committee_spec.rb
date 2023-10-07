RSpec.describe RelatonBipm::Committee do
  before { RelatonBipm.instance_variable_set :@configuration, nil }

  it "warn when an acronym is invalid" do
    expect do
      RelatonBipm::Committee.new acronym: "INVAL"
    end.to output(/Invalid acronym/).to_stderr
  end
end
