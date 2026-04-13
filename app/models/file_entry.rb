class FileEntry < ApplicationRecord
  belongs_to :directory
  has_one_attached :content

  validates :name, presence: true, uniqueness: { scope: :directory_id }
  validates :directory, presence: true

  def path
    "#{directory.path}/#{name}"
  end
end