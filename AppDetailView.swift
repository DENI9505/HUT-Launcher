import SwiftUI

struct AppDetailView: View {
    let entry: CatalogEntry
    let api: CatalogAPI
    @ObservedObject var downloadManager: DownloadManager

    private var progress: Double { downloadManager.progressByEntryId[entry.id] ?? 0 }
    private var savedURL: URL? { downloadManager.savedFileURLByEntryId[entry.id] }
    private var error: String? { downloadManager.errorByEntryId[entry.id] }
    private var isDownloading: Bool { progress > 0 && progress < 1 && savedURL == nil }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(entry.title).font(.title2).bold()
                Text("Версия \(entry.version) · \(entry.formattedSize)")
                    .foregroundStyle(.secondary)
                Text(entry.description)

                if let savedURL {
                    Label("Сохранено: \(savedURL.lastPathComponent)", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Файл доступен в приложении «Файлы» → На айфоне → [имя вашего приложения].")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else if isDownloading {
                    ProgressView(value: progress)
                    Text("\(Int(progress * 100))%")
                } else if let error {
                    Text("Ошибка: \(error)").foregroundStyle(.red)
                }

                Button {
                    downloadManager.download(entry: entry, from: api.downloadURL(for: entry))
                } label: {
                    Label(
                        savedURL == nil ? "Скачать IPA" : "Скачать повторно",
                        systemImage: "arrow.down.circle"
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(isDownloading)
            }
            .padding()
        }
        .navigationTitle(entry.title)
    }
}
