# HKHealthImport

Swift Package to import HealthKit data exported from real hardware. **Work In Progress** as there are some things to polish.

### How to export HealthKit data?

On Health.app,

1. Tap the top right button which will show your profile
2. Scroll to the bottom and tap export.

Depending on the ammount of data you have it will take several minutes and its size is variable. Once finished, AirDrop the resulting file to your Mac and extract its contents.

Structure is as follows,

```
.
├── electrocardiograms
│   ├── ecg_2020-09-23.csv
│   └── ...
├── export_cda.xml
├── export.xml
└── workout-routes
    ├── route_2018-03-07_8.42am.gpx
    └── ...
```

The `export.xml` file naming changes depending on the device's locale and will be translated to the current's device's language.


### Simulator


If you wish to remove the data added to the simulator use the following command on the console.

```bash
xcrun simctl shutdown all; xcrun simctl erase all
```
