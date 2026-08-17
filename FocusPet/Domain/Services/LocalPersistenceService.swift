import Foundation

struct FocusPetPersistedState: Codable, Hashable, Sendable {
    var schemaVersion: Int
    var tasks: [TaskItem]
    var memoItems: [MemoItem]
    var focusSessions: [FocusSession]
    var settings: AppSettings
    var petChatMessages: [PetChatStoredMessage]

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case tasks
        case memoItems
        case focusSessions
        case settings
        case petChatMessages
    }

    init(
        schemaVersion: Int = 1,
        tasks: [TaskItem],
        memoItems: [MemoItem],
        focusSessions: [FocusSession],
        settings: AppSettings,
        petChatMessages: [PetChatStoredMessage] = []
    ) {
        self.schemaVersion = schemaVersion
        self.tasks = tasks
        self.memoItems = memoItems
        self.focusSessions = focusSessions
        self.settings = settings
        self.petChatMessages = petChatMessages
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        tasks = try container.decode([TaskItem].self, forKey: .tasks)
        memoItems = try container.decode([MemoItem].self, forKey: .memoItems)
        focusSessions = try container.decode([FocusSession].self, forKey: .focusSessions)
        settings = try container.decode(AppSettings.self, forKey: .settings)
        petChatMessages = try container.decodeIfPresent([PetChatStoredMessage].self, forKey: .petChatMessages) ?? []
    }
}

struct LocalPersistenceService {
    private let fileURL: URL?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileURL: URL?) {
        self.fileURL = fileURL

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    static var live: LocalPersistenceService {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return .disabled
        }

        let supportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        let appDirectory = supportDirectory.appendingPathComponent("FocusPet", isDirectory: true)
        return LocalPersistenceService(fileURL: appDirectory.appendingPathComponent("focuspet-state.json"))
    }

    static let disabled = LocalPersistenceService(fileURL: nil)

    func loadState() throws -> FocusPetPersistedState? {
        guard let fileURL, FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(FocusPetPersistedState.self, from: data)
    }

    func saveState(_ state: FocusPetPersistedState) throws {
        guard let fileURL else { return }

        let directoryURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        let data = try encoder.encode(state)
        try data.write(to: fileURL, options: [.atomic])
    }
}
