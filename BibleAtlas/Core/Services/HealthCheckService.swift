import Foundation

enum HealthStatus: Equatable {
    case ok
    case maintenance(message: String)
    case blocked(message: String)
}

struct HealthDTO: Decodable, Encodable {
    let status: String        // "ok" | "maintenance" | ...
    let timestamp: String
}

protocol HealthCheckServiceProtocol {
    func check() async throws -> HealthStatus
}

final class HealthCheckService: HealthCheckServiceProtocol {
    private let baseURL: URL
    private let timeout: TimeInterval

    init(baseURLString: String, timeout: TimeInterval = 8) {
        self.baseURL = URL(string: baseURLString)!
        self.timeout = timeout
    }

    func check() async throws -> HealthStatus {
        let url = baseURL.appendingPathComponent("health") // no leading slash
        var req = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: timeout
        )
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)

            guard let http = resp as? HTTPURLResponse else {
                return .blocked(message: "Invalid response type.")
            }

            // Non-2xx → parse server error body (NestJS style) OR map by status code
            guard (200..<300).contains(http.statusCode) else {
                let serverMsg = Self.parseServerErrorMessage(from: data)
                let friendly = Self.friendlyMessage(for: http.statusCode, serverMessage: serverMsg)
                return .blocked(message: friendly)
            }

            // 2xx → parse health payload (strict: must decode and be "ok"/"maintenance")
            guard let dto = try? JSONDecoder().decode(HealthDTO.self, from: data) else {
                return .blocked(message: "Failed to parse response.")
            }

            switch dto.status.lowercased() {
            case "ok":
                return .ok
            case "maintenance":
                return .maintenance(message: "Under maintenance (\(dto.timestamp)).")
            default:
                return .blocked(message: "Access is restricted.")
            }

        } catch let e as URLError {
            // Network-level mapping (timeouts, offline, unreachable, SSL, etc.)
            let msg: String
            switch e.code {
            case .timedOut:
                msg = "Request timed out. Please check your connection and try again."
            case .notConnectedToInternet, .networkConnectionLost:
                msg = "No internet connection."
            case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                msg = "Cannot reach the server."
            case .appTransportSecurityRequiresSecureConnection,
                 .secureConnectionFailed,
                 .serverCertificateUntrusted,
                 .clientCertificateRejected,
                 .clientCertificateRequired:
                msg = "Secure connection failed."
            default:
                msg = "Network error: \(e.localizedDescription)"
            }
            return .blocked(message: msg)
        } catch {
            return .blocked(message: "Unexpected error: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    /// Accepts both `message: "text"` and `message: ["a","b"]` from NestJS-style errors.
    private static func parseServerErrorMessage(from data: Data) -> String? {
        guard !data.isEmpty else { return nil }
        if let dto = try? JSONDecoder().decode(ServerErrorDTO.self, from: data),
           let msg = dto.message?.joined, !msg.isEmpty {
            return msg
        }
        return nil
    }

    /// Human-readable defaults per HTTP status code (fallback when server message is absent).
    private static func friendlyMessage(for statusCode: Int, serverMessage: String?) -> String {
        if let m = serverMessage, !m.isEmpty { return "\(m) (\(statusCode))" }
        switch statusCode {
        case 400: return "Invalid request. (400)"
        case 401: return "Authentication required. Please sign in again. (401)"
        case 403: return "Forbidden resource. You do not have permission. (403)"
        case 404: return "Endpoint not found. (404)"
        case 409: return "Request conflicts with the current state. (409)"
        case 410: return "The requested resource is no longer available. (410)"
        case 412: return "Precondition failed. (412)"
        case 415: return "Unsupported media type. (415)"
        case 422: return "Validation failed. Please check your input. (422)"
        case 426: return "Upgrade required. (426)"
        case 428: return "Precondition required. (428)"
        case 429: return "Too many requests. Please try again later. (429)"
        case 431: return "Request headers are too large. (431)"
        case 451: return "Unavailable for legal reasons. (451)"
        case 500: return "Server error. Please try again later. (500)"
        case 502: return "Bad gateway. (502)"
        case 503: return "Service unavailable. Please try again later. (503)"
        case 504: return "Gateway timeout. (504)"
        default:  return "Server error (\(statusCode))."
        }
    }
}

// MARK: - NestJS-style error decoding

private enum ErrorMessage: Decodable {
    case text(String)
    case list([String])

    var joined: String {
        switch self {
        case .text(let s): return s
        case .list(let arr): return arr.joined(separator: "\n")
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self) {
            self = .text(s)
        } else if let a = try? c.decode([String].self) {
            self = .list(a)
        } else {
            self = .text("Unknown error")
        }
    }
}

private struct ServerErrorDTO: Decodable {
    let message: ErrorMessage?
    let error: String?
    let statusCode: Int?
}
