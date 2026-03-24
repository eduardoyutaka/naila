class OpenWeatherMapClient < BaseClient
  LATITUDE = -25.4284
  LONGITUDE = -49.2733
  EMPTY_RESULT = { observations: [], forecasts: [] }.freeze

  def call
    api_key = Rails.application.credentials.dig(:open_weather_map, :api_key) || ""

    response = fetch do |conn|
      conn.get("/data/3.0/onecall", {
        lat: LATITUDE,
        lon: LONGITUDE,
        appid: api_key,
        units: "metric",
        lang: "pt_br"
      })
    end

    return EMPTY_RESULT unless response

    data = response.body
    {
      observations: parse_current(data),
      forecasts: parse_hourly(data)
    }
  end

  private

  def parse_current(data)
    current = data["current"]
    return [] unless current

    [{
      source: "open_weather_map",
      observed_at: Time.zone.at(current["dt"]),
      temperature_c: current["temp"],
      humidity_pct: current["humidity"],
      pressure_hpa: current["pressure"],
      wind_speed_ms: current["wind_speed"],
      wind_direction_deg: current["wind_deg"],
      precipitation_mm: current.dig("rain", "1h") || 0.0,
      weather_condition: current.dig("weather", 0, "description"),
      raw_data: current
    }]
  end

  def parse_hourly(data)
    hourly = data["hourly"]
    return [] unless hourly

    hourly.map do |hour|
      dt = Time.zone.at(hour["dt"])
      {
        source: "open_weather_map",
        issued_at: Time.current,
        valid_from: dt,
        valid_until: dt + 1.hour,
        precipitation_mm: hour.dig("rain", "1h") || 0.0,
        precipitation_probability: (hour["pop"] || 0) * 100,
        temperature_max_c: hour["temp"],
        temperature_min_c: hour["temp"],
        raw_data: hour
      }
    end
  end
end
