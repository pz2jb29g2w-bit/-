import Foundation

struct Exercise: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let primaryMuscles: [MuscleGroup]
    let secondaryMuscles: [MuscleGroup]
    let equipment: String
    let isAnytimeCompatible: Bool
    let difficulty: Difficulty

    enum Difficulty: String, Codable {
        case beginner     = "初心者向け"
        case intermediate = "中級者向け"
        case advanced     = "上級者向け"
    }

    var videoSearchURL: URL? {
        let query = "\(name) やり方 筋トレ フォーム"
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "https://www.youtube.com/results?search_query=\(encoded)")
    }

    init(
        id: UUID = UUID(),
        name: String,
        primaryMuscles: [MuscleGroup],
        secondaryMuscles: [MuscleGroup] = [],
        equipment: String,
        isAnytimeCompatible: Bool = true,
        difficulty: Difficulty = .intermediate
    ) {
        self.id = id
        self.name = name
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.equipment = equipment
        self.isAnytimeCompatible = isAnytimeCompatible
        self.difficulty = difficulty
    }
}
