//
//  File.swift
//  
//
//  Created by Javier de Martín Gil on 9/2/21.
//

import Foundation
import HealthKit
import CoreLocation

// MARK: - XMLParserDelegate

extension HKHealthImporter: XMLParserDelegate {
    
    /// Does not run on the main thread
    /// - Parameter parser: <#parser description#>
    public func parserDidEndDocument(_ parser: XMLParser) {
        
        dump(allRecords)
        
        for record in allRecords {
            
            var record = record
            
            
            
            DispatchQueue.main.async {
                
                
//                if let gpx = record.associatedGpxUrl {
//                    
//                    var workout = HKWorkout(activityType: record.activityType!, start: record.startDate, end: record.endDate)
//                    
//                    GPXXMLParser().parseThingies(url: gpx, completion: { met in
////                        dump(met)//
//                        /// Move object to HKWorkoutRoute
////                        let hkWorkoutRoute = met.points.compactMap({ HKWorkoutRoute( })
//                        
//                        let locations = met.points.compactMap({ CLLocation(latitude: $0.coordinates.latitude, longitude: $0.coordinates.longitude) })
//                        
//                        
//                        let a = HKWorkoutRouteBuilder(healthStore: self.healthStore!, device: nil)
//                        
//                        a.insertRouteData(locations, completion: { (finished, error) in
//                            
//                            if error != nil {
//                                dump(error?.localizedDescription)
//                                return
//                            }
//                            
////                            a.finishRoute(with: workout, metadata: nil, completion: { (route, error) in
//////                                print(route, error)
////                                self.healthStore?.save(workout, withCompletion: { (a,b) in })
////                            })
//                        })
//                        
//                        self.healthStore?.save(workout, withCompletion: { (finished,b) in
//                            
//                            if finished {
////                                self.healthStore!.add(, to: workout, completion: {
////                                    
////                                })
//                            }
//                        })
//                    })
//                }
                
                self.save(item: record, completion: { result in
                    switch result {

                    case .success(let sample):
                        self.healthStore!.save(sample, withCompletion: { (succ, error) in
                            if let error = error {
                                print(error.localizedDescription)
                            }
                        })
                    case .failure(let error):
                        dump(error.localizedDescription)
                        // fatalError(error.localizedDescription)
                    }
                })
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
    
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "Record" && valuesToImport.contains(.record) {
            recordFrom(attributeDict)
        } else if elementName == "MetadataEntry" && valuesToImport.contains(.metadata) {
            // A key that indicates whether the sample was entered by the user.
            metadataFrom(attributeDict)
            dump(currentRecord.metadata)
        } else if elementName == "Workout" && valuesToImport.contains(.workout) {
            
            if attributeDict["sourceName"] == "Apple Watch de Javier" {
                print("HEHE")
            }
            
            workoutFrom(attributeDict)
        } else if elementName == "FileReference" && valuesToImport.contains(.fileReference)  {
            routeFrom(attributeDict)
        } else if elementName == "WorkoutRoute" && valuesToImport.contains(.workoutRoute) {
            print("ROUTE")
        } else if elementName == "WorkoutEvent" && valuesToImport.contains(.workoutEvent) {
            workoutEvent(from: attributeDict)
        } else if elementName == "FileReference" {
            print(metadata)
        }
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if elementName == "Record" && valuesToImport.contains(.record) {
            
            currentRecord.metadata = metadata
            metadata = [:]
            allRecords.append(currentRecord)
            currentRecord = HKHealthRecord()
        } else if elementName == "Workout" && valuesToImport.contains(.workout) {
            currentRecord.metadata = metadata
            metadata = [:]
            allRecords.append(currentRecord)
            currentRecord = HKHealthRecord()
        }
    }
    
    fileprivate func workoutEvent(from attributeDict: [String: String]) {
        
        guard let eventTypeString = attributeDict["type"] else { return }
        
        guard let eventType = MyHKWorkoutEventType(rawValue: eventTypeString) else { return }
        
        guard let dateString = attributeDict["date"], let eventDate = dateFormatter.date(from: dateString) else { return }
        
        let event = MyHKWorkoutEvent(type: eventType, date: eventDate)
        
        currentRecord.workoutEvent.append(event)
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
