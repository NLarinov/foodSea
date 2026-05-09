import Foundation

enum CategoryIconResolver {
    private static let topLevelIconBySlug: [String: String] = [
        "алкоголь": "wineglass",
        "готовая_еда": "takeoutbag.and.cup.and.straw",
        "детские_товары": "figure.child",
        "замороженные_продукты": "snowflake",
        "консервация": "cylinder",
        "крупы_и_макароны": "bag",
        "масло_соусы_специи": "drop.triangle",
        "молочные_продукты_яйца": "drop",
        "мясная_гастрономия": "fork.knife",
        "мясо_и_птица": "fork.knife.circle",
        "напитки": "waterbottle",
        "овощи_и_фрукты": "leaf",
        "одежда_обувь_текстиль": "tshirt",
        "орехи_чипсы_снеки": "circle.grid.3x3",
        "рыба_и_морепродукты": "fish",
        "сладости_десерты_мороженое": "birthday.cake",
        "средства_гигиены": "shower",
        "стирка_и_уборка": "washer",
        "сыры_и_масло": "square.grid.2x2",
        "тестовая_категория": "questionmark.square",
        "товары_для_дома": "house",
        "товары_для_животных": "pawprint",
        "хлеб_и_выпечка": "birthday.cake.fill",
        "чай_кофе": "cup.and.saucer",
        "энергетики": "bolt",
    ]

    private static let defaultIcon = "square.grid.2x2"

    static func icon(for slug: String) -> String {
        topLevelIconBySlug[slug] ?? defaultIcon
    }
}
