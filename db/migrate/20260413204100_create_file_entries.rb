class CreateFileEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :file_entries do |t|
      t.string :name, null: false
      t.references :directory, null: false, foreign_key: true

      t.timestamps
    end

    add_index :file_entries, [:directory_id, :name], unique: true
  end
end