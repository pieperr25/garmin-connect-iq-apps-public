# Drivetrain Friction Governor

Standalone Garmin Connect IQ data field for warning a rider about cross-chaining from electronic-shifting data.

## Threat states

- **Normal:** rear-gear index follows the Edge's global daytime/nighttime data-field theme.
- **Yellow:** black on yellow for big ring/rear 3 or small ring/rear 10. A Normal-to-Yellow transition plays one quick double beep; Red-to-Yellow is silent.
- **Red:** black on red for big ring/rear 1–2 or small ring/rear 11–12. A quick double beep plays for each shift farther into Red: big-ring 3→2 and 2→1, or small-ring 10→11 and 11→12.

The same alert applies to a chainring shift with automatic rear-derailleur compensation. For example, a small-to-big shift that changes the rear index from 4 to 2 enters Red and plays the double beep; the corresponding big-to-small compensated shift is handled symmetrically. Front and rear derailleur readings can arrive in either order without suppressing the alert.

Rear index 1 is the largest cog and rear index 12 is the smallest cog. A missing or out-of-range rear index is displayed as `--`; missing shifting data is treated as Normal.

## Performance

All shifting reads, state evaluation, transition detection, and display-string selection occur in `compute()`. Tone profiles, the tone options dictionary, rear-index strings, and prior-gear tracking are allocated once in `initialize()`. `onUpdate()` only clears its data-field device context and draws cached state; the app never requests a redraw.

## Supported devices

Edge 530, 540, 830, 840, 1030 Plus, and 1040. The minimum API level is 3.1.0 because the preallocated custom double-tone profile uses `Attention.ToneProfile`.
