//
//  Pin.swift
//  Blockchain
//
//  Created by Chris Arriola on 4/26/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation

struct SavePinError: Error {}

/// Model for a user's 4-digit pin
@objc class Pin: NSObject {
    static let Invalid = Pin(code: 0000)

    private(set) var pinCode: UInt

    /// Checks if this pin is a valid
    @objc var isValid: Bool {
        return self != Pin.Invalid
    }

    /// Checks if this pin is a commonly used pin (read: not very secure)
    @objc var isCommon: Bool {
        let commonPinCodes: [UInt] = [1234, 1111, 1212, 7777, 1004]
        return commonPinCodes.contains(pinCode)
    }

    /// String representation of the underlying pin
    @objc var toString: String {
        return pinCode.pinToString
    }

    // MARK: - Initializers

    @objc init(code: UInt) {
        self.pinCode = code
    }

    convenience init?(string: String) {
        guard let code = UInt(string) else { return nil }
        self.init(code: code)
    }

    // MARK: - Public

    func saveToKeychain() {
        BlockchainSettings.App.shared.pin = self.toString
    }
}

extension Pin {
    static func == (lhs: Pin, rhs: Pin) -> Bool {
        return lhs.pinCode == rhs.pinCode
    }

    override func isEqual(_ object: Any?) -> Bool {
        return self.pinCode == (object as? Pin)?.pinCode
    }

    override var hashValue: Int {
        return Int(pinCode)
    }
}

extension UInt {
    var pinToString: String {
        return String(format: "%lu", CUnsignedLongLong(self))
    }
}
