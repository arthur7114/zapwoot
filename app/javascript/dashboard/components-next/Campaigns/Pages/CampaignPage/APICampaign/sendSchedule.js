export const WEEKDAYS = [
  { value: 1, key: 'MON' },
  { value: 2, key: 'TUE' },
  { value: 3, key: 'WED' },
  { value: 4, key: 'THU' },
  { value: 5, key: 'FRI' },
  { value: 6, key: 'SAT' },
  { value: 0, key: 'SUN' },
];

// The id only keys the rows in the UI; serializeSchedule strips it before the API call.
export const buildWindow = (start = '09:00', end = '18:00') => ({
  id: crypto.randomUUID(),
  start,
  end,
});

export const buildDefaultSchedule = () => ({
  timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
  weekdays: [1, 2, 3, 4, 5],
  windows: [buildWindow()],
  excluded_dates: [],
  interval: { min: 30, max: 90 },
  batch_pause: { every: 20, minutes: 10 },
  daily_limit: null,
});

const toNumber = value =>
  value === '' || value === null ? null : Number(value);

// Mirrors Campaigns::SendSchedule#errors so mistakes show inline instead of as a 422 after submit.
export const validateSchedule = schedule => {
  const windowErrors = {};
  const sorted = [...schedule.windows].sort((a, b) =>
    a.start.localeCompare(b.start)
  );
  schedule.windows.forEach(window => {
    if (!window.start || !window.end || window.start >= window.end) {
      windowErrors[window.id] = 'INVALID';
    }
  });
  sorted.forEach((window, index) => {
    const next = sorted[index + 1];
    if (next && next.start < window.end && !windowErrors[next.id]) {
      windowErrors[next.id] = 'OVERLAP';
    }
  });

  const min = toNumber(schedule.interval.min);
  const max = toNumber(schedule.interval.max);
  const every = toNumber(schedule.batch_pause.every) || 0;
  const minutes = toNumber(schedule.batch_pause.minutes);
  const dailyLimit = toNumber(schedule.daily_limit);

  const errors = {
    weekdays: schedule.weekdays.length === 0,
    windows: windowErrors,
    noWindows: schedule.windows.length === 0,
    interval: min === null || min < 0 || (max !== null && max < min),
    batchPause: every < 0 || (every > 0 && !(minutes > 0)),
    dailyLimit: dailyLimit !== null && !(dailyLimit >= 1),
  };

  errors.hasErrors =
    errors.weekdays ||
    errors.noWindows ||
    Object.keys(windowErrors).length > 0 ||
    errors.interval ||
    errors.batchPause ||
    errors.dailyLimit;

  return errors;
};

export const serializeSchedule = schedule => {
  const every = toNumber(schedule.batch_pause.every) || 0;
  return {
    timezone: schedule.timezone,
    weekdays: schedule.weekdays,
    windows: schedule.windows.map(({ start, end }) => ({ start, end })),
    excluded_dates: schedule.excluded_dates,
    interval: {
      min: toNumber(schedule.interval.min) || 0,
      max: toNumber(schedule.interval.max) || 0,
    },
    batch_pause:
      every > 0
        ? { every, minutes: toNumber(schedule.batch_pause.minutes) }
        : null,
    daily_limit: toNumber(schedule.daily_limit),
  };
};

export const getTimezones = () => Intl.supportedValuesOf('timeZone');
