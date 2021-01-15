import HealthKit
import Foundation
import os.log

enum HKImporterError: Error {
    case saving
    case nilSample
}

public class HKHealthImporter: NSObject {
    
    /// Path for the exported XML file containing the exported data
    var xmlPath: URL?
    
    private var healthStore: HKHealthStore?
    
    private var currentRecord: HKHealthRecord = HKHealthRecord()
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return f
    }()
    
    private var numberFormatter: NumberFormatter?
    
    
    private var allSamples: [HKSample] = []
    
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
                    fatalError(error.localizedDescription)
                }
                
                switch status {
                
                case .unknown:
                    break
                case .shouldRequest:
                    self.healthStore!.requestAuthorization(toShare: HKConstants.allSampleTypes, read: HKConstants.allSampleTypes, completion: { (authorized, error) in
                        
                        if let error = error {
                            fatalError(error.localizedDescription)
                        } else {
                            completion()
                        }
                    })
                case .unnecessary:
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

// MARK: - XMLParserDelegate

extension HKHealthImporter: XMLParserDelegate {
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        if elementName == "Record" {
            recordFrom(attributeDict)
        } else if elementName == "MetadataEntry" {
            // A key that indicates whether the sample was entered by the user.
            metadataFrom(attributeDict)
        } else if elementName == "Workout" {
            workoutFrom(attributeDict)
        } else {
            return
        }
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if elementName == "Record" || elementName == "Workout" {
            
            //            if self.cutDate == nil || currentRecord.startDate > cutDate! {
            save(item: currentRecord, completion: { result in
                switch result {
                
                case .success():
                    break
                case .failure(let error):
                    dump(error.localizedDescription)
                }
                
                if self.allSamples.count % 1000 == 0 {

                    let a = self.allSamples
                    self.healthStore!.save(a, withCompletion: { (succ, error) in
                        if let error = error {
                            fatalError(error.localizedDescription)
                        }
                    })

                    self.allSamples = []
                }
                
                self.currentRecord = HKHealthRecord()
            })
            
            //            }
            
//
        } else {
            print(elementName)
        }
    }
    
    fileprivate func recordFrom(_ attributeDict: [String: String]) {
        
        currentRecord.type = attributeDict["type"]!
        currentRecord.sourceName = attributeDict["sourceName"] ??  ""
        currentRecord.sourceVersion = attributeDict["sourceVersion"] ??  ""
        currentRecord.value = Double(attributeDict["value"] ?? "0") ?? 0
        currentRecord.unit = attributeDict["unit"] ?? ""
        
        if let date = dateFormatter.date(from: attributeDict["startDate"]!) {
            currentRecord.startDate = date
        }
        
        if let date = dateFormatter.date(from: attributeDict["endDate"]!) {
            currentRecord.endDate = date
        }
        
        if currentRecord.startDate >  currentRecord.endDate {
            currentRecord.startDate = currentRecord.endDate
        }
        
        if let date = dateFormatter.date(from: attributeDict["creationDate"]!) {
            currentRecord.creationDate = date
        }
    }
    
    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print(parseError.localizedDescription)
    }
    
    public func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) {
        print(validationError.localizedDescription)
    }
}

// MARK: - Metadata management

extension HKHealthImporter {
    
    fileprivate func metadataFrom(_ attributeDict: [String: String]) {
        var key: String?
        var value: Any?
        
//        dump(attributeDict)
        
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
        }

        currentRecord.metadata = [String: Any]()
        
        if let key = key, let value = value, key != "HKMetadataKeySyncIdentifier" {
            currentRecord.metadata?[key] = value
        }
    }
    
    /**
     Parse workouts contents from a dictionary
     */
    fileprivate func workoutFrom(_ attributeDict: [String: String]) {
        
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
        
        // TODO: Add metadata["HKElevationDescended"]
        // TODO: Add metadata["HKElevationAscended"]
    }
    
//    func save(item: HKHealthRecord, withSuccess: @escaping () -> Void, failure: @escaping () -> Void) {
    func save(item: HKHealthRecord, completion: @escaping (Result<Void, HKImporterError>) -> Void) {
        
        var metadata: [String: Any]? = nil
        
        // Thread 3: "Invalid class __NSCFNumber for metadata key: HKExternalUUID. Expected NSString."
        if let hkMetadata = item.metadata {
            
            metadata = hkMetadata
            
            if let hkExternalUuid = metadata!["HKExternalUUID"] {
                metadata!["HKExternalUUID"] = "\(hkExternalUuid)"
            }
            
            // Thread 7: "HKMetadataKeySyncVersion may not be provided if HKMetadataKeySyncIdentifier is not provided in the metadata"
//            if metadata!["HKMetadataKeySyncVersion"] != nil && metadata?.keys.count == 1 {
//
//                failureBlock()
//                return
//            }
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
            
            hkSample = HKWorkout(
                activityType: item.activityType ?? HKWorkoutActivityType(rawValue: 0)!,
                start: item.startDate,
                end: item.endDate,
                duration: HKQuantity(unit: HKUnit.init(from: item.unit!), doubleValue: item.value).doubleValue(for: HKUnit.second()),
                totalEnergyBurned: HKQuantity(unit: HKUnit.init(from: item.totalEnergyBurnedUnit), doubleValue: item.totalEnergyBurned),
                totalDistance: HKQuantity(unit: HKUnit.init(from: item.totalDistanceUnit), doubleValue: item.totalDistance),
                device: nil,
                metadata: item.metadata
            )
        } else {
            os_log("Didn't catch this item: %@", item.description)
        }
        
//        if let hkSample = hkSample,
//            (authorizedTypes[hkSample.sampleType] ?? false || (self.healthStore?.authorizationStatus(for: hkSample.sampleType) == HKAuthorizationStatus.sharingAuthorized)) {
        if let hkSample = hkSample {
        
            authorizedTypes[hkSample.sampleType] = true
            allSamples.append(hkSample)
            completion(.success(()))
            return
        } else {
            completion(.failure(.nilSample))
            return
        }
        
//        if allSamples.count % 10000 == 0 {
//
//            let a = allSamples
//            self.healthStore!.save(a, withCompletion: { (succ, error) in
//                if let error = error {
//                    print(error.localizedDescription)
//                }
//            })
//
//            allSamples = []
//        }
        
//        if prevSample != item.type {
//            prevSample = item.type
//
//            print("CHANGED SAMPLE \(prevSample)")
//            let a = allSamples
//
//            saveSamples(samples: a, withSuccess: {
//                print("SUCCESS")
//                self.allSamples = []
//            }, failure: {
//                print("FAIL")
//                self.allSamples = []
//            })
//        }
    }
}
