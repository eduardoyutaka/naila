class OpenMeteoClient < BaseClient
  LATITUDE = -25.4284
  LONGITUDE = -49.2733
  BUCKET_HOURS = 3
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

    times.each_slice(BUCKET_HOURS).with_index.map do |bucket_times, _index|
      offset = bucket_times.first ? times.index(bucket_times.first) : 0
      bucket_size = bucket_times.size

      precip_slice = precipitation[offset, bucket_size] || []
      prob_slice = probability[offset, bucket_size] || []
      temp_slice = temperature[offset, bucket_size] || []
      soil_slice = soil_moisture[offset, bucket_size] || []

      valid_from = Time.zone.parse(bucket_times.first)
      valid_until = valid_from + BUCKET_HOURS.hours

      {
        source: "open_meteo",
        issued_at: Time.current,
        valid_from: valid_from,
        valid_until: valid_until,
        precipitation_mm: precip_slice.sum.round(2),
        precipitation_probability: prob_slice.max || 0,
        temperature_max_c: temp_slice.max,
        temperature_min_c: temp_slice.min,
        raw_data: {
          "soil_moisture_avg" => soil_slice.any? ? (soil_slice.sum / soil_slice.size).round(4) : nil,
          "hours" => bucket_times.size,
          "weather_codes" => hourly["weather_code"]&.slice(offset, bucket_size)
        }
      }
    end
  end
end
