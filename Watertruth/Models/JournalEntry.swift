import Foundation
import SwiftData

@Model
final class JournalEntry {
    var id: UUID
    var createdAt: Date
    var caption: String
    var photoData: Data?
    var plant: Plant?

    init(caption: String = "", photoData: Data? = nil, plant: Plant? = nil) {
        self.id = UUID()
        self.createdAt = Date()
        self.caption = caption
        self.photoData = photoData
        self.plant = plant
    }
}
