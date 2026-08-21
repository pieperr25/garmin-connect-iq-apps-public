# Development setup

## Required software

1. Install Garmin's Connect IQ SDK Manager from the
   [Connect IQ SDK page](https://developer.garmin.com/connect-iq/sdk/).
2. In SDK Manager, install the current SDK and the Edge 540 device definition.
3. Install Visual Studio Code and Garmin's Monkey C extension.
4. Generate a developer key when prompted by the extension. Developer keys are
   excluded from this repository.

## Build and run

Open `apps/wind-field` in VS Code and use the Monkey C extension to run the data
field in the Edge 540 simulator.

Command-line builds use the SDK selected by SDK Manager:

```sh
monkeyc -d edge540 -f apps/wind-field/monkey.jungle \
  -o apps/wind-field/bin/WindField.prg -y /path/to/developer_key.der
```

To sideload, build for the Edge 540 and copy `WindField.prg` to `GARMIN/APPS` on
the device over USB.
