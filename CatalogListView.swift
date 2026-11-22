import SwiftUI

@MainActor
final class CatalogViewModel: ObservableObject {
    @Published var entries: [CatalogEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api: CatalogAPI

    init(api: CatalogAPI) {
        self.api = api
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            entries = try await api.fetchCatalog()
        } catch {
            errorMessage = "Не удалось загрузить каталог: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

struct CatalogListView: View {
    @StateObject private var viewModel: CatalogViewModel
    @StateObject private var downloadManager = DownloadManager()
    private let api: CatalogAPI

    init(catalogURL: URL) {
        let api = CatalogAPI(catalogURL: catalogURL)
        self.api = api
        _viewModel = StateObject(wrappedValue: CatalogViewModel(api: api))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.entries.isEmpty {
                    ProgressView("Загрузка каталога…")
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Text(error).multilineTextAlignment(.center)
                        Button("Повторить") { Task { await viewModel.load() } }
                    }
                    .padding()
                } else {
                    List(viewModel.entries) { entry in
                        NavigationLink(value: entry) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.title).font(.headline)
                                Text("v\(entry.version) · \(entry.formattedSize)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .refreshable { await viewModel.load() }
                }
            }
            .navigationTitle("Каталог")
            .navigationDestination(for: CatalogEntry.self) { entry in
                AppDetailView(entry: entry, api: api, downloadManager: downloadManager)
            }
        }
        .task { await viewModel.load() }
    }
}

extension CatalogEntry: Hashable {
    static func == (lhs: CatalogEntry, rhs: CatalogEntry) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
