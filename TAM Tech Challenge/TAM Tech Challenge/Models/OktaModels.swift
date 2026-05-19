//
//  OktaModels.swift
//  TAM Tech Challenge
//
//  Generated using Claude and further edited by Kenny Barnt on 2026-05-17.
//

import Foundation

// MARK: - Shared HAL Link Types

/// A single HAL link object returned in `_links`.
struct OktaLink: Codable {
    let href: String
    let name: String?
    let type: String?          // e.g. "image/png", "application/json"
    let hints: OktaLinkHints?
}

struct OktaLinkHints: Codable {
    let allow: [String]?       // HTTP methods permitted, e.g. ["POST"]
}

// MARK: - User

/// Top-level User object returned by GET /api/v1/users/{userId}
@Observable
class OktaUser: Codable, Identifiable, Hashable {
    static func == (lhs: OktaUser, rhs: OktaUser) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: Identity
    let id: String

    // MARK: Lifecycle timestamps (ISO-8601 strings; nullable in the API)
    let created: Date?
    let activated: Date?
    let statusChanged: Date?
    let lastLogin: Date?
    let lastUpdated: Date?
    let passwordChanged: Date?

    // MARK: Status
    let status: OktaUserStatus

    /// The status the user is transitioning to (present only during a lifecycle change).
    let transitioningToStatus: OktaUserStatus?

    // MARK: Nested objects
    let type: OktaUserTypeRef?
    let profile: OktaUserProfile
    let credentials: OktaUserCredentials?

    // MARK: HAL
    /// Key-value map of link relation name → link (or array of links for "logo").
    let links: OktaUserLinks?

    enum CodingKeys: String, CodingKey {
        case id, created, activated, statusChanged, lastLogin, lastUpdated,
             passwordChanged, status, transitioningToStatus, type, profile,
             credentials
        case links = "_links"
    }
}

/// Possible lifecycle statuses for an Okta user.
enum OktaUserStatus: String, Codable {
    case staged       = "STAGED"
    case provisioned  = "PROVISIONED"
    case active       = "ACTIVE"
    case recovery     = "RECOVERY"
    case lockedOut    = "LOCKED_OUT"
    case passwordExpired = "PASSWORD_EXPIRED"
    case suspended    = "SUSPENDED"
    case deprovisioned = "DEPROVISIONED"
}

/// Thin reference to the User Type object.
struct OktaUserTypeRef: Codable {
    let id: String
}

// MARK: User Profile

/// Base (standard) user profile attributes. Custom attributes are stored
/// alongside these in the JSON object; capture them via `additionalProperties`
/// if needed, or extend this struct with your org-specific fields.
struct OktaUserProfile: Codable {
    // Core identity
    let login: String
    let email: String
    let secondEmail: String?

    // Name
    let firstName: String?
    let lastName: String?
    let middleName: String?
    let honorificPrefix: String?
    let honorificSuffix: String?
    let displayName: String?
    let nickName: String?

    // Contact
    let profileUrl: String?
    let primaryPhone: String?
    let mobilePhone: String?

    // Organization
    let organization: String?
    let division: String?
    let department: String?
    let costCenter: String?
    let employeeNumber: String?
    let title: String?

    // Address
    let streetAddress: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let countryCode: String?
    let postalAddress: String?

    // Locale / timezone
    let locale: String?           // BCP 47 language tag, e.g. "en_US"
    let timezone: String?         // IANA timezone name, e.g. "America/Los_Angeles"

    // Directory
    let userType: String?
    let preferredLanguage: String?

    // Manager relationship
    let manager: String?
    let managerId: String?
}

// MARK: User Credentials

/// Primary authentication and recovery credentials.
struct OktaUserCredentials: Codable {
    let password: OktaPasswordCredential?
    let recoveryQuestion: OktaRecoveryQuestionCredential?
    let provider: OktaAuthenticationProvider?
}

/// Password credential. The `hash` field is only present when importing
/// a hashed password; `value` is write-only and never returned.
struct OktaPasswordCredential: Codable {
    let value: String?    // write-only; always nil in GET responses
    let hash: OktaPasswordHash?
    let hook: OktaPasswordHook?
}

struct OktaPasswordHash: Codable {
    let algorithm: String   // e.g. "BCRYPT", "SHA-512", "MD5"
    let workFactor: Int?
    let salt: String?
    let saltOrder: String?
    let value: String?
}

struct OktaPasswordHook: Codable {
    let type: String
}

struct OktaRecoveryQuestionCredential: Codable {
    let question: String?
    let answer: String?     // write-only; always nil in GET responses
}

/// Credential provider information.
struct OktaAuthenticationProvider: Codable {
    let type: OktaProviderType
    let name: String?
}

enum OktaProviderType: String, Codable {
    case okta        = "OKTA"
    case active_directory = "ACTIVE_DIRECTORY"
    case ldap        = "LDAP"
    case federation  = "FEDERATION"
    case social      = "SOCIAL"
    case import_type = "IMPORT"
}

// MARK: User HAL Links

/// HAL `_links` block on a User. Lifecycle links are only present when
/// the corresponding transition is allowed for the user's current status.
struct OktaUserLinks: Codable {
    let `self`: OktaLink?
    let activate: OktaLink?
    let deactivate: OktaLink?
    let suspend: OktaLink?
    let unsuspend: OktaLink?
    let resetPassword: OktaLink?
    let expirePassword: OktaLink?
    let forgotPassword: OktaLink?
    let resetFactors: OktaLink?
    let unlock: OktaLink?
    let changePassword: OktaLink?
    let changeRecoveryQuestion: OktaLink?
    let schema: OktaLink?
    let type: OktaLink?
}

// MARK: - Group

/// Top-level Group object returned by GET /api/v1/groups/{groupId}
struct OktaGroup: Codable {
    // MARK: Identity
    let id: String

    // MARK: Timestamps
    let created: Date?
    let lastUpdated: Date?
    let lastMembershipUpdated: Date?

    // MARK: Classification
    /// Determines which profile schema the group uses.
    /// e.g. ["okta:user_group"] or ["okta:windows_security_principal"]
    let objectClass: [String]?

    let type: OktaGroupType

    // MARK: Nested objects
    let profile: OktaGroupProfile

    // MARK: HAL
    let links: OktaGroupLinks?

    /// Present on APP_GROUP groups synced from an external source (AD, SCIM).
    let source: OktaGroupSource?

    enum CodingKeys: String, CodingKey {
        case id, created, lastUpdated, lastMembershipUpdated,
             objectClass, type, profile, source
        case links = "_links"
    }
}

/// The origin/type of a Group.
enum OktaGroupType: String, Codable {
    /// Managed in Okta.
    case oktaGroup   = "OKTA_GROUP"
    /// Synced from Active Directory or another app.
    case appGroup    = "APP_GROUP"
    /// Built-in Okta system group (e.g. "Everyone").
    case builtIn     = "BUILT_IN"
}

// MARK: Group Profile

/// Standard group profile. App groups may carry additional attributes
/// (e.g. samAccountName, objectSid) that can be added below or handled
/// via a custom Decodable implementation.
struct OktaGroupProfile: Codable {
    let name: String
    let description: String?

    // Active Directory / Windows security principal extensions
    // (present when objectClass contains "okta:windows_security_principal")
    let groupType: String?
    let samAccountName: String?
    let objectSid: String?
    let groupScope: String?
    let windowsDomainQualifiedName: String?
    let dn: String?
    let externalId: String?
}

// MARK: Group Source

/// Identifies the app that is the authoritative source for an APP_GROUP.
struct OktaGroupSource: Codable {
    let id: String
    let name: String?
    let type: String?
}

// MARK: Group HAL Links

struct OktaGroupLinks: Codable {
    let `self`: OktaLink?
    /// Array of logo link objects (medium, large).
    let logo: [OktaLink]?
    let users: OktaLink?
    let apps: OktaLink?
    let owners: OktaLink?
    let source: OktaLink?
}

// MARK: - JSON Decoder helper

extension JSONDecoder {
    /// A decoder pre-configured for Okta Management API responses:
    /// ISO-8601 fractional-second dates and snake_case → camelCase key conversion.
    static var okta: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: string) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(string)"
            )
        }
        // CodingKeys are already defined manually above, so no key strategy needed.
        return decoder
    }
}
