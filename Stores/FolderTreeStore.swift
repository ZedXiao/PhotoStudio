import Foundation
import Observation
import PhotoStudioCore

@MainActor @Observable
final class FolderTreeStore {
    private(set) var children: [URL: [URL]] = [:]
    private(set) var errors: [URL: String] = [:]
    private(set) var loading: Set<URL> = []
    @ObservationIgnored private var revisions: [URL: UUID] = [:]
    @ObservationIgnored private var tasks: [URL: Task<Void, Never>] = [:]

    func load(_ url: URL, force: Bool = false) {
        guard force || (children[url] == nil && tasks[url] == nil && errors[url] == nil) else { return }
        tasks[url]?.cancel()
        errors[url] = nil
        loading.insert(url)
        let revision = UUID(); revisions[url] = revision
        tasks[url] = Task { [weak self] in
            let result = await Task.detached(priority: .utility) { Result { try FolderScanner.subdirectories(of: url) } }.value
            guard let self, self.revisions[url] == revision, !Task.isCancelled else { return }
            self.tasks[url] = nil
            self.loading.remove(url)
            switch result {
            case .success(let urls): self.children[url] = urls
            case .failure(let error): self.errors[url] = error.localizedDescription
            }
        }
    }
    func update(_ url: URL, children: [URL]) {
        tasks[url]?.cancel(); tasks[url] = nil; revisions[url] = UUID()
        loading.remove(url)
        self.children[url] = children; errors[url] = nil
    }
}
