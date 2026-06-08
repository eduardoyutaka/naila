class NormalizeMonitoringStationNames < ActiveRecord::Migration[8.1]
  # Strip a trailing parenthetical (e.g. "Estação Umbará (bacia Iguaçu)") from
  # station names — the basin is already shown via the station's association, so
  # the suffix is redundant noise for users. Only touches names that end in a
  # parenthetical group; everything else is left untouched.
  def up
    execute <<~SQL.squish
      UPDATE monitoring_stations
      SET name = regexp_replace(name, '\\s*\\([^)]*\\)\\s*$', '')
      WHERE name ~ '\\([^)]*\\)\\s*$'
    SQL
  end

  def down
    # Irreversible: the original parentheticals are not recoverable.
  end
end
