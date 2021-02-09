//
//  File.swift
//  
//
//  Created by Javier de Martín Gil on 9/2/21.
//

import Foundation

// MARK: - XMLParserDelegate

extension HKHealthImporter: XMLParserDelegate {
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "Record" && valuesToImport.contains(.record) {
            recordFrom(attributeDict)
        } else if elementName == "MetadataEntry" && valuesToImport.contains(.metadata) {
            // A key that indicates whether the sample was entered by the user.
            metadataFrom(attributeDict)
            dump(currentRecord.metadata)
        } else if elementName == "Workout" && valuesToImport.contains(.workout) {
            workoutFrom(attributeDict)
        } else if elementName == "FileReference" && valuesToImport.contains(.fileReference)  {
            routeFrom(attributeDict)
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
