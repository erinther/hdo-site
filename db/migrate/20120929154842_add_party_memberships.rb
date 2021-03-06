class AddPartyMemberships < ActiveRecord::Migration
  def up
    create_table :party_memberships do |t|
      t.references :representative, :party, null: false
      t.date :start_date, null: false
      t.date :end_date, default: nil

      t.timestamps
    end

    add_index :party_memberships, [:representative_id, :party_id, :start_date, :end_date], name: "index_party_memberships_on_all"

    # move data to the new relation
    # no way of knowing what dates we *should* be adding, so just assume what's valid when this migration was written
    start_date = Date.new(2011, 10, 1).strftime("%Y-%m-%d")

    execute <<-SQL
      INSERT INTO party_memberships (representative_id, party_id, start_date, created_at, updated_at)
      SELECT id, party_id, date('#{start_date}'), NOW(), NOW() FROM representatives
    SQL

    remove_column :representatives, :party_id
  end

  def down
    add_column :representatives, :party_id, :integer

    # we're bound to lose data here, just keep the most recent association

    execute <<-SQL
      UPDATE representatives
      SET party_id = ( SELECT party_memberships.party_id
                       FROM party_memberships
                       WHERE party_memberships.representative_id = representatives.id
                       ORDER BY start_date DESC LIMIT 1)
    SQL

    remove_index :party_memberships, name: "index_party_memberships_on_all"
    drop_table :party_memberships
  end

end
