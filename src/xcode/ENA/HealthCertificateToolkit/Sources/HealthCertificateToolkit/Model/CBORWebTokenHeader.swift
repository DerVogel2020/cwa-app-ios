//
// 🦠 Corona-Warn-App
//

import Foundation

public struct CBORWebTokenHeader: Codable, Equatable {

    // MARK: - Protocol Codable

    enum CodingKeys: String, CodingKey {
        case issuer = "iss"
        case issuedAt = "iat"
        case expirationTime = "exp"
    }

    // MARK: - Internal

    let issuer: String
    let issuedAt: UInt64?
    let expirationTime: UInt64
}
