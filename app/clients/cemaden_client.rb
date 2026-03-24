class CemadenClient < BaseClient
  MUNICIPIO_CODE = "4106902" # Curitiba

  def call
    response = fetch do |conn|
      conn.get("/resources/dados/#{MUNICIPIO_CODE}")
    end

    return [] unless response

    parse_readings(response.body)
  end

  private

  def parse_readings(data)
    stations = data["estacoes"]
    return [] unless stations.is_a?(Array)

    stations.flat_map do |station|
      station_code = station["codEstacao"]
      medicoes = station["medicoes"]
      next [] unless medicoes.is_a?(Array)

      medicoes.filter_map do |medicao|
        recorded_at = Time.zone.parse(medicao["dataHora"])
        next unless recorded_at

        {
          source: "cemaden",
          station_code: station_code,
          value: medicao["valor"]&.to_f,
          unit: "mm",
          reading_type: "precipitation",
          recorded_at: recorded_at,
          raw_data: medicao
        }
      end
    end
  end
end
