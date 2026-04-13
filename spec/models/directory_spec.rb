require "rails_helper"

RSpec.describe Directory, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:parent).class_name("Directory").optional }
    it { is_expected.to have_many(:children).class_name("Directory").with_foreign_key(:parent_id).dependent(:destroy) }
    it { is_expected.to have_many(:file_entries).dependent(:destroy) }
  end

  describe "validations" do
    it "is invalid without a name" do
      directory = described_class.new(name: nil)

      expect(directory).not_to be_valid
      expect(directory.errors[:name]).to include("não pode ficar em branco")
    end

    it "allows directories with the same name under different parents" do
      root_a = described_class.create!(name: "root_a")
      root_b = described_class.create!(name: "root_b")

      described_class.create!(name: "docs", parent: root_a)
      directory = described_class.new(name: "docs", parent: root_b)

      expect(directory).to be_valid
    end

    it "does not allow directories with the same name under the same parent" do
      root = described_class.create!(name: "root")
      described_class.create!(name: "docs", parent: root)

      directory = described_class.new(name: "docs", parent: root)

      expect(directory).not_to be_valid
      expect(directory.errors[:name]).to include("já está em uso neste diretório")
    end

    it "does not allow a directory to be its own parent" do
      directory = described_class.create!(name: "root")

      directory.parent = directory

      expect(directory).not_to be_valid
      expect(directory.errors[:parent]).to include("não pode ser pai de si mesmo")
    end

    it "does not allow cycles in the hierarchy" do
      root = described_class.create!(name: "root")
      child = described_class.create!(name: "child", parent: root)
      grandchild = described_class.create!(name: "grandchild", parent: child)

      root.parent = grandchild

      expect(root).not_to be_valid
      expect(root.errors[:parent]).to include("não pode criar um ciclo na hierarquia")
    end
  end

  describe "#path" do
    it "returns the path for a root directory" do
      directory = described_class.create!(name: "root")

      expect(directory.path).to eq("/root")
    end

    it "returns the full path for a nested directory" do
      root = described_class.create!(name: "root")
      docs = described_class.create!(name: "docs", parent: root)
      invoices = described_class.create!(name: "invoices", parent: docs)

      expect(invoices.path).to eq("/root/docs/invoices")
    end
  end
end