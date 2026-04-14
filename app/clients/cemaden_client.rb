class CemadenClient < BaseClient
  FETCH_HOURS = 24

  # Fetches hourly accumulated precipitation for a single CEMADEN station.
  # station_code is the numeric idEstacao (e.g. "6873") used by the
  # MapaInterativoWS endpoint, stored on MonitoringStation#external_id.
  def call(station_code:)
    response = fetch do |conn|
      conn.get("/MapaInterativoWS/resources/horario/#{station_code}/#{FETCH_HOURS}")
    end

    return [] unless response

    parse_readings(response.body, station_code: station_code)
  end

  private

  def parse_readings(data, station_code:)
    horarios = data["horarios"]
    datas = data["datas"]
    acumulados = data["acumulados"]

    return [] unless horarios.is_a?(Array) && datas.is_a?(Array) && acumulados.is_a?(Array)

    datas.each_with_index.flat_map do |date_str, date_idx|
      row = acumulados[date_idx]
      next [] unless row.is_a?(Array)

      row.each_with_index.filter_map do |value, hour_idx|
        next if value.nil?

        recorded_at = parse_timestamp(date_str, horarios[hour_idx])
        next unless recorded_at

        {
          source: "cemaden",
          station_code: station_code,
          value: value.to_f,
          unit: "mm",
          reading_type: "precipitation",
          recorded_at: recorded_at,
          raw_data: { date: date_str, hour: horarios[hour_idx], value: value }
        }
      end
    end
  end

  def parse_timestamp(date_str, hour_str)
    return nil unless date_str && hour_str

    day, month, year = date_str.split("/")
    hour = hour_str.to_s.delete("h").to_i
    Time.zone.local(year.to_i, month.to_i, day.to_i, hour, 0, 0)
  rescue ArgumentError
    nil
  end
end
