//
//  KYCCountry.swift
//  Blockchain
//
//  Created by Maurice A. on 7/26/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation

enum JSONDecodeError: Error, Equatable {
    case failedToDecodeContainer
    case failedToDecodeValueForKey
}

struct KYCCountry: Codable {
    var country: [String: String]
    private struct CustomCodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        var intValue: Int?
        init?(intValue: Int) { return nil }
    }
    init(from decoder: Decoder) throws {
        guard let container = try? decoder.container(keyedBy: CustomCodingKeys.self) else {
            throw JSONDecodeError.failedToDecodeContainer
        }
        self.country = [String: String]()
        for key in container.allKeys {
            guard let value = try? container.decode(String.self, forKey: key) else {
                throw JSONDecodeError.failedToDecodeValueForKey
            }
            country[key.stringValue] = value
        }
    }
}
