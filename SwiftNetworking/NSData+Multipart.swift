//
//  NSData+Multipart.swift
//  SwiftNetworking
//
//  Created by Ilya Puchka on 11.09.15.
//  Copyright © 2015 Ilya Puchka. All rights reserved.
//

import Foundation

public struct MultipartBodyItem: APIRequestDataEncodable, Equatable {
    let data: NSData
    let contentType: MIMEType
    let headers: [HTTPHeader]
    
    public init(data: NSData, contentType: MIMEType, headers: [HTTPHeader]) {
        self.data = data.copy() as! NSData
        self.contentType = contentType
        self.headers = headers
    }
    
    public init?(multipartData: NSData) {
        let (data, contentType, headers) = MultipartBodyItem.parseMultipartData(multipartData)
        guard let _ = contentType, _ = data else {
            return nil
        }
        self.headers = headers
        self.contentType = contentType!
        self.data = data!
    }
    
    static private func parseMultipartData(multipartData: NSData) -> (NSData?, MIMEType?, [HTTPHeader]) {
        var headers = [HTTPHeader]()
        var contentType: MIMEType?
        var data: NSData?
        let dataLines = MultipartBodyItem.multipartDataLines(multipartData)
        for dataLine in dataLines {
            let line = NSString(data: dataLine, encoding: NSUTF8StringEncoding)! as String
            if let _contentType = MultipartBodyItem.contentTypeFromLine(line) {
                contentType = _contentType
            }
            else if let contentLength = MultipartBodyItem.contentLengthFromLine(line) {
                data = MultipartBodyItem.contentDataFromData(multipartData, contentLength: contentLength)
            }
            else if let header = MultipartBodyItem.headersFromLine(line) {
                headers.append(header)
            }
        }
        return (data, contentType, headers)
    }
    
    static private func multipartDataLines(data: NSData) -> [NSData] {
        var dataLines = data.lines()
        dataLines.removeLast()
        return dataLines
    }
    
    private static let ContentTypePrefix = "Content-Type: "
    private static let ContentLengthPrefix = "Content-Length: "
    
    private static func contentTypeFromLine(line: String) -> String? {
        guard line.hasPrefix(MultipartBodyItem.ContentTypePrefix) else {
            return nil
        }
        return line.substringFromIndex(MultipartBodyItem.ContentTypePrefix.endIndex)
    }
    
    private static func contentLengthFromLine(line: String) -> Int? {
        guard line.hasPrefix(MultipartBodyItem.ContentLengthPrefix) else {
            return nil
        }
        let scaner = NSScanner(string: line.substringFromIndex(MultipartBodyItem.ContentLengthPrefix.endIndex))
        var contentLength: Int = 0
        scaner.scanInteger(&contentLength)
        return contentLength
    }
    
    private static func headersFromLine(line: String) -> HTTPHeader? {
        guard let colonRange = line.rangeOfString(": ") else {
            return nil
        }
        let key = line.substringToIndex(colonRange.startIndex)
        let value = line.substringFromIndex(colonRange.endIndex)
        return HTTPHeader.Custom(key, value)
    }

    private static func contentDataFromData(data: NSData, contentLength: Int) -> NSData {
        let carriageReturn = "\r\n".dataUsingEncoding(NSUTF8StringEncoding)!
        let range = NSMakeRange(data.length - carriageReturn.length - contentLength, contentLength)
        return data.subdataWithRange(range)
    }
}

//MARK: - APIRequestDataEncodable

extension MultipartBodyItem {
    public func encodeForAPIRequestData() throws -> NSData {
        return NSData()
    }
}

//MARK: - Equatable

public func ==(lhs: MultipartBodyItem, rhs: MultipartBodyItem) -> Bool {
    return lhs.data == rhs.data && lhs.contentType == rhs.contentType && lhs.headers == rhs.headers
}


public func NSSubstractRange(fromRange: NSRange, _ substractRange: NSRange) -> NSRange {
    return NSMakeRange(NSMaxRange(substractRange), NSMaxRange(fromRange) - NSMaxRange(substractRange));
}

public func NSRangeInterval(fromRange: NSRange, toRange: NSRange) -> NSRange {
    if (NSIntersectionRange(fromRange, toRange).length > 0) {
        return NSMakeRange(0, 0);
    }
    if (NSMaxRange(fromRange) < NSMaxRange(toRange)) {
        return NSMakeRange(NSMaxRange(fromRange), toRange.location - NSMaxRange(fromRange));
    }
    else {
        return NSMakeRange(NSMaxRange(toRange), fromRange.location - NSMaxRange(toRange));
    }
}

extension NSMutableData {
    
    public func appendString(string: String) {
        appendData(string.dataUsingEncoding(NSUTF8StringEncoding) ?? NSData())
    }
    
    public func appendNewLine() {
        appendString("\r\n")
    }

    public func appendStringLine(string: String) {
        appendString(string)
        appendNewLine()
    }
    
    public func appendMultipartBodyItem(item: MultipartBodyItem, boundary: String) {
        appendStringLine("--\(boundary)")
        appendStringLine("Content-Type: \(item.contentType)")
        appendStringLine("Content-Length: \(item.data.length)")
        for header in item.headers {
            appendStringLine("\(header.key): \(header.requestHeaderValue)")
        }
        appendNewLine()
        appendData(item.data)
        appendNewLine()
    }
}

extension NSData {
    
    public convenience init(multipartDataWithItems items: [MultipartBodyItem], boundary: String) {
        let multipartData = NSMutableData()
        for item in items {
            multipartData.appendMultipartBodyItem(item, boundary: boundary)
        }
        multipartData.appendStringLine("--\(boundary)--")
        self.init(data: multipartData)
    }
    
    public func multipartDataItemsSeparatedWithBoundary(boundary: String) -> [MultipartBodyItem] {
        let boundaryData = "--\(boundary)".dataUsingEncoding(NSUTF8StringEncoding)!
        let trailingData = "--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!
        let items = componentsSeparatedByData(boundaryData).flatMap { (data: NSData) -> MultipartBodyItem? in
            if data != trailingData {
                return MultipartBodyItem(multipartData: data)
            }
            return nil
        }
        return items
    }
    
    public func componentsSeparatedByData(boundary: NSData) -> [NSData] {
        var components = [NSData]()
        enumerateBytesByBoundary(boundary) { (dataPart, _, _) -> Void in
            components.append(dataPart)
        }
        return components
    }
    
    public func lines() -> [NSData] {
        return componentsSeparatedByData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
    }
    
    private func enumerateBytesByBoundary(boundary: NSData, iteration: (NSData, NSRange, inout Bool) -> Void) {
        var boundaryRange = NSMakeRange(0, 0)
        var stop = false
        repeat {
            if let subRange = subRange(boundary, boundaryRange: boundaryRange) {
                if subRange.length > 0 {
                    iteration(subdataWithRange(subRange), subRange, &stop)
                }
                boundaryRange = NSMakeRange(NSMaxRange(subRange), boundary.length)
            }
            else {
                break;
            }
        } while (!stop && NSMaxRange(boundaryRange) < length)
    }
    
    private func subRange(boundary: NSData, boundaryRange: NSRange) -> NSRange? {
        let searchRange = NSSubstractRange(NSMakeRange(0, length), boundaryRange)
        let nextBoundaryRange = rangeOfData(boundary, options: NSDataSearchOptions(), range: searchRange)
        var subRange: NSRange?
        if nextBoundaryRange.location != NSNotFound {
            subRange = NSRangeInterval(boundaryRange, toRange: nextBoundaryRange)
        }
        else if (NSMaxRange(boundaryRange) < length) {
            subRange = searchRange
        }
        return subRange
    }
    
}