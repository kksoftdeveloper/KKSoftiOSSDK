import Foundation

public struct GamePackageStatusOutput: Codable {
    let sku: String
    let status: String
    let price: Int
    let point: Int
    let alias: String?
    let description: String?
}
