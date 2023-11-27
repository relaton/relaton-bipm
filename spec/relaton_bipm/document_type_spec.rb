describe RelatonBipm::DocumentType do
  context "when doctype is valid" do
    shared_examples "allowed doctype" do |doctype|
      it do
        expect do
          described_class.new type: doctype
        end.not_to output(/\[relaton-bipm\] WARNING: invalid doctype/).to_stderr
      end
    end

    it_behaves_like "allowed doctype", "brochure"
    it_behaves_like "allowed doctype", "mise-en-pratique"
    it_behaves_like "allowed doctype", "rapport"
    it_behaves_like "allowed doctype", "monographie"
    it_behaves_like "allowed doctype", "guide"
    it_behaves_like "allowed doctype", "meeting-report"
    it_behaves_like "allowed doctype", "technical-report"
    it_behaves_like "allowed doctype", "working-party-note"
    it_behaves_like "allowed doctype", "strategy"
    it_behaves_like "allowed doctype", "cipm-mra"
    it_behaves_like "allowed doctype", "resolutions"
  end

  # it "warn when doctype is invalid" do
  #   expect do
  #     described_class.new type: "aspect"
  #   end.to output(/\[relaton-bipm\] WARNING: invalid doctype: `aspect`/).to_stderr_from_any_process
  # end
end
