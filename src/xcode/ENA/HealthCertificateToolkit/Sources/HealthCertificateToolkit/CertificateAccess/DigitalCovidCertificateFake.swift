//
// 🦠 Corona-Warn-App
//

import Foundation
import base45_swift
import SwiftCBOR

public enum DigitalCovidCertificateFake {

    public static func makeBase45Fake(from certificate: Codable, and header: CBORWebTokenHeader) -> Result<Base45, CertificateDecodingError> {

        guard let cborCertificateData = try? CodableCBOREncoder().encode(certificate) else {
            return .failure(.HC_BASE45_ENCODING_FAILED)
        }

        let cborEncoder = CBORDecoder(input: [UInt8](cborCertificateData))
        guard let cborCertificate = try? cborEncoder.decodeItem() else {
            return .failure(.HC_BASE45_ENCODING_FAILED)
        }

        var wrappedCertificate = CBOR.map([CBOR: CBOR]())
        wrappedCertificate[1] = cborCertificate

        var cborWebTokenPayload = CBOR.map([CBOR: CBOR]())
        cborWebTokenPayload[-260] = wrappedCertificate
        cborWebTokenPayload[1] = CBOR.utf8String(header.issuer)
        cborWebTokenPayload[4] = CBOR.double(header.expirationTime.timeIntervalSince1970)
        cborWebTokenPayload[6] = CBOR.unsignedInt(UInt64(header.issuedAt.timeIntervalSince1970))

        let cborWebTokenPayloadBytes = cborWebTokenPayload.encode()

        let cborWebTokenMessage = CBOR.array([
            CBOR.null,
            CBOR.null,
            CBOR.byteString(cborWebTokenPayloadBytes),
            CBOR.null
        ])

        let cborWebToken = CBOR.tagged(CBOR.Tag(rawValue: 18), cborWebTokenMessage)

        // Compress with zlib
        let cborWebTokenData = Data(cborWebToken.encode())
        let compressedCBORWebToken = cborWebTokenData.compressZLib()
        guard !compressedCBORWebToken.isEmpty else {
            return .failure(.HC_ZLIB_COMPRESSION_FAILED)
        }

        // Encode with base45
        let base45CBORWebToken = compressedCBORWebToken.toBase45()
        guard !base45CBORWebToken.isEmpty else {
            return .failure(.HC_BASE45_ENCODING_FAILED)
        }

        // Add prefix
        let prefixedBase45CBORWebToken = hcPrefix + base45CBORWebToken

        return .success(prefixedBase45CBORWebToken)
    }
    
    public static func makeBase45CorruptFake(
        from certificate: DigitalCovidCertificate,
        and header: CBORWebTokenHeader = CBORWebTokenHeader.fake()
    ) -> Result<Base45, CertificateDecodingError> {

        guard let cborCertificateData = try? CodableCBOREncoder().encode(certificate) else {
            return .failure(.HC_BASE45_ENCODING_FAILED)
        }

        let cborEncoder = CBORDecoder(input: [UInt8](cborCertificateData))
        guard let cborCertificate = try? cborEncoder.decodeItem() else {
            return .failure(.HC_BASE45_ENCODING_FAILED)
        }

        var wrappedCertificate = CBOR.map([CBOR: CBOR]())
        wrappedCertificate[1] = cborCertificate

        var cborWebTokenPayload = CBOR.map([CBOR: CBOR]())
        cborWebTokenPayload[-260] = wrappedCertificate
        cborWebTokenPayload[4] = CBOR.unsignedInt(UInt64(header.expirationTime.timeIntervalSince1970))
        cborWebTokenPayload[6] = CBOR.double(header.issuedAt.timeIntervalSince1970)

        let cborWebTokenPayloadBytes = cborWebTokenPayload.encode()

        let cborWebTokenMessage = CBOR.array([
            CBOR.null,
            CBOR.byteString(cborWebTokenPayloadBytes),
            CBOR.null
        ])

        let cborWebToken = CBOR.tagged(CBOR.Tag(rawValue: 18), cborWebTokenMessage)

        // Compress with zlib
        let cborWebTokenData = Data(cborWebToken.encode())
        let compressedCBORWebToken = cborWebTokenData.compressZLib()
        guard !compressedCBORWebToken.isEmpty else {
            return .failure(.HC_ZLIB_COMPRESSION_FAILED)
        }

        // Encode with base45
        let base45CBORWebToken = compressedCBORWebToken.toBase45()
        guard !base45CBORWebToken.isEmpty else {
            return .failure(.HC_BASE45_ENCODING_FAILED)
        }

        // Add prefix
        let prefixedBase45CBORWebToken = hcPrefix + base45CBORWebToken

        return .success(prefixedBase45CBORWebToken)
    }

}
