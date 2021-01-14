import HealthKit
import Foundation

struct HKHealthImport {
    var text = "Hello, World!"
}

//public class HKHealthImport {
//
//    private static var sharedUnits: HKHealthImport = {
//        let shared = HKHealthImport()
//
//        return shared
//    }()
//
//    class func shared() -> HKHealthImport {
//        return sharedUnits
//    }
//
//    private init() {
//        let fileManager = FileManager.default
//        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
//
//        var path: URL?
//        do {
//            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
//            if let url = fileURLs.first, url.absoluteString.hasSuffix("export.xml") {
//                path = url
//            }
//        } catch {
//        }
//
////        dataImporter = Importer {
////            if path == nil {
////                path = Bundle.main.url(forResource: "export", withExtension: "xml")
////            }
////
////            if let path = path {
////                if let parser = XMLParser(contentsOf: path) {
////                    parser.delegate = self.dataImporter
////                    self.dataImporter.readCounterLabel  = self.readCounter
////                    self.dataImporter.writeCounterLabel = self.writeCounter
////                    parser.parse()
////                    self.dataImporter.saveAllSamples()
////                }
////            } else {
////                os_log("File not found")
////            }
////        }
//    }
//}
