//
//  Salsa20.swift
//  GateKeeper
//

import Foundation

protocol KdbxStreamCipher {
    func protect(string: String) throws -> String
    func unprotect(string: String) throws -> String
}

class Salsa20: KdbxStreamCipher {

    private static let sigma = [UInt8]("expand 32-byte k".utf8)
    private static let tau = [UInt8]("expand 16-byte k".utf8)

    private let rounds: Int
    private var index = 0
    private var keyStream = [UInt8](repeating: 0, count: 64)
    private var state = [UInt32](repeating: 0, count: 16)

    required init(key: [UInt8], iv: [UInt8], rounds: Int = 20) {
        self.rounds = rounds

        setKeyIv(key, iv)

        reset()
    }

    private func setKeyIv(_ key: [UInt8], _ iv: [UInt8]) {
        state[1] = toUInt32(bytes: key, offset: 0)
        state[2] = toUInt32(bytes: key, offset: 4)
        state[3] = toUInt32(bytes: key, offset: 8)
        state[4] = toUInt32(bytes: key, offset: 12)

        let keyIndex = key.count - 16

        state[11] = toUInt32(bytes: key, offset: keyIndex)
        state[12] = toUInt32(bytes: key, offset: keyIndex + 4)
        state[13] = toUInt32(bytes: key, offset: keyIndex + 8)
        state[14] = toUInt32(bytes: key, offset: keyIndex + 12)

        let constants = key.count == 32 ? Salsa20.sigma : Salsa20.tau

        state[0] = toUInt32(bytes: constants, offset: 0)
        state[5] = toUInt32(bytes: constants, offset: 4)
        state[10] = toUInt32(bytes: constants, offset: 8)
        state[15] = toUInt32(bytes: constants, offset: 12)

        state[6] = toUInt32(bytes: iv, offset: 0)
        state[7] = toUInt32(bytes: iv, offset: 4)
        state[8] = 0
        state[9] = 0
    }

    private func toUInt32(bytes: [UInt8], offset: Int) -> UInt32 {
        let a = UInt32(bytes[offset])
        let b = UInt32(bytes[offset + 1]) << 8
        let c = UInt32(bytes[offset + 2]) << 16
        let d = UInt32(bytes[offset + 3]) << 24
        return a | b | c | d
    }

    func transformBlock(inputBuffer: [UInt8], inputOffset: Int, inputCount: Int, outputBuffer: inout [UInt8], outputOffset: Int) {
        for i in 0..<inputCount {
            outputBuffer[i + outputOffset] = keyStream[index] ^ inputBuffer[i + inputOffset]
            index = (index + 1) & 63

            if index == 0 {
                state[8] = addOne(state[8])
                if state[8] == 0 {
                    state[9] = addOne(state[9])
                }

                salsa20Core(input: state, output: &keyStream)
            }
        }
    }

    private func reset() {
        index = 0
        state[8] = 0
        state[9] = 0

        salsa20Core(input: state, output: &keyStream)
    }

    private func addOne(_ v: UInt32) -> UInt32 {
        return v &+ 1
    }

    private func salsa20Core(input: [UInt32], output: inout [UInt8]) {
        var x = input
        for _ in stride(from: rounds, to: 0, by: -2) {
            x[04] ^= rotate(add(x[00], x[12]), 07)
            x[08] ^= rotate(add(x[04], x[00]), 09)
            x[12] ^= rotate(add(x[08], x[04]), 13)
            x[00] ^= rotate(add(x[12], x[08]), 18)
            x[09] ^= rotate(add(x[05], x[01]), 07)
            x[13] ^= rotate(add(x[09], x[05]), 09)
            x[01] ^= rotate(add(x[13], x[09]), 13)
            x[05] ^= rotate(add(x[01], x[13]), 18)
            x[14] ^= rotate(add(x[10], x[06]), 07)
            x[02] ^= rotate(add(x[14], x[10]), 09)
            x[06] ^= rotate(add(x[02], x[14]), 13)
            x[10] ^= rotate(add(x[06], x[02]), 18)
            x[03] ^= rotate(add(x[15], x[11]), 07)
            x[07] ^= rotate(add(x[03], x[15]), 09)
            x[11] ^= rotate(add(x[07], x[03]), 13)
            x[15] ^= rotate(add(x[11], x[07]), 18)
            x[01] ^= rotate(add(x[00], x[03]), 07)
            x[02] ^= rotate(add(x[01], x[00]), 09)
            x[03] ^= rotate(add(x[02], x[01]), 13)
            x[00] ^= rotate(add(x[03], x[02]), 18)
            x[06] ^= rotate(add(x[05], x[04]), 07)
            x[07] ^= rotate(add(x[06], x[05]), 09)
            x[04] ^= rotate(add(x[07], x[06]), 13)
            x[05] ^= rotate(add(x[04], x[07]), 18)
            x[11] ^= rotate(add(x[10], x[09]), 07)
            x[08] ^= rotate(add(x[11], x[10]), 09)
            x[09] ^= rotate(add(x[08], x[11]), 13)
            x[10] ^= rotate(add(x[09], x[08]), 18)
            x[12] ^= rotate(add(x[15], x[14]), 07)
            x[13] ^= rotate(add(x[12], x[15]), 09)
            x[14] ^= rotate(add(x[13], x[12]), 13)
            x[15] ^= rotate(add(x[14], x[13]), 18)
        }

        for i in 0..<16 {
            toBytes(input: add(x[i], input[i]), output: &output, outputOffset: 4 * i)
        }
    }

    private func rotate(_ v: UInt32, _ c: UInt32) -> UInt32 {
        return (v << c) | (v >> (32 - c))
    }

    private func add(_ v: UInt32, _ w: UInt32) -> UInt32 {
        return v &+ w
    }

    private func toBytes(input: UInt32, output: inout [UInt8], outputOffset: Int) {
        var littleEndian = input.littleEndian
        let count = MemoryLayout<UInt32>.size
        let bytePtr = withUnsafePointer(to: &littleEndian) {
            $0.withMemoryRebound(to: UInt8.self, capacity: count) {
                UnsafeBufferPointer(start: $0, count: count)
            }
        }

        let byteArray = [UInt8](bytePtr)
        output[outputOffset] = byteArray[0]
        output[outputOffset + 1] = byteArray[1]
        output[outputOffset + 2] = byteArray[2]
        output[outputOffset + 3] = byteArray[3]
    }

    func protect(string: String) throws -> String {
        let stringBytes = [UInt8](string.utf8)

        var outputBuffer = [UInt8](repeating: 0, count: stringBytes.count)
        transformBlock(inputBuffer: stringBytes, inputOffset: 0, inputCount: stringBytes.count, outputBuffer: &outputBuffer, outputOffset: 0)

        let outputBufferData = Data(outputBuffer)

        return outputBufferData.base64EncodedString()
    }

    func unprotect(string: String) throws -> String {
        guard let base64Decoded = string.base64Decoded() else {
            throw KdbxCrypto.CryptoError.dataError
        }

        var outputBuffer = [UInt8](repeating: 0, count: base64Decoded.count)
        transformBlock(inputBuffer: base64Decoded, inputOffset: 0, inputCount: base64Decoded.count, outputBuffer: &outputBuffer, outputOffset: 0)

        guard let unprotectedString = String(bytes: outputBuffer, encoding: .utf8) else {
            throw KdbxCrypto.CryptoError.dataError
        }

        return unprotectedString
    }
}
