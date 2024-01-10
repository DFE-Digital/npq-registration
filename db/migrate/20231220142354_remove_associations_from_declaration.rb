class RemoveAssociationsFromDeclaration < ActiveRecord::Migration[7.0]
  def up
    remove_reference :declarations, :user, foreign_key: true
    remove_reference :declarations, :course, foreign_key: true
    remove_reference :declarations, :lead_provider, foreign_key: true
  end

  def down
    add_reference :declarations, :user, foreign_key: true
    add_reference :declarations, :course, foreign_key: true
    add_reference :declarations, :lead_provider, foreign_key: true
  end
end
