//
//  NSDataMultipartTests.swift
//  SwiftNetworking
//
//  Created by Ilya Puchka on 12.09.15.
//  Copyright © 2015 Ilya Puchka. All rights reserved.
//

import XCTest
@testable import SwiftNetworking

class NSDataMultipartTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testThatItReturnsComponentsSeparatedByData() {
        let data1 = "1".dataUsingEncoding(NSUTF8StringEncoding)!
        let data2 = "2".dataUsingEncoding(NSUTF8StringEncoding)!
        let data3 = "3".dataUsingEncoding(NSUTF8StringEncoding)!
        let separator = "-".dataUsingEncoding(NSUTF8StringEncoding)!
        let fullData = "1-2-3".dataUsingEncoding(NSUTF8StringEncoding)!
        let components = fullData.componentsSeparatedByData(separator)
        let expectedComponents = [data1, data2, data3]
        XCTAssertEqual(components, expectedComponents)
    }
    
    func testThatItReturnsComponentsSeparatedByDataWithTrailingSeparator() {
        let data1 = "1".dataUsingEncoding(NSUTF8StringEncoding)!
        let data2 = "2".dataUsingEncoding(NSUTF8StringEncoding)!
        let separator = "-".dataUsingEncoding(NSUTF8StringEncoding)!
        let fullData = "1-2-".dataUsingEncoding(NSUTF8StringEncoding)!
        let components = fullData.componentsSeparatedByData(separator)
        let expectedComponents = [data1, data2]
        XCTAssertEqual(components, expectedComponents)
    }
    
    func testThatItReturnsComponentsSeparatedByDataWithHeadingSeparator() {
        let data1 = "1".dataUsingEncoding(NSUTF8StringEncoding)!
        let data2 = "2".dataUsingEncoding(NSUTF8StringEncoding)!
        let separator = "-".dataUsingEncoding(NSUTF8StringEncoding)!
        let fullData = "-1-2-".dataUsingEncoding(NSUTF8StringEncoding)!
        let components = fullData.componentsSeparatedByData(separator)
        let expectedComponents = [data1, data2]
        XCTAssertEqual(components, expectedComponents)
    }
    
    func testThatItDoesNotReturnEmptyComponent() {
        let data1 = "1".dataUsingEncoding(NSUTF8StringEncoding)!
        let data2 = "2".dataUsingEncoding(NSUTF8StringEncoding)!
        let separator = "-".dataUsingEncoding(NSUTF8StringEncoding)!
        let fullData = "---1--2--".dataUsingEncoding(NSUTF8StringEncoding)!
        let components = fullData.componentsSeparatedByData(separator)
        let expectedComponents = [data1, data2]
        XCTAssertEqual(components, expectedComponents)
    }
    
    func testThatItReturnsFullDataIfThereIsNoSeparator() {
        let separator = "-".dataUsingEncoding(NSUTF8StringEncoding)!
        let fullData = "123".dataUsingEncoding(NSUTF8StringEncoding)!
        let components = fullData.componentsSeparatedByData(separator)
        let expectedComponents = [fullData]
        XCTAssertEqual(components, expectedComponents)
    }
    
    func testThatItReturnsNoItemsForEmptyData() {
        let separator = "".dataUsingEncoding(NSUTF8StringEncoding)!
        let fullData = "".dataUsingEncoding(NSUTF8StringEncoding)!
        let components = fullData.componentsSeparatedByData(separator)
        let expectedComponents = []
        XCTAssertEqual(components, expectedComponents)
    }
    
    func testThatItReturnsLines() {
        let data1 = "1".dataUsingEncoding(NSUTF8StringEncoding)!
        let separator = "\r\n".dataUsingEncoding(NSUTF8StringEncoding)!
        let fullData = "1\r\n23\r\n".dataUsingEncoding(NSUTF8StringEncoding)!
        let components = fullData.componentsSeparatedByData(separator)
        let expectedComponents = [data1, "23".dataUsingEncoding(NSUTF8StringEncoding)!]
        XCTAssertEqual(components, expectedComponents)
    }
    
    func testThatItCreatesDataFromItems() {
        // given
        let data1 = "1".dataUsingEncoding(NSUTF8StringEncoding)!
        let data2 = "2".dataUsingEncoding(NSUTF8StringEncoding)!
        let contentType = "text"
        let headers = [HTTPHeader.Custom("key", "value")]
        let item1 = MultipartBodyItem(data: data1, contentType: contentType, headers: headers)
        let item2 = MultipartBodyItem(data: data2, contentType: contentType, headers: headers)
        let separator = "--boundary".dataUsingEncoding(NSUTF8StringEncoding)!
        
        // expect
        let itemsContentData = [data1, data2]
        let contentLengths = ["Content-Length: \(data1.length)", "Content-Length: \(data2.length)"]
        let expectedContentType = "Content-Type: \(contentType)"
        let expectedHeader = "\(headers.first!.key): \(headers.first!.requestHeaderValue)"

        // when
        let multipartData = NSData(multipartDataWithItems: [item1, item2], boundary: "boundary")

        // then
        let components = multipartData.componentsSeparatedByData(separator)
        XCTAssertEqual(components.count, 3);
        XCTAssertEqual(components.last!, "--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!);
        let itemsData = components[0...1];
        for (index, itemData) in itemsData.enumerate() {
            let lines = itemData.lines()
            XCTAssertEqual(lines.count, 4);
            XCTAssertEqual(lines.last!, itemsContentData[index])
            let itemContentType = NSString(data: lines[0], encoding: NSUTF8StringEncoding)!
            XCTAssertEqual(itemContentType, expectedContentType)
            let itemContentLength = NSString(data: lines[1], encoding: NSUTF8StringEncoding)!
            XCTAssertEqual(itemContentLength, contentLengths[index])
            let header = NSString(data: lines[2], encoding: NSUTF8StringEncoding)!
            XCTAssertEqual(header, expectedHeader)
        }
    }
    
    func testThatItReturnsItemsFromData() {
        let data1 = "1".dataUsingEncoding(NSUTF8StringEncoding)!
        let data2 = "2".dataUsingEncoding(NSUTF8StringEncoding)!
        let contentType = "text"
        let headers = [HTTPHeader.Custom("key", "value")]
        let item1 = MultipartBodyItem(data: data1, contentType: contentType, headers: headers)
        let item2 = MultipartBodyItem(data: data2, contentType: contentType, headers: headers)

        let boundary = "boundary"
        let multipartData = NSData(multipartDataWithItems: [item1, item2], boundary: boundary)
        let items = multipartData.multipartDataItemsSeparatedWithBoundary(boundary)
        XCTAssertEqual(items.count, 2);
        XCTAssertEqual(items.first!, item1)
        XCTAssertEqual(items.last!, item2)

    }
}
