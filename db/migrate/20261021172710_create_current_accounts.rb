# Column names match the legacy schema (docs/legado-referencia/schema-legado.rb)
# so existing data can be imported without remapping.
class CreateCurrentAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :current_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :cash_account_id, null: false
      t.integer :cost_id, null: false
      t.date :date_ocurrence, null: false
      t.integer :type_launche, null: false
      t.decimal :price, precision: 9, scale: 2, null: false
      t.string :historic

      t.timestamps
    end

    add_index :current_accounts, [ :user_id, :date_ocurrence ]
  end
end
