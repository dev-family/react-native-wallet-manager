import Compression
import Foundation

// A .pkpasses bundle is a ZIP archive whose entries are .pkpass files.
enum PassesBundle {
  private static let maxEntries = 512
  private static let maxEntrySize = 32 * 1024 * 1024
  private static let maxTotalSize = 128 * 1024 * 1024

  private static let endOfCentralDirectorySignature = 0x06054b50
  private static let centralDirectorySignature = 0x02014b50
  private static let localHeaderSignature = 0x04034b50
  private static let zip64EndOfCentralDirectorySignature = 0x06064b50
  private static let zip64LocatorSignature = 0x07064b50
  private static let zip64ExtraFieldId = 0x0001

  // MARK: - extractPassEntries

  static func extractPassEntries(from data: Data) -> [Data] {
    let bytes = [UInt8](data)
    let count = bytes.count
    guard count >= 22 else { return [] }

    func uint16(_ offset: Int) -> Int {
      Int(bytes[offset]) | Int(bytes[offset + 1]) << 8
    }
    func uint32(_ offset: Int) -> Int {
      uint16(offset) | uint16(offset + 2) << 16
    }
    func uint64(_ offset: Int) -> UInt64 {
      UInt64(uint32(offset)) | UInt64(uint32(offset + 4)) << 32
    }
    // Caps 64-bit values so that later bounds checks fail instead of overflowing.
    func clamped(_ value: UInt64, limit: Int) -> Int {
      value > UInt64(limit) ? limit : Int(value)
    }
    func hasSignature(_ signature: Int, at offset: Int) -> Bool {
      offset >= 0 && offset + 4 <= count && uint32(offset) == signature
    }

    var eocd = -1
    var position = count - 22
    let lowerBound = max(0, count - 22 - 0xFFFF)
    while position >= lowerBound {
      if hasSignature(endOfCentralDirectorySignature, at: position),
         position + 22 + uint16(position + 20) == count {
        eocd = position
        break
      }
      position -= 1
    }
    guard eocd >= 0 else { return [] }

    var diskNumber = uint16(eocd + 4)
    var centralDirectoryDisk = uint16(eocd + 6)
    var diskEntries = uint16(eocd + 8)
    var totalEntries = uint16(eocd + 10)
    var centralDirectorySize = uint32(eocd + 12)
    var centralDirectoryOffset = uint32(eocd + 16)
    var centralDirectoryLimit = eocd

    // ZIP64: the real values live in a ZIP64 end of central directory record,
    // found through the locator right before the regular record.
    let locator = eocd - 20
    let needsZip64 = diskNumber == 0xFFFF || centralDirectoryDisk == 0xFFFF
      || diskEntries == 0xFFFF || totalEntries == 0xFFFF
      || centralDirectorySize == 0xFFFFFFFF || centralDirectoryOffset == 0xFFFFFFFF
    if hasSignature(zip64LocatorSignature, at: locator) {
      let record = clamped(uint64(locator + 8), limit: count)
      if uint32(locator + 16) <= 1,
         record + 56 <= locator,
         hasSignature(zip64EndOfCentralDirectorySignature, at: record) {
        diskNumber = uint32(record + 16)
        centralDirectoryDisk = uint32(record + 20)
        diskEntries = clamped(uint64(record + 24), limit: maxEntries + 1)
        totalEntries = clamped(uint64(record + 32), limit: maxEntries + 1)
        centralDirectorySize = clamped(uint64(record + 40), limit: count)
        centralDirectoryOffset = clamped(uint64(record + 48), limit: count)
        centralDirectoryLimit = record
      } else if needsZip64 {
        print("wallet", "Invalid ZIP64 bundle archive")
        return []
      }
    } else if needsZip64 {
      print("wallet", "Invalid ZIP64 bundle archive")
      return []
    }

    guard diskNumber == 0,
          centralDirectoryDisk == 0,
          diskEntries == totalEntries
    else {
      print("wallet", "Unsupported multi-disk bundle archive")
      return []
    }
    guard totalEntries <= maxEntries,
          centralDirectoryOffset + centralDirectorySize <= centralDirectoryLimit
    else {
      print("wallet", "Invalid bundle archive")
      return []
    }

    let centralDirectoryEnd = centralDirectoryOffset + centralDirectorySize
    var header = centralDirectoryOffset
    var entries: [Data] = []
    var totalSize = 0

    for _ in 0..<totalEntries {
      guard header + 46 <= centralDirectoryEnd,
            hasSignature(centralDirectorySignature, at: header)
      else {
        print("wallet", "Invalid bundle central directory")
        return []
      }

      let flags = uint16(header + 8)
      let method = uint16(header + 10)
      var compressedSize = uint32(header + 20)
      var uncompressedSize = uint32(header + 24)
      let nameLength = uint16(header + 28)
      let extraLength = uint16(header + 30)
      let commentLength = uint16(header + 32)
      var localHeader = uint32(header + 42)
      let nameStart = header + 46
      let nextHeader = nameStart + nameLength + extraLength + commentLength

      guard nextHeader <= centralDirectoryEnd else {
        print("wallet", "Invalid bundle central directory")
        return []
      }
      let name = String(decoding: bytes[nameStart..<(nameStart + nameLength)], as: UTF8.self)
      header = nextHeader

      guard isPassEntry(name) else { continue }

      // Bits 0, 6 and 13 mark encrypted entries.
      guard flags & 0x2041 == 0 else {
        print("wallet", "Skipping encrypted bundle entry", name)
        continue
      }
      if uncompressedSize == 0xFFFFFFFF || compressedSize == 0xFFFFFFFF || localHeader == 0xFFFFFFFF {
        // The ZIP64 extra field holds, in this order, only the values that are
        // 0xFFFFFFFF in the header.
        let wanted = [uncompressedSize, compressedSize, localHeader].filter { $0 == 0xFFFFFFFF }.count
        var values: [UInt64]?
        var field = nameStart + nameLength
        let extraEnd = field + extraLength
        while field + 4 <= extraEnd {
          let id = uint16(field)
          let size = uint16(field + 2)
          guard field + 4 + size <= extraEnd else { break }
          if id == zip64ExtraFieldId {
            if size >= wanted * 8 {
              values = (0..<wanted).map { uint64(field + 4 + $0 * 8) }
            }
            break
          }
          field += 4 + size
        }
        guard var remaining = values?[...] else {
          print("wallet", "Skipping bundle entry with invalid ZIP64 data", name)
          continue
        }
        if uncompressedSize == 0xFFFFFFFF {
          uncompressedSize = clamped(remaining.removeFirst(), limit: maxEntrySize + 1)
        }
        if compressedSize == 0xFFFFFFFF {
          compressedSize = clamped(remaining.removeFirst(), limit: count)
        }
        if localHeader == 0xFFFFFFFF {
          localHeader = clamped(remaining.removeFirst(), limit: count)
        }
      }
      guard uncompressedSize > 0 else { continue }
      guard uncompressedSize <= maxEntrySize,
            totalSize + uncompressedSize <= maxTotalSize
      else {
        print("wallet", "Skipping oversized bundle entry", name)
        continue
      }
      guard localHeader + 30 <= count,
            hasSignature(localHeaderSignature, at: localHeader)
      else {
        print("wallet", "Skipping bundle entry with invalid local header", name)
        continue
      }

      // Sizes come from the central directory: the local header holds zeros
      // when the entry uses a data descriptor (flag bit 3).
      let dataStart = localHeader + 30 + uint16(localHeader + 26) + uint16(localHeader + 28)
      guard dataStart + compressedSize <= count else {
        print("wallet", "Skipping truncated bundle entry", name)
        continue
      }

      let payload: [UInt8]?
      switch method {
      case 0:
        payload = compressedSize == uncompressedSize
          ? Array(bytes[dataStart..<(dataStart + compressedSize)])
          : nil
      case 8:
        payload = inflate(bytes, start: dataStart, length: compressedSize, expectedSize: uncompressedSize)
      default:
        print("wallet", "Skipping bundle entry with unsupported compression method \(method)", name)
        continue
      }

      guard let payload = payload else {
        print("wallet", "Failed to read bundle entry", name)
        continue
      }
      entries.append(Data(payload))
      totalSize += uncompressedSize
    }

    return entries
  }

  // MARK: - Helper

  private static func isPassEntry(_ name: String) -> Bool {
    guard !name.hasSuffix("/") else { return false }
    let components = name.split(separator: "/")
    guard let fileName = components.last,
          !components.contains("__MACOSX"),
          !fileName.hasPrefix(".")
    else { return false }
    return fileName.lowercased().hasSuffix(".pkpass")
  }

  // COMPRESSION_ZLIB decodes raw DEFLATE (RFC 1951), which is ZIP method 8.
  private static func inflate(_ bytes: [UInt8],
                              start: Int,
                              length: Int,
                              expectedSize: Int) -> [UInt8]? {
    guard length > 0, expectedSize > 0 else { return nil }

    // One spare byte tells a stream longer than declared from an exact fit.
    var output = [UInt8](repeating: 0, count: expectedSize + 1)
    let written = bytes.withUnsafeBufferPointer { source -> Int in
      output.withUnsafeMutableBufferPointer { destination -> Int in
        guard let sourceBase = source.baseAddress,
              let destinationBase = destination.baseAddress
        else { return 0 }
        return compression_decode_buffer(destinationBase,
                                         destination.count,
                                         sourceBase + start,
                                         length,
                                         nil,
                                         COMPRESSION_ZLIB)
      }
    }
    guard written == expectedSize else { return nil }
    output.removeLast()
    return output
  }
}
