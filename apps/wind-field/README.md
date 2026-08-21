# Wind Field

A private Garmin Edge 540 cycling data field that displays forecast wind at the
rider's current position.

## Behavior

- Downloads Open-Meteo wind speed, direction, and gust every 15 minutes.
- Retries failed downloads after 60 seconds while retaining the last good data.
- Uses the Edge's GPS track, with heading as a fallback, once per second.
- Smooths heading changes with a circular exponential filter.
- Points the arrow toward the direction the wind comes from:
  - arrow up: headwind
  - arrow down: tailwind
  - arrow right: wind from the rider's right
  - arrow left: wind from the rider's left
- Uses a full visual layout when given a large data-field slot and a compact
  layout in smaller slots.

Wind speed is currently shown in mph. Current conditions come from Open-Meteo's
free non-commercial API and are based on 15-minute weather model data.

## Project files

- `source/WindFieldApp.mc` — application entry point
- `source/WindFieldView.mc` — activity input, networking, and rendering
- `source/WindMath.mc` — relative-angle, smoothing, and labeling logic
- `test/WindMathTest.mc` — Connect IQ unit tests for direction math

## Privacy

Each weather request sends the current latitude and longitude directly to
Open-Meteo through Garmin Connect Mobile's communications layer. No account or
API key is used.
