import Foundation

/// Reads the catalog straight from a GitHub Release — no backend to deploy at all.
/// catalogURL points at a raw catalog.json (e.g. raw.githubusercontent.com/you/repo/main/catalog.json);
/// each entry's download_url points at its own GitHub Release asset.
final class CatalogAPI {
    private let catalogURL: URL
    private let session: URLSession

    init(catalogURL: URL, session: URLSession = .shared) {
        self.catalogURL = catalogURL
        self.session = session
    }

    func fetchCatalog() async throws -> [CatalogEntry] {
        let (data, response) = try await session.data(from: catalogURL)
        try Self.checkStatus(response)
        return try JSONDecoder().decode([CatalogEntry].self, from: data)
    }

    /// URL to hand to a URLSessionDownloadTask (see DownloadManager) — just the entry's own asset link.
    func downloadURL(for entry: CatalogEntry) -> URL {
        entry.downloadURL
    }

    private static func checkStatus(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "CatalogAPI", code: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }
    }
}
