import Foundation

struct CatalogEntry: Decodable, Identifiable, Equatable {
    let id: String
    let title: String
    let version: String
    let description: String
    let downloadURL: URL
    let sizeBytes: Int

    enum CodingKeys: String, CodingKey {
        case id, title, version, description
        case downloadURL = "download_url"
        case sizeBytes = "size_bytes"
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(sizeBytes), countStyle: .file)
    }
}
