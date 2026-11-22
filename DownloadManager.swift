import Foundation

@MainActor
final class DownloadManager: NSObject, ObservableObject {
    @Published var progressByEntryId: [String: Double] = [:]
    @Published var savedFileURLByEntryId: [String: URL] = [:]
    @Published var errorByEntryId: [String: String] = [:]

    private var session: URLSession!
    private var entryIdByTask: [Int: String] = [:]

    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    /// Downloads the IPA and saves it into the app's Documents folder, where it shows up
    /// in the Files app (requires UIFileSharingEnabled + LSSupportsOpeningDocumentsInPlace
    /// in Info.plist — see Info.plist.snippet.xml).
    func download(entry: CatalogEntry, from url: URL) {
        errorByEntryId[entry.id] = nil
        progressByEntryId[entry.id] = 0

        let task = session.downloadTask(with: url)
        entryIdByTask[task.taskIdentifier] = entry.id
        task.taskDescription = entry.filename
        task.resume()
    }

    private func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

extension DownloadManager: URLSessionDownloadDelegate {
    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let fraction = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        let taskId = downloadTask.taskIdentifier
        Task { @MainActor in
            if let entryId = self.entryIdByTask[taskId] {
                self.progressByEntryId[entryId] = fraction
            }
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        let taskId = downloadTask.taskIdentifier
        let filename = downloadTask.taskDescription ?? "download-\(taskId).ipa"

        // Move out of the temp location synchronously, before the system deletes it.
        let fm = FileManager.default
        let destination = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
        var moveError: Error?
        do {
            if fm.fileExists(atPath: destination.path) {
                try fm.removeItem(at: destination)
            }
            try fm.moveItem(at: location, to: destination)
        } catch {
            moveError = error
        }

        Task { @MainActor in
            guard let entryId = self.entryIdByTask[taskId] else { return }
            self.entryIdByTask[taskId] = nil
            if let moveError {
                self.errorByEntryId[entryId] = moveError.localizedDescription
            } else {
                self.savedFileURLByEntryId[entryId] = destination
                self.progressByEntryId[entryId] = 1.0
            }
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let error else { return }
        let taskId = task.taskIdentifier
        Task { @MainActor in
            guard let entryId = self.entryIdByTask[taskId] else { return }
            self.entryIdByTask[taskId] = nil
            self.errorByEntryId[entryId] = error.localizedDescription
        }
    }
}
