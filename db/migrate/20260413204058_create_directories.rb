class CreateDirectories < ActiveRecord::Migration[8.1]
  def change
    create_table :directories do |t|
      t.string :name, null: false
      t.references :parent, null: true, foreign_key: { to_table: :directories }

      t.timestamps
    end

    add_index :directories, [:parent_id, :name], unique: true
  end
end