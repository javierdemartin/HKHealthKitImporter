import HealthKit
import Foundation
import os.log

// TODO:  Parse HKWorkoutEventTypePause
// TODO: HKWorkoutEventTypeMotionPaused
// TODO: HKWorkoutEventTypeResume
// TODO: HKWorkoutEventTypeSegment

enum HKValuesToImport {
    case workout
    case record
    case metadata
    case fileReference
}

public class HKHealthImporter: NSObject {
    
    /// Path for the exported XML file containing the exported data
    var xmlPath: URL?
    
    var valuesToImport: [HKValuesToImport] = [.workout]
    
    private var healthStore: HKHealthStore?
    
    var currentRecord: HKHealthRecord = HKHealthRecord()
    
    let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return f
    }()
    
    private var numberFormatter: NumberFormatter?
    
    var allRecords: [HKHealthRecord] = []
    private var allSamples: [HKSample] = []
    
    var metadata: [String: Any] = [:]
    
    // Hold the HealthKit types that are allowed to be read/written from/to
    private var authorizedTypes: [HKSampleType: Bool] = [:]
    
    /// ASDF
    /// - Parameter completion: ASDF
    public convenience init(path: URL?, completion: @escaping() -> Void) {
        
        self.init()
        healthStore = HKHealthStore()
        
        self.xmlPath = path
        
        #if !targetEnvironment(simulator)
        fatalError("Running on a real device")
        #endif
        
        self.numberFormatter = NumberFormatter()
        numberFormatter?.locale = Locale.current
        numberFormatter?.numberStyle = .decimal
        
        DispatchQueue.main.async {
            
            self.healthStore?.getRequestStatusForAuthorization(toShare: HKConstants.allSampleTypes, read: HKConstants.allSampleTypes, completion: { (status, error) in
                
                if let error = error {
                    os_log("Error: %@", log: .default, type: .error, error.localizedDescription)
                    fatalError(error.localizedDescription)
                }
                
                switch status {
                
                case .unknown:
                    break
                case .shouldRequest:
                    self.healthStore!.requestAuthorization(toShare: HKConstants.allSampleTypes, read: HKConstants.allSampleTypes, completion: { (authorized, error) in
                        
                        if let error = error {
                            fatalError(error.localizedDescription)
                            os_log("Error: %@", log: .default, type: .error, error.localizedDescription)
                        } else {
                            completion()
                        }
                    })
                case .unnecessary:
                    //                    DispatchQueue.global(qos: .background).async {
                    //                        <#code#>
                    //                    }
                    completion()
                @unknown default:
                    break
                }
            })
        }
    }
    
    public func parseData() {
        if let path = xmlPath, let parser = XMLParser(contentsOf: path) {
            
            parser.delegate = self
            
            /// Triggers the XMLParserDelegate methods to parse the XML feed
            parser.parse()
            
            self.saveAll()
            
            
        } else {
            os_log("File not found")
        }
    }
    
    func saveAll() {
        saveSamples(samples: self.allSamples, withSuccess: {}, failure: {})
    }
    
    func saveSamples(samples: [HKSample], withSuccess successBlock: @escaping () -> Void, failure failureBlock: @escaping () -> Void) {
        
        let size = samples.count
        
        print(samples.count)
        
        let z = 1000
        
        for i in stride(from: 0, to: samples.count-2000, by: z) {
            print("From \(i) to \(i+z)")
            let a = Array(samples[i..<(i+z)])
            self.healthStore!.save(a, withCompletion: { (succ, error) in
                if let error = error {
                    print(error.localizedDescription)
                }
            })
        }
        
        
        // TODO: There's an issue when saving a lot of samples using an array.
        // In my case I have a 2GB XML file and it's better to save the results item by item
        
    }
}



// MARK: - Metadata management

extension HKHealthImporter {
    
    func metadataFrom(_ attributeDict: [String: String]) {
        var key: String?
        var value: Any?
        
        for (attributeKey, attributeValue) in attributeDict {
            
            if attributeKey == "key" {
                key = attributeValue
            }
            
            if attributeKey == "value" {
                if let intValue = Int(attributeValue) {
                    value = intValue
                } else {
                    value = attributeValue
                }
                if attributeValue.hasSuffix("%") {
                    let components = attributeValue.split(separator: " ")
                    
                    value = HKQuantity.init(unit: .percent(), doubleValue: (numberFormatter?.number(from: String(components.first!))!.doubleValue)!)
                }
            }
            
            if let key = key, let value = value {
                print("Appended \(key) - \(value)")
                currentRecord.metadata?[key] = value
                metadata[key] = value
                dump(currentRecord.metadata)
                print("---------------------")
            }
        }
        
        //        currentRecord.metadata = [String: Any]()
        //
        //        if let key = key, let value = value, key != "HKMetadataKeySyncIdentifier" {
        //            currentRecord.metadata?[key] = value
        //        }
    }
    
    func routeFrom(_ attributeDict: [String: String]) {
        
        /**
         {
         "key": "path",
         "value": "/workout-routes/route_2021-01-08_7.13pm.gpx"
         }
         */
        
        var key: String?
        var value: Any?
        
        for (attributeKey, attributeValue) in attributeDict {
            
            // A GPX file is associated with the
            if attributeKey == "path" {
                let pathExtension = URL(fileURLWithPath: attributeValue).pathExtension
                let pathFileName = URL(fileURLWithPath: attributeValue).lastPathComponent.replacingOccurrences(of: ".\(pathExtension)", with: "")
                
                let path = Bundle.main.url(forResource: "\(pathFileName)", withExtension: "\(pathExtension)")!
                
                currentRecord.associatedGpxUrl = path
            }
            
            
            
        }
    }
    
    public func parser(_ parser: XMLParser, foundComment comment: String) {
        print("comment")
        print(comment)
    }
    
    public func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        print(String(data: CDATABlock, encoding: .utf8))
    }
    
    /**
     Parse workouts contents from a dictionary
     */
    func workoutFrom(_ attributeDict: [String: String]) {
        
        currentRecord.type = HKObjectType.workoutType().identifier
        currentRecord.activityType = HKWorkoutActivityType.from(string: attributeDict["workoutActivityType"] ?? "")
        currentRecord.sourceName = attributeDict["sourceName"] ??  ""
        currentRecord.sourceVersion = attributeDict["sourceVersion"] ??  ""
        currentRecord.value = Double(attributeDict["duration"] ?? "0") ?? 0
        currentRecord.unit = attributeDict["durationUnit"] ?? ""
        currentRecord.totalDistance = Double(attributeDict["totalDistance"] ?? "0") ?? 0
        currentRecord.totalDistanceUnit = attributeDict["totalDistanceUnit"] ??  ""
        currentRecord.totalEnergyBurned = Double(attributeDict["totalEnergyBurned"] ?? "0") ?? 0
        currentRecord.totalEnergyBurnedUnit = attributeDict["totalEnergyBurnedUnit"] ??  ""
        
        attributeDict["sourceVersion"]
        
        currentRecord.device = HKDevice(name: attributeDict["sourceName"] ?? nil,
                                        manufacturer: nil,
                                        model: nil,
                                        hardwareVersion: nil,
                                        firmwareVersion: nil,
                                        softwareVersion: nil,
                                        localIdentifier: nil,
                                        udiDeviceIdentifier: nil)
        
        // Create HKDevice
        
        
        
        if let date = dateFormatter.date(from: attributeDict["startDate"]!) {
            currentRecord.startDate = date
        }
        
        if let date = dateFormatter.date(from: attributeDict["endDate"]!) {
            currentRecord.endDate = date
        }
        if currentRecord.startDate > currentRecord.endDate {
            currentRecord.startDate = currentRecord.endDate
        }
        if let date = dateFormatter.date(from: attributeDict["creationDate"]!) {
            currentRecord.creationDate = date
        }
    }
    
    
    /// Does not run on the main thread
    /// - Parameter parser: <#parser description#>
    public func parserDidEndDocument(_ parser: XMLParser) {
        
        dump(allRecords)
        
        for record in allRecords {
            
            DispatchQueue.main.async {
                
                
                if let gpx = record.associatedGpxUrl {
                    GPXXMLParser().parseThingies(url: gpx, completion: { met in
                        
                        dump(met)
                    })
                }
                
                self.save(item: record, completion: { result in
                    switch result {
                    
                    case .success(let sample):
                        self.healthStore!.save(sample, withCompletion: { (succ, error) in
                            if let error = error {
                                print(error.localizedDescription)
                            }
                        })
                    case .failure(let error):
                        fatalError(error.localizedDescription)
                    }
                })
            }
        }
        
    }
    
    func save(item: HKHealthRecord, completion: @escaping (Result<HKSample, HKImporterError>) -> Void) {
        
        var metadata: [String: Any]? = nil
        
        // Thread 3: "Invalid class __NSCFNumber for metadata key: HKExternalUUID. Expected NSString."
        if let hkMetadata = item.metadata {
            
            metadata = hkMetadata
            
            if let hkExternalUuid = metadata!["HKExternalUUID"] {
                metadata!["HKExternalUUID"] = "\(hkExternalUuid)"
            }
            
            // Thread 7: "HKMetadataKeySyncVersion may not be provided if HKMetadataKeySyncIdentifier is not provided in the metadata"
            if metadata!["HKMetadataKeySyncVersion"] != nil && metadata?.keys.count == 1 {
                
                completion(.failure(.metadataSync))
                return
            }
        }
        
        // "110 count/min" crashes because it's a string and not a HKQuantity
        // Thread 4: "Invalid class __NSCFString for metadata key: HKHeartRateEventThreshold. Expected HKQuantity."
        if item.type == HKCategoryTypeIdentifier.highHeartRateEvent.rawValue {
            dump(item)
            completion(.failure(.saving))
            return
        }
        
        // Thread 7: "Invalid class __NSCFString for metadata key: HKHeartRateEventThreshold. Expected HKQuantity."
        if item.type == HKCategoryTypeIdentifier.lowHeartRateEvent.rawValue {
            dump(item)
            completion(.failure(.saving))
            
            return
        }
        
        // Thread 8: "Duration between startDate (2021-01-15 11:18:34 +0000) and endDate (2021-01-15 11:18:34 +0000) is below the minimum allowed duration for this sample type. Minimum duration for type HKQuantityTypeIdentifierEnvironmentalAudioExposure is 0.001000"
        if (item.endDate.timeIntervalSince(item.startDate)) < 0.001000 && (item.type == HKQuantityTypeIdentifier.environmentalAudioExposure.rawValue || item.type == HKQuantityTypeIdentifier.headphoneAudioExposure.rawValue ) {
            dump(item)
            completion(.failure(.saving))
            return
        }
        
        // Thread 4: "Value 0 is not compatible with type HKCategoryTypeIdentifierAudioExposureEvent"
        // Thread 9: "Value 0 is not compatible with type HKCategoryTypeIdentifierAudioExposureEvent"
        //        if item.type == HKQuantityTypeIdentifier.environmentalAudioExposure.rawValue {
        //            dump(item)
        //            failureBlock()
        //            return
        //        }
        
        if item.type == HKCategoryTypeIdentifier.environmentalAudioExposureEvent.rawValue {
            dump(item)
            completion(.failure(.saving))
            return
        }
        
        
        
        let unit = HKUnit.init(from: item.unit!)
        let quantity = HKQuantity(unit: unit, doubleValue: item.value)
        var hkSample: HKSample?
        if let type = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: item.type)) {
            
            hkSample = HKQuantitySample(
                type: type,
                quantity: quantity,
                start: item.startDate,
                end: item.endDate,
                metadata: metadata)
        } else if let type = HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: item.type)) {
            
            hkSample = HKCategorySample(
                type: type,
                value: Int(item.value),
                start: item.startDate,
                end: item.endDate,
                metadata: item.metadata)
            
        } else if item.type == HKObjectType.workoutType().identifier {
            // Thread 4: "Invalid class NSTaggedPointerString for metadata key: HKElevationDescended. Expected HKQuantity."
            
            // TODO: These items are read from the XML file as strings, convert the metadata associated to HKQuantities
            if let lapLength = item.metadata?["HKLapLength"] as? String {
                let values = lapLength.components(separatedBy: " ")
                let value = Double(values[0])!
                let unit = HKUnit(from: values[1])
                let quantity = HKQuantity(unit: unit, doubleValue: value)
                
                item.metadata!["HKLapLength"] = quantity
            }
            
            if let lapLength = item.metadata?["HKElevationDescended"] as? String {
                let values = lapLength.components(separatedBy: " ")
                let value = Double(values[0])!
                let unit = HKUnit(from: values[1])
                let quantity = HKQuantity(unit: unit, doubleValue: value)
                
                item.metadata!["HKElevationDescended"] = quantity
            }
            
            if let lapLength = item.metadata?["HKElevationAscended"] as? String {
                let values = lapLength.components(separatedBy: " ")
                let value = Double(values[0])!
                let unit = HKUnit(from: values[1])
                let quantity = HKQuantity(unit: unit, doubleValue: value)
                
                item.metadata!["HKElevationAscended"] = quantity
            }
            
            if let mets = item.metadata?["HKAverageMETs"] as? String {
                let values = mets.components(separatedBy: " ")
                let value = Double(values[0])!
                let unit = HKUnit(from: values[1])
                let quantity = HKQuantity(unit: unit, doubleValue: value)
                
                item.metadata!["HKAverageMETs"] = quantity
            }
            
            if let mets = item.metadata?["HKWeatherTemperature"] as? String {
                let values = mets.components(separatedBy: " ")
                let value = Double(values[0])!
                let unit = HKUnit(from: values[1])
                let quantity = HKQuantity(unit: unit, doubleValue: value)
                
                item.metadata!["HKWeatherTemperature"] = quantity
            }
            
            if let lapLength = item.metadata?["HKWeatherHumidity"] as? String {
                let values = lapLength.components(separatedBy: " ")
                let value = Double(values[0])!
                let unit = HKUnit(from: values[1])
                let quantity = HKQuantity(unit: unit, doubleValue: value)
                
                item.metadata!["HKWeatherHumidity"] = quantity
            }
            
            hkSample = HKWorkout(
                activityType: item.activityType ?? HKWorkoutActivityType(rawValue: 0)!,
                start: item.startDate,
                end: item.endDate,
                duration: HKQuantity(unit: HKUnit.init(from: item.unit!), doubleValue: item.value).doubleValue(for: HKUnit.second()),
                totalEnergyBurned: HKQuantity(unit: HKUnit.init(from: item.totalEnergyBurnedUnit), doubleValue: item.totalEnergyBurned),
                totalDistance: HKQuantity(unit: HKUnit.init(from: item.totalDistanceUnit), doubleValue: item.totalDistance),
                device: item.device,
                metadata: item.metadata
            )
        } else {
            os_log("Didn't catch this item: %@", item.description)
        }
        
        if let hkSample = hkSample {
            
            authorizedTypes[hkSample.sampleType] = true
            allSamples.append(hkSample)
            completion(.success(hkSample))
            return
        } else {
            completion(.failure(.nilSample))
            return
        }
    }
}
