//
// 🦠 Corona-Warn-App
//

import Foundation

public struct ProofCertificateAccess {

    // MARK: - Public

    public func extractCBORWebTokenHeader(cbor: Data) -> Result<CBORWebTokenHeader, HealthCertificateDecodingError> {
        return certificateAccess.extractHeader(from: cbor)
    }

    // MARK: - Internal

    let certificateAccess = CertificateAccess()
}
