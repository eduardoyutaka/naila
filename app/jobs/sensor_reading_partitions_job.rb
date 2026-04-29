class SensorReadingPartitionsJob < ApplicationJob
  queue_as :default

  LOOKAHEAD_MONTHS = 3

  def perform
    LOOKAHEAD_MONTHS.times do |offset|
      start_date = Date.current.beginning_of_month + offset.months
      end_date   = start_date.next_month
      partition  = "sensor_readings_#{start_date.year}_#{format('%02d', start_date.month)}"

      ActiveRecord::Base.connection.execute <<~SQL
        CREATE TABLE IF NOT EXISTS #{partition} PARTITION OF sensor_readings
        FOR VALUES FROM ('#{start_date}') TO ('#{end_date}');
      SQL
    end
  end
end
