import Foundation

enum PetChatMessageSender: String, Codable, Hashable, Sendable {
    case user
    case pet
}

struct PetChatStoredMessage: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let petType: PetType
    let sender: PetChatMessageSender
    let text: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        petType: PetType,
        sender: PetChatMessageSender,
        text: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.petType = petType
        self.sender = sender
        self.text = text
        self.createdAt = createdAt
    }
}
