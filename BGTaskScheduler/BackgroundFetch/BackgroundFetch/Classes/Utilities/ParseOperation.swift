 /*
  Copyright (C) 2017 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  NSOperation subclass for parsing the RSS feed.
  */

import UIKit

let CellIdentifier = "LazyTableCell"
let PlaceholderCellIdentifier = "PlaceholderCell"

// string contants found in the RSS feed
let kIDStr: String = "id"
let kNameStr: String = "im:name"
let kImageStr: String = "im:image"
let kArtistStr: String = "im:artist"
let kEntryStr: String = "entry"

 // MARK: -
 
class ParseOperation: Operation {
    // A block to call when an error is encountered during parsing.
    var errorHandler: ((Error?) -> Void)?

    // Redeclare appRecordList so we can modify it within this class
    var appRecordList: [AppRecord]?
    
    var dataToParse: Data?
    var workingArray: [AnyObject]?
    var workingEntry: AppRecord? // the current app record or XML entry being parsed
    var workingPropertyString: String?
    var elementsToParse: [String]?
    var storingCharacterData: Bool?
    
    // -------------------------------------------------------------------------------
    //    initWithData:
    // -------------------------------------------------------------------------------
    convenience init(data: Data) {
        self.init()
        
        dataToParse = data
        elementsToParse = [kIDStr, kNameStr, kImageStr, kArtistStr]
    }
    
    // MARK: -

    // -------------------------------------------------------------------------------
    //  main
    //  Entry point for the operation.
    //  Given data to parse, use NSXMLParser and process all the top paid apps.
    // -------------------------------------------------------------------------------
    override func main() {
        // The default implemetation of the -start method sets up an autorelease pool
        // just before invoking -main however it does NOT setup an excption handler
        // before invoking -main.  If an exception is thrown here, the app will be
        // terminated.
        
        workingArray = [AnyObject]()
        workingPropertyString = ""
        
        // It's also possible to have NSXMLParser download the data, by passing it a URL, but this is not
        // desirable because it gives less control over the network, particularly in responding to
        // connection errors.
        //
        let parser: XMLParser = XMLParser(data: dataToParse!)
        parser.delegate = self
        parser.parse()
        
        if isCancelled == false {
            // Set appRecordList to the result of our parsing
            appRecordList = workingArray as? [AppRecord]
        }
        
        workingArray = nil
        workingPropertyString = nil
        dataToParse = nil
    }
}

// MARK: - RSS processing

extension ParseOperation: XMLParserDelegate {
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        // entry: { id (link), im:name (app name), im:image (variable height) }
        //
        if elementName == kEntryStr {
            workingEntry = AppRecord()
        }
        storingCharacterData = elementsToParse?.contains(elementName)
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if workingEntry != nil {
            if storingCharacterData == true {
                let trimmedString = workingPropertyString!.trimmingCharacters(in: .whitespacesAndNewlines)
                workingPropertyString = "" // clear the string for next time
                if elementName == kIDStr {
                    workingEntry!.appURLString = trimmedString
                } else if elementName == kNameStr {
                    workingEntry!.appName = trimmedString
                } else if elementName == kImageStr {
                    workingEntry!.imageURLString = trimmedString
                } else if elementName == kArtistStr {
                    workingEntry!.artist = trimmedString
                }
            } else if elementName == kEntryStr {
                workingArray!.append(workingEntry!)
                workingEntry = nil
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if storingCharacterData == true {
            workingPropertyString!.append(string)
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        if errorHandler != nil {
            errorHandler!(parseError)
        } else {
            print("parseErrorOccurred: \(parseError.localizedDescription)")
        }
    }
}
