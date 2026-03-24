class InmetClient < BaseClient
  def call(station_code:)
    today = Date.current.strftime("%Y-%m-%d")

    response = fetch do |conn|
      conn.get("/estacao/dados/#{today}/#{station_code}")
    end

    return [] unless response

    parse_observations(response.body, station_code)
  end

  private

  def parse_observations(data, station_code)
    return [] unless data.is_a?(Array)

    data.filter_map do |reading|
      date = reading["DT_MEDICAO"]
      hour = reading["HR_MEDICAO"]
      next unless date && hour

      observed_at = Time.zone.parse("#{date} #{hour[0..1]}:#{hour[2..3]}:00")

      {
        source: "inmet",
        station_code: station_code,
        observed_at: observed_at,
        temperature_c: reading["TEM_INS"]&.to_f,
        humidity_pct: reading["UMD_INS"]&.to_f,
        pressure_hpa: reading["PRE_INS"]&.to_f,
        wind_speed_ms: reading["VEN_VEL"]&.to_f,
        wind_direction_deg: reading["VEN_DIR"]&.to_f,
        precipitation_mm: reading["CHUVA"]&.to_f,
        raw_data: reading
      }
    end
  end
end
