//
//  KYCCountrySelectionControllerTests.swift
//  BlockchainTests
//
//  Created by Maurice A. on 7/25/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

import XCTest
import Blockchain

class KYCCountrySelectionControllerTests: XCTestCase {

    let sampleResponse = """
        [
            {
                "UK": "United Kingdom"
            },
            {
                "US": "United States"
            }
        ]
    """

    let badResponse = """
        [
            {
                "UK": ❌
            }
        ]
    """

    let emptyResponse = "[]"

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testDecodeSampleResponse() {
        let responseData = sampleResponse.data(using: .utf8)
        let data = try? JSONDecoder().decode([KYCCountry].self, from: responseData!)
        XCTAssertNoThrow(data, "Expected data not to throw")
        XCTAssertNotNil(data, "Expected data not to be nil")
    }

    func testDecodeBadResponse() {
        let responseData = badResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode([KYCCountry].self, from: responseData))
    }

    func testDecodeEmptyResponse() {
        let responseData = emptyResponse.data(using: .utf8)
        let data = try? JSONDecoder().decode([KYCCountry].self, from: responseData!)
        XCTAssertNoThrow(data, "Expected data not to throw")
        XCTAssertNotNil(data, "Expected data not to be nil")
        XCTAssertEqual(data?.count, 0, "Expected empty response to result in an empty array")
    }
}
