class CreateCoupons < ActiveRecord::Migration[7.1]
  def change
    create_table :coupons do |t|
      t.string :name
      t.string :code
      t.decimal :value
      t.string :value_type
      t.boolean :active
      t.references :merchant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
