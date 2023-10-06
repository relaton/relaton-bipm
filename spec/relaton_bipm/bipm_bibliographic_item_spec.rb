RSpec.describe RelatonBipm::BipmBibliographicItem do
  before { RelatonBipm.instance_variable_set :@configuration, nil }

  it "warn when si_aspect is invalid" do
    expect do
      RelatonBipm::BipmBibliographicItem.new si_aspect: "aspect"
    end.to output(/\[relaton-bipm\] WARNING: invalid si_aspect/).to_stderr
  end

  it "warning when docstatus is invalid" do
    expect do
      RelatonBipm::BipmBibliographicItem.new docstatus: RelatonBib::DocumentStatus.new(stage: "status")
    end.to output(/\[relaton-bipm\] WARNING: invalid docstatus: `status`/).to_stderr
  end

  context "doctypes" do
    shared_examples "allowed doctype" do |doctype|
      it do
        expect do
          RelatonBipm::BipmBibliographicItem.new doctype: doctype
        end.not_to output(/\[relaton-bipm\] WARNING: invalid doctype/).to_stderr
      end
    end

    it_behaves_like "allowed doctype", "brochure"
  end
end
