class Directory < ApplicationRecord
  belongs_to :parent, class_name: "Directory", optional: true
  has_many :children, class_name: "Directory", foreign_key: :parent_id, dependent: :destroy
  has_many :file_entries, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :parent_id }

  validate :cannot_be_its_own_parent
  validate :cannot_create_cycle

  def path
    return "/#{name}" unless parent

    "#{parent.path}/#{name}"
  end

  private

  def cannot_be_its_own_parent
    return if parent_id.blank? || id.blank?

    errors.add(:parent, :self_parent) if parent_id == id
  end

  def cannot_create_cycle
    return if parent.nil? || id.blank?

    current = parent

    while current
      if current.id == id
        errors.add(:parent, :cycle_detected)
        break
      end

      current = current.parent
    end
  end
end