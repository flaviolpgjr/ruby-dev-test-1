require "fileutils"
require "stringio"

namespace :filesystem do
  desc "Demonstra a criação de diretórios, arquivos e persistência no storage local"
  task demo: :environment do
    def cleanup_storage!
      FileUtils.rm_rf(Rails.root.join("storage"))
      FileUtils.rm_rf(Rails.root.join("tmp/storage"))
      FileUtils.mkdir_p(Rails.root.join("storage"))
      FileUtils.mkdir_p(Rails.root.join("tmp/storage"))
    end

    begin
      puts "Limpando dados anteriores..."
      ActiveStorage::Attachment.delete_all
      ActiveStorage::Blob.delete_all
      FileEntry.delete_all
      Directory.delete_all
      cleanup_storage!

      puts "\n== Criando estrutura de diretórios =="
      root = Directory.create!(name: "root")
      docs = Directory.create!(name: "docs", parent: root)
      invoices = Directory.create!(name: "invoices", parent: docs)

      puts "Diretório raiz: #{root.path}"
      puts "Subdiretório: #{docs.path}"
      puts "Subdiretório aninhado: #{invoices.path}"

      puts "\n== Criando arquivos =="
      report = FileEntry.create!(name: "report.txt", directory: docs)
      invoice = FileEntry.create!(name: "invoice-001.txt", directory: invoices)

      report.content.attach(
        io: StringIO.new("Conteúdo do relatório"),
        filename: "report.txt",
        content_type: "text/plain"
      )

      invoice.content.attach(
        io: StringIO.new("Conteúdo da fatura"),
        filename: "invoice-001.txt",
        content_type: "text/plain"
      )

      puts "Arquivo 1: #{report.path}"
      puts "Arquivo 2: #{invoice.path}"

      puts "\n== Validando persistência no storage =="
      puts "Report attached? #{report.content.attached?}"
      puts "Invoice attached? #{invoice.content.attached?}"

      if ActiveStorage::Blob.service.is_a?(ActiveStorage::Service::DiskService)
        report_storage_path = ActiveStorage::Blob.service.send(:path_for, report.content.blob.key)
        invoice_storage_path = ActiveStorage::Blob.service.send(:path_for, invoice.content.blob.key)

        puts "Report storage path: #{report_storage_path}"
        puts "Report exists on disk? #{::File.exist?(report_storage_path)}"

        puts "Invoice storage path: #{invoice_storage_path}"
        puts "Invoice exists on disk? #{::File.exist?(invoice_storage_path)}"
      end

      puts "\n== Validando duplicidade de diretório no mesmo pai =="
      duplicated_directory = Directory.new(name: "docs", parent: root)
      if duplicated_directory.valid?
        puts "ERRO: diretório duplicado deveria ser inválido"
      else
        puts duplicated_directory.errors.full_messages.join(", ")
      end

      puts "\n== Validando duplicidade de arquivo no mesmo diretório =="
      duplicated_file = FileEntry.new(name: "report.txt", directory: docs)
      if duplicated_file.valid?
        puts "ERRO: arquivo duplicado deveria ser inválido"
      else
        puts duplicated_file.errors.full_messages.join(", ")
      end

      puts "\n== Validando self-parent =="
      root.parent = root
      if root.valid?
        puts "ERRO: self-parent deveria ser inválido"
      else
        puts root.errors.full_messages.join(", ")
      end
      root.parent = nil

      puts "\n== Validando ciclo na hierarquia =="
      root.parent = invoices
      if root.valid?
        puts "ERRO: ciclo deveria ser inválido"
      else
        puts root.errors.full_messages.join(", ")
      end

      puts "\nDemo finalizada com sucesso."
    ensure
      puts "\nLimpando arquivos e dados gerados pela demo..."
      ActiveStorage::Attachment.delete_all
      ActiveStorage::Blob.delete_all
      FileEntry.delete_all
      Directory.delete_all
      cleanup_storage!
      puts "Limpeza concluída."
    end
  end
end