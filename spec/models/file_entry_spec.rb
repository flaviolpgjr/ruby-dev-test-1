require "rails_helper"

RSpec.describe FileEntry, type: :model do
  let!(:directory) { Directory.create!(name: "root") }

  describe "associations" do
    it { is_expected.to belong_to(:directory) }
    it { is_expected.to have_one_attached(:content) }
  end

  describe "validations" do
    it "is invalid without a name" do
      file_entry = described_class.new(name: nil, directory: directory)

      expect(file_entry).not_to be_valid
      expect(file_entry.errors[:name]).to include("não pode ficar em branco")
    end

    it "is invalid without a directory" do
      file_entry = described_class.new(name: "report.pdf", directory: nil)

      expect(file_entry).not_to be_valid
      expect(file_entry.errors[:directory]).to include("deve ser informado")
    end

    it "allows files with the same name in different directories" do
      other_directory = Directory.create!(name: "docs")

      described_class.create!(name: "report.pdf", directory: directory)
      file_entry = described_class.new(name: "report.pdf", directory: other_directory)

      expect(file_entry).to be_valid
    end

    it "does not allow files with the same name in the same directory" do
      described_class.create!(name: "report.pdf", directory: directory)
      file_entry = described_class.new(name: "report.pdf", directory: directory)

      expect(file_entry).not_to be_valid
      expect(file_entry.errors[:name]).to include("já está em uso neste diretório")
    end
  end

  describe "#path" do
    it "returns the full path of the file" do
      file_entry = described_class.create!(name: "report.pdf", directory: directory)

      expect(file_entry.path).to eq("/root/report.pdf")
    end

    it "returns the full nested path of the file" do
      docs = Directory.create!(name: "docs", parent: directory)
      file_entry = described_class.create!(name: "report.pdf", directory: docs)

      expect(file_entry.path).to eq("/root/docs/report.pdf")
    end
  end

  describe "content attachment" do
    it "allows attaching content to the file entry" do
      file_entry = described_class.create!(name: "report.txt", directory: directory)

      file_entry.content.attach(
        io: StringIO.new("conteúdo do arquivo"),
        filename: "report.txt",
        content_type: "text/plain"
      )

      expect(file_entry.content).to be_attached
      expect(file_entry.content.filename.to_s).to eq("report.txt")
      expect(file_entry.content.content_type).to eq("text/plain")
      downloaded_content = file_entry.content.download.force_encoding("UTF-8")
      expect(downloaded_content).to eq("conteúdo do arquivo")
    end

    it "persists the attachment after reloading the record" do
      file_entry = described_class.create!(name: "report.txt", directory: directory)

      file_entry.content.attach(
        io: StringIO.new("conteúdo persistido"),
        filename: "report.txt",
        content_type: "text/plain"
      )

      file_entry.reload

      downloaded_content = file_entry.content.download.force_encoding("UTF-8")
      expect(downloaded_content).to eq("conteúdo persistido")
    end

    it "stores the file using active storage service" do
      file_entry = described_class.create!(name: "report.txt", directory: directory)

      file_entry.content.attach(
        io: StringIO.new("conteúdo físico"),
        filename: "report.txt",
        content_type: "text/plain"
      )

      expect(file_entry.content.blob.key).to be_present
    end
  end
end