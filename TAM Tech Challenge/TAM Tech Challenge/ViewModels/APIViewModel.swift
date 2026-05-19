import Foundation
import Combine

// ── Example API models ────────────────────────────────────────────────────────

struct UserProfile: Decodable, Identifiable {
    let id:    String
    let name:  String
    let email: String
}

struct Item: Codable, Identifiable {
    let id:       Int
    let name:     String
    let quantity: Int
}

struct APILogEntry: Identifiable {
    let id      = UUID()
    let method  : String
    let path    : String
    let result  : String
    let isError : Bool
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

@MainActor
final class APIViewModel: ObservableObject {

    @Published var logEntries : [APILogEntry] = []
    @Published var isLoading  = false
    @Published var errorMessage: String?

    private let client: AuthenticatedAPIClient

    init(authManager: OIDCAuthManager) {
        self.client = AuthenticatedAPIClient(authManager: authManager)
    }

    // ── Demo sequence (mirrors Python demo_api_calls) ─────────────────────────

    func runAllDemos() async {
        logEntries  = []
        isLoading   = true
        errorMessage = nil

        await demoGET()
        await demoGETWithParams()
        await demoPOST()
        await demoPUT()
        await demoPATCH()
        await demoDELETE()

        isLoading = false
    }

    // ── Individual demos ──────────────────────────────────────────────────────

    func demoGET() async {
        await run(method: "GET", path: "/api/v1/users/me") {
            try await self.client.get("/api/v1/users/me")
        }
    }

    func demoGETWithParams() async {
        await run(method: "GET", path: "/items?status=active") {
            try await self.client.get(
                "/items",
                queryItems: [URLQueryItem(name: "status", value: "active")]
            )
        }
    }

    func demoPOST() async {
        struct NewItem: Encodable { let name: String; let quantity: Int }
        await run(method: "POST", path: "/items") {
            try await self.client.post("/items", body: NewItem(name: "Widget", quantity: 3))
        }
    }

    func demoPUT() async {
        struct PutItem: Encodable { let name: String; let quantity: Int }
        await run(method: "PUT", path: "/items/1") {
            try await self.client.put("/items/1", body: PutItem(name: "Widget", quantity: 10))
        }
    }

    func demoPATCH() async {
        struct PatchItem: Encodable { let quantity: Int }
        await run(method: "PATCH", path: "/items/1") {
            try await self.client.patch("/items/1", body: PatchItem(quantity: 7))
        }
    }

    func demoDELETE() async {
        await run(method: "DELETE", path: "/items/1") {
            try await self.client.delete("/items/1")
        }
    }

    // ── Generic runner ────────────────────────────────────────────────────────

    private func run(method: String, path: String, action: () async throws -> Data) async {
        do {
            let data   = try await action()
            let result : String
            if data.isEmpty {
                result = "(204 No Content)"
            } else if let json = try? JSONSerialization.jsonObject(with: data),
                      let pretty = try? JSONSerialization.data(withJSONObject: json,
                                                               options: .prettyPrinted),
                      let str = String(data: pretty, encoding: .utf8) {
                result = str
            } else {
                result = String(data: data, encoding: .utf8) ?? "(binary)"
            }
            logEntries.append(APILogEntry(method: method, path: path,
                                          result: result, isError: false))
        } catch {
            logEntries.append(APILogEntry(method: method, path: path,
                                          result: error.localizedDescription, isError: true))
        }
    }
}
