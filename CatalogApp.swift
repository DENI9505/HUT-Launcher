import SwiftUI

@main
struct CatalogApp: App {
    // Замените на raw-ссылку на catalog.json в вашем GitHub-репозитории, например:
    // https://raw.githubusercontent.com/ваш-ник/catalog-ios-app/main/catalog.json
    private let catalogURL = URL(string: "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/catalog.json")!

    var body: some Scene {
        WindowGroup {
            CatalogListView(catalogURL: catalogURL)
        }
    }
}
