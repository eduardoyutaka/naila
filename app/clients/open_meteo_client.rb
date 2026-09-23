class OpenMeteoClient < BaseClient
  LATITUDE = -25.4284
  LONGITUDE = -49.2733
  HOURLY_PARAMS = "precipitation,precipitation_probability,temperature_2m,soil_moisture_0_to_7cm,weather_code"

  def call
    response = fetch do |conn|
      conn.get("/v1/forecast", {
        latitude: LATITUDE,
        longitude: LONGITUDE,
        hourly: HOURLY_PARAMS,
        forecast_days: 3,
        timezone: "America/Sao_Paulo"
      })
    end

    return [] unless response

    parse_forecasts(response.body)
  end

  private

  def parse_forecasts(data)
    hourly = data["hourly"]
    return [] unless hourly

    times = hourly["time"]
    precipitation = hourly["precipitation"] || []
    probability = hourly["precipitation_probability"] || []
    temperature = hourly["temperature_2m"] || []
    soil_moisture = hourly["soil_moisture_0_to_7cm"] || []
    weather_code = hourly["weather_code"] || []

    times.each_with_index.map do |time, i|
      valid_from = Time.zone.parse(time)
      valid_until = valid_from + 1.hour

      {
        source: "open_meteo",
        issued_at: Time.current,
        valid_from: valid_from,
        valid_until: valid_until,
        precipitation_mm: (precipitation[i] || 0.0).round(2),
        precipitation_probability: probability[i] || 0,
        temperature_max_c: temperature[i],
        temperature_min_c: temperature[i],
        raw_data: {
          "soil_moisture_avg" => soil_moisture[i]&.round(4),
          "weather_codes" => [ weather_code[i] ].compact
        }
      }
    end
  end
end
