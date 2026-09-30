# Sending rules for drip campaigns: which weekdays, which time windows, which dates are off-limits and how fast messages go out.
#
#   timezone:       IANA name, e.g. 'America/Sao_Paulo'
#   weekdays:       allowed days, 0 (Sunday) to 6 (Saturday)
#   windows:        [{ 'start' => '09:00', 'end' => '12:00' }, ...]; empty means the whole day
#   excluded_dates: ['2026-12-25', ...]
#   interval:       { 'min' => 30, 'max' => 90 } seconds between messages, picked at random
#   batch_pause:    { 'every' => 20, 'minutes' => 15 } extra rest after every N messages
#   daily_limit:    max messages per day
class Campaigns::SendSchedule
  DEFAULT_WEEKDAYS = [1, 2, 3, 4, 5].freeze
  TIME_FORMAT = /\A([01]\d|2[0-3]):[0-5]\d\z/
  DATE_FORMAT = /\A\d{4}-\d{2}-\d{2}\z/
  LOOKAHEAD_DAYS = 400

  def initialize(config)
    @config = (config || {}).with_indifferent_access
  end

  def errors
    [timezone_error, weekday_error, window_errors, date_errors, interval_error, batch_pause_error, daily_limit_error].flatten.compact
  end

  def zone
    ActiveSupport::TimeZone[@config[:timezone].presence || 'UTC']
  end

  def weekdays
    Array(@config[:weekdays].presence || DEFAULT_WEEKDAYS).map(&:to_i)
  end

  def windows
    Array(@config[:windows]).map { |window| [window[:start], window[:end]] }.sort
  end

  def excluded_dates
    Array(@config[:excluded_dates]).map(&:to_s)
  end

  def daily_limit
    @config[:daily_limit].to_i if @config[:daily_limit].present?
  end

  # The moment the campaign may send, starting from `time`: `time` itself when it falls inside a window, otherwise the next window start.
  def next_allowed_at(time)
    local = time.in_time_zone(zone)
    LOOKAHEAD_DAYS.times do |offset|
      date = local.to_date + offset
      next unless day_allowed?(date)

      slot = slot_on(date, local)
      return slot if slot
    end
    nil
  end

  def next_day_start(time)
    next_allowed_at(time.in_time_zone(zone).tomorrow.beginning_of_day)
  end

  def day_range(time)
    local = time.in_time_zone(zone)
    local.all_day
  end

  def delay_after(processed_count)
    delay = rand(interval_min..interval_max)
    delay += batch_pause_seconds if batch_pause_due?(processed_count)
    delay
  end

  private

  def day_allowed?(date)
    weekdays.include?(date.wday) && excluded_dates.exclude?(date.iso8601)
  end

  def slot_on(date, local)
    return [local, date.in_time_zone(zone).beginning_of_day].max if windows.empty?

    windows.each do |start_at, end_at|
      window_end = zone.parse("#{date} #{end_at}")
      return [local, zone.parse("#{date} #{start_at}")].max if local < window_end
    end
    nil
  end

  def interval_min
    (@config.dig(:interval, :min) || 0).to_i
  end

  def interval_max
    [(@config.dig(:interval, :max) || interval_min).to_i, interval_min].max
  end

  def batch_pause_due?(processed_count)
    every = @config.dig(:batch_pause, :every).to_i
    every.positive? && (processed_count % every).zero?
  end

  def batch_pause_seconds
    @config.dig(:batch_pause, :minutes).to_i * 60
  end

  def timezone_error
    'timezone is invalid' if @config[:timezone].present? && ActiveSupport::TimeZone[@config[:timezone]].nil?
  end

  def weekday_error
    'weekdays must be between 0 and 6 and cannot be empty' unless weekdays.any? && weekdays.all? { |day| day.between?(0, 6) }
  end

  def window_errors
    Array(@config[:windows]).map do |window|
      valid = window[:start].to_s.match?(TIME_FORMAT) && window[:end].to_s.match?(TIME_FORMAT) && window[:start] < window[:end]
      "window #{window[:start]}-#{window[:end]} is invalid" unless valid
    end
  end

  def date_errors
    excluded_dates.filter_map do |date|
      "excluded date #{date} is invalid" unless date.match?(DATE_FORMAT) && Date.valid_date?(*date.split('-').map(&:to_i))
    end
  end

  def interval_error
    'interval must be zero or more seconds' if interval_min.negative?
  end

  def batch_pause_error
    return if @config[:batch_pause].blank?

    'batch_pause needs a positive every and minutes' unless @config.dig(:batch_pause, :every).to_i.positive? && batch_pause_seconds >= 0
  end

  def daily_limit_error
    'daily_limit must be positive' if @config[:daily_limit].present? && !@config[:daily_limit].to_i.positive?
  end
end
