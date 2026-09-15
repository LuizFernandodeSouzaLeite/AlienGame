class RemoveStringFromAliens < ActiveRecord::Migration[8.1]
  def change
    remove_column :aliens, :string, :string
  end
end
