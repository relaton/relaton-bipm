describe Relaton::Bipm::ItemData do
  let(:title) { [Relaton::Bib::Title.new(content: "Title")] }
  let(:docid) { [Relaton::Bib::Docidentifier.new(content: "BIPM 123")] }
  let(:note) { [Relaton::Bib::Note.new(content: "Note")] }

  subject do
    described_class.new(
      title: title,
      docidentifier: docid,
      note: note,
    )
  end

  context "#deep_clone" do
    it "creates a deep clone of the object" do
      clone = subject.deep_clone
      expect(clone).to be_a(Relaton::Bipm::ItemData)
      expect(clone).not_to be(subject)
      expect(clone.title).not_to be(subject.title)
      expect(clone.docidentifier).not_to be(subject.docidentifier)
      expect(clone.note).not_to be(subject.note)
      expect(clone.title.first.content).to eq(subject.title.first.content)
      expect(clone.docidentifier.first.content).to eq(subject.docidentifier.first.content)
      expect(clone.note.first.content).to eq(subject.note.first.content)
    end
  end

  context "#to_xml" do
    context "with empty initial notes" do
      subject { described_class.new(title: title, docidentifier: docid) }

      it "renders XML with only additional notes" do
        xml = subject.to_xml(note: [{ content: "Additional Note", type: "additional" }])
        expect(xml).to include("<note type=\"additional\">Additional Note</note>")
      end
    end

    it "renders XML with notes" do
      xml = subject.to_xml(note: [{ content: "Additional Note", type: "additional" }])
      expect(xml).to include("<note type=\"additional\">Additional Note</note>")
    end
  end

  context "#to_yaml" do
    it "renders YAML with notes" do
      yaml = subject.to_yaml(note: [{ content: "Additional Note", type: "additional" }])
      expect(yaml).to include("type: additional")
      expect(yaml).to include("content: Additional Note")
    end
  end

  context "#to_json" do
    it "renders JSON with notes" do
      json = subject.to_json(note: [{ content: "Additional Note", type: "additional" }])
      expect(json).to include('"type":"additional"')
      expect(json).to include('"content":"Additional Note"')
    end
  end
end
