//
//  GPXXMLParser.swift
//  
//
//  Created by Javier de Martín Gil on 16/1/21.
//

import Foundation
import CoreLocation

class GPXXMLParser: NSObject, ObservableObject {
    var parser = XMLParser()
    var posts = NSMutableArray()
    var elements = NSMutableDictionary()
    var element = NSString()
    var title1 = NSMutableString()
    var date = NSMutableString()
    
    func parseThingies(url: URL, completion: @escaping(Metadata) -> ()) {
        parser = XMLParser(contentsOf: url)!
        parser.delegate = self
        parser.parse()
        completion(gpx)
    }
    
    var gpx = Metadata()
    var foundCharacters = "";
    var provisionalCoordinates = CLLocationCoordinate2D()
    var provisionalPoint = Point()
}

extension GPXXMLParser: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        if elementName == "metadata" {
            
        }
        
        if elementName == "trkpt" {
//            print(attributeDict)
            
            if let latitude = attributeDict["lat"],
               let longitude = attributeDict["lon"],
               let latNo = Double(latitude),
               let lonNo = Double(longitude) {
                provisionalCoordinates = CLLocationCoordinate2D(latitude: latNo, longitude: lonNo)
                provisionalPoint.coordinates = provisionalCoordinates
            }
        }
        
        if elementName == "ele" {
//            print()
        }
        
        if elementName == "time" {
//            print()
        }
        
        
        if element == "name" {
            
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
//        print(foundCharacters)
        foundCharacters += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if elementName == "metadata" {
//            print()
        }
        
        if elementName == "trkpt" {
            gpx.points.append(provisionalPoint)
            provisionalCoordinates = CLLocationCoordinate2D()
        }
        
        if elementName == "ele" {
            if let elevation = Double(foundCharacters) {
                provisionalPoint.elevation = elevation
            }
        }
        
        if elementName == "time" {
            
            
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: foundCharacters) {
                provisionalPoint.time = date
            }
        }
        
        if elementName == "name" {
            self.gpx.name = foundCharacters
        }
        
        foundCharacters = "";
        
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        fatalError(parseError.localizedDescription)
    }
    
    func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) {
        fatalError(validationError.localizedDescription)
    }
}

class Metadata {
    var name = ""
    var points = [Point]()
}

class Point {
    var elevation = 0.0
    var time = Date()
    var coordinates = CLLocationCoordinate2D()
    
    init(elevation: Double, time: Date, coordinates: CLLocationCoordinate2D) {
        self.elevation = elevation
        self.time = time
        self.coordinates = coordinates
    }
    
    init() {
        
    }
}

import MapKit
