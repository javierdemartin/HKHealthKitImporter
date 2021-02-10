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

```xml
<Workout workoutActivityType="HKWorkoutActivityTypeRunning" duration="28.10076753695806" durationUnit="min" totalDistance="4.101117966346867" totalDistanceUnit="km" totalEnergyBurned="273.2946050717617" totalEnergyBurnedUnit="kcal" sourceName="Apple Watch de Javier" sourceVersion="7.2" device="&lt;&lt;HKDevice: 0x280bb4f00&gt;, name:Apple Watch, manufacturer:Apple Inc., model:Watch, hardware:Watch6,2, software:7.2&gt;" creationDate="2021-01-08 19:14:00 +0100" startDate="2021-01-08 18:44:41 +0100" endDate="2021-01-08 19:13:58 +0100">
 <MetadataEntry key="HKIndoorWorkout" value="0"/>
 <MetadataEntry key="HKAverageMETs" value="9.09449 kcal/hr·kg"/>
 <MetadataEntry key="HKWeatherTemperature" value="39.2 degF"/>
 <MetadataEntry key="HKWeatherHumidity" value="6900 %"/>
 <MetadataEntry key="HKTimeZone" value="Europe/Madrid"/>
 <MetadataEntry key="HKElevationAscended" value="1036 cm"/>
 <WorkoutEvent type="HKWorkoutEventTypeSegment" date="2021-01-08 18:44:41 +0100" duration="7.332181878884634" durationUnit="min"/>
 <WorkoutEvent type="HKWorkoutEventTypeSegment" date="2021-01-08 18:44:41 +0100" duration="11.95525238911311" durationUnit="min"/>
 <WorkoutEvent type="HKWorkoutEventTypePause" date="2021-01-08 18:44:41 +0100"/>
 <WorkoutEvent type="HKWorkoutEventTypeMotionPaused" date="2021-01-08 18:44:41 +0100"/>
 <WorkoutEvent type="HKWorkoutEventTypeResume" date="2021-01-08 18:44:46 +0100"/>
 <WorkoutEvent type="HKWorkoutEventTypeMotionResumed" date="2021-01-08 18:44:46 +0100"/>
 <WorkoutEvent type="HKWorkoutEventTypePause" date="2021-01-08 18:48:37 +0100"/>
 <WorkoutEvent type="HKWorkoutEventTypeMotionPaused" date="2021-01-08 18:48:37 +0100"/>
 <WorkoutEvent type="HKWorkoutEventTypeResume" date="2021-01-08 18:49:17 +0100"/>
 <WorkoutEvent type="HKWorkoutEventTypeMotionResumed" date="2021-01-08 18:49:17 +0100"/>
 <WorkoutEvent type="HKWorkoutEventTypeSegment" date="2021-01-08 18:52:01 +0100" duration="7.276928500334422" durationUnit="min"/>
 <WorkoutEvent type="HKWorkoutEventTypePause" date="2021-01-08 18:52:21 +0100"/>
 <WorkoutEvent type="HKWorkoutEventTypeResume" date="2021-01-08 18:52:47 +0100"/>
 <WorkoutEvent type="HKWorkoutEventTypePause" date="2021-01-08 18:52:47 +0100"/>
 <WorkoutEvent type="HKWorkoutEventTypeMotionPaused" date="2021-01-08 18:52:47 +0100"/>
 <WorkoutEvent type="HKWorkoutEventTypeResume" date="2021-01-08 18:52:48 +0100"/>
 <WorkoutEvent type="HKWorkoutEventTypeMotionResumed" date="2021-01-08 18:52:48 +0100"/>
 <WorkoutEvent type="HKWorkoutEventTypeSegment" date="2021-01-08 18:56:38 +0100" duration="11.12899329861005" durationUnit="min"/>
 <WorkoutEvent type="HKWorkoutEventTypeSegment" date="2021-01-08 18:59:18 +0100" duration="7.019823886950811" durationUnit="min"/>
 <WorkoutEvent type="HKWorkoutEventTypeSegment" date="2021-01-08 19:06:19 +0100" duration="6.891412558158239" durationUnit="min"/>
 <WorkoutEvent type="HKWorkoutEventTypeSegment" date="2021-01-08 19:07:46 +0100" duration="6.121000881989797" durationUnit="min"/>
 <WorkoutRoute sourceName="Apple Watch de Javier" sourceVersion="7.2" creationDate="2021-01-08 19:14:01 +0100" startDate="2021-01-08 18:44:41 +0100" endDate="2021-01-08 19:13:58 +0100">
  <MetadataEntry key="HKMetadataKeySyncVersion" value="2"/>
  <MetadataEntry key="HKMetadataKeySyncIdentifier" value="BD7A74D3-350C-44A8-9A2D-8FE2DF99404D"/>
  <FileReference path="/workout-routes/route_2021-01-08_7.13pm.gpx"/>
 </WorkoutRoute>
</Workout>
```

Sample of a workout data 

```xml
<Workout workoutActivityType="HKWorkoutActivityTypeCycling" duration="18.96813208262126" durationUnit="min" totalDistance="4.637590121406164" totalDistanceUnit="km" totalEnergyBurned="92.066" totalEnergyBurnedUnit="kcal" sourceName="Apple Watch de Javier" sourceVersion="4.2.2" creationDate="2018-03-07 08:43:19 +0100" startDate="2018-03-07 08:23:28 +0100" endDate="2018-03-07 08:43:18 +0100">
  <MetadataEntry key="HKTimeZone" value="Europe/Madrid"/>
  <MetadataEntry key="HKWeatherTemperature" value="44 degF"/>
  <MetadataEntry key="HKWeatherHumidity" value="8200 %"/>
  <WorkoutEvent type="HKWorkoutEventTypePause" date="2018-03-07 08:27:20 +0100"/>
  <WorkoutEvent type="HKWorkoutEventTypeResume" date="2018-03-07 08:27:28 +0100"/>
  <WorkoutEvent type="HKWorkoutEventTypePause" date="2018-03-07 08:38:50 +0100"/>
  <WorkoutEvent type="HKWorkoutEventTypeResume" date="2018-03-07 08:39:12 +0100"/>
  <WorkoutEvent type="HKWorkoutEventTypePause" date="2018-03-07 08:42:56 +0100"/>
  <WorkoutRoute sourceName="Apple Watch de Javier" sourceVersion="11.2.6" creationDate="2018-03-07 08:44:26 +0100" startDate="2018-03-07 08:23:29 +0100" endDate="2018-03-07 08:42:55 +0100">
   <MetadataEntry key="HKMetadataKeySyncVersion" value="2"/>
   <MetadataEntry key="HKMetadataKeySyncIdentifier" value="F005A5AA-0C3D-4F76-8F3F-EE24A56D0688"/>
   <FileReference path="/workout-routes/route_2018-03-07_8.42am.gpx"/>
  </WorkoutRoute>
 </Workout>
```


### Simulator


If you wish to remove the data added to the simulator use the following command on the console.

```bash
xcrun simctl shutdown all; xcrun simctl erase all
```

### Caveats

This is still a work in progress and some errors might be raised when dealing with metadata values that haven't been taken care of. If that happens a `_HKObjectValidationFailureException` error will be raised. 

```
*** Terminating app due to uncaught exception '_HKObjectValidationFailureException', reason: 'HKMetadataKeySyncVersion may not be provided if HKMetadataKeySyncIdentifier is not provided in the metadata'
terminating with uncaught exception of type NSException
```
