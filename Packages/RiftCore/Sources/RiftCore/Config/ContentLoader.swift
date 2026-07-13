import Foundation

public enum ContentLoader {
    public static func load(from directory: URL) throws -> ContentCatalog {
        let decoder = JSONDecoder()

        let catalog = try ContentCatalog(
            classes: load("classes.json", from: directory, using: decoder),
            skills: load("skills.json", from: directory, using: decoder),
            items: load("items.json", from: directory, using: decoder),
            quests: load("quests.json", from: directory, using: decoder),
            dialogues: load("dialogs.json", from: directory, using: decoder)
        )
        try ContentValidator.validate(catalog)
        return catalog
    }

    private static func load<T: Decodable>(_ fileName: String, from directory: URL, using decoder: JSONDecoder) throws -> T {
        let url = directory.appending(path: fileName)
        let data = try Data(contentsOf: url)
        return try decoder.decode(T.self, from: data)
    }
}
