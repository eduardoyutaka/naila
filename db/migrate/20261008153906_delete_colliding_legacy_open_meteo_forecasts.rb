class DeleteCollidingLegacyOpenMeteoForecasts < ActiveRecord::Migration[8.1]
  def up
    # Before the hourly switch (8c699cd), Open-Meteo forecasts were bucketed into
    # 3-hour windows. find_or_create_by! keys on (source, valid_from, valid_until),
    # so a legacy 3-hour row isn't replaced by an hourly row sharing its valid_from
    # — both linger with the same valid_from, duplicating that timestamp on any
    # chart/query spanning the switchover. Only deletes rows that actually collide
    # with a newer hourly row (same source + valid_from, 1-hour window) — this is
    # the narrow set of forecasts in flight at deploy time, not Open-Meteo's wider
    # pre-switch history, which has no colliding row and stays untouched.
    execute <<~SQL
      DELETE FROM weather_forecasts a
      WHERE a.source = 'open_meteo'
        AND EXTRACT(EPOCH FROM (a.valid_until - a.valid_from)) > 3600
        AND EXISTS (
          SELECT 1 FROM weather_forecasts b
          WHERE b.source = a.source
            AND b.valid_from = a.valid_from
            AND EXTRACT(EPOCH FROM (b.valid_until - b.valid_from)) = 3600
        )
    SQL
  end

  def down
    # Deleted rows can't be reconstructed (down is a no-op) — this is a one-way
    # cleanup of rows superseded by hourly data.
  end
end
