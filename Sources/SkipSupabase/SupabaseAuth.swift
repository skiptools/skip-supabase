// Copyright 2024–2026 Skip
// SPDX-License-Identifier: MPL-2.0
import Foundation

#if !SKIP
@_exported import Supabase
#else
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.FlowType
import io.github.jan.supabase.createSupabaseClient

import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.minimalSettings
#endif

#if SKIP

// SKIP NOWARN
// This extension will be moved into its extended type definition when translated to Kotlin. It will not be able to access this file's private types or fileprivate members
extension SupabaseClient {
    public var auth: AuthClient {
        AuthClient(auth: client.auth)
    }
}

public class AuthClient {
    public let auth: io.github.jan.supabase.auth.Auth

    init(auth: io.github.jan.supabase.auth.Auth) {
        self.auth = auth
    }

    public var session: Session {
        get throws {
            guard let session = auth.currentSessionOrNull() else {
                throw AuthError.sessionMissing
            }
            return Session(session: session)
        }
    }

    public var currentSession: Session? {
        guard let session = auth.currentSessionOrNull() else {
            return nil
        }

        return Session(session: session)
    }

    public func signIn(email: String, password: String, captchaToken: String? = nil) async throws {
        // SKIP NOWARN
        try await auth.signInWith(io.github.jan.supabase.auth.providers.builtin.Email) {
            self.email = email
            self.password = password
            self.captchaToken = captchaToken
        }
    }

    public func signUp(email: String, password: String) async throws {
        // SKIP NOWARN
        try await auth.signUpWith(io.github.jan.supabase.auth.providers.builtin.Email) {
            self.email = email
            self.password = password
        }
    }

    public func signIn(phone: String, password: String, captchaToken: String? = nil) async throws {
        // SKIP NOWARN
        try await auth.signInWith(io.github.jan.supabase.auth.providers.builtin.Phone) {
            self.phone = phone
            self.password = password
            self.captchaToken = captchaToken
        }
    }

    public func signInAnonymously(data: [String: AnyJSON]? = nil, captchaToken: String? = nil) async throws {
        // SKIP NOWARN
        try await auth.signInAnonymously(data: dict2JsonObject(data), captchaToken: captchaToken)
    }

    public func signOut(scope: SignOutScope = .global) async throws {
        // SKIP NOWARN
        try await auth.signOut(scope.kotlinScope)
    }

    /// Refresh the current session. Returns the refreshed session.
    @discardableResult
    public func refreshSession(refreshToken: String? = nil) async throws -> Session {
        // SKIP NOWARN
        try await auth.refreshCurrentSession()
        guard let session = auth.currentSessionOrNull() else {
            throw AuthError.sessionMissing
        }
        return Session(session: session)
    }

    /// Update the current user's attributes (email, phone, password, or metadata).
    @discardableResult
    public func update(user attributes: UserAttributes) async throws -> User {
        // SKIP NOWARN
        let userInfo = try await auth.updateUser {
            if let email = attributes.email { self.email = email }
            if let phone = attributes.phone { self.phone = phone }
            if let password = attributes.password { self.password = password }
        }
        return User(userInfo: userInfo)
    }
}

/// Errors that can occur during authentication.
public enum AuthError: Error {
    case sessionMissing
}

/// Attributes that can be updated on the current user.
public struct UserAttributes: Sendable {
    public var email: String?
    public var phone: String?
    public var password: String?

    public init(
        email: String? = nil,
        phone: String? = nil,
        password: String? = nil
    ) {
        self.email = email
        self.phone = phone
        self.password = password
    }
}

public enum SignOutScope: String, Sendable {
    /// All sessions by this account will be signed out.
    case global
    /// Only this session will be signed out.
    case local
    /// All other sessions except the current one will be signed out.
    case others

    var kotlinScope: io.github.jan.supabase.auth.SignOutScope {
        switch self {
        case .global: return io.github.jan.supabase.auth.SignOutScope.GLOBAL
        case .local: return io.github.jan.supabase.auth.SignOutScope.LOCAL
        case .others: return io.github.jan.supabase.auth.SignOutScope.OTHERS
        }
    }
}

public class Session {
    fileprivate let session: io.github.jan.supabase.auth.user.UserSession

    init(session: io.github.jan.supabase.auth.user.UserSession) {
        self.session = session
    }

    public var user: User {
        User(userInfo: session.user!)
    }

    /// The access token (JWT) for the current session.
    public var accessToken: String {
        session.accessToken
    }

    /// The refresh token for renewing the session.
    public var refreshToken: String {
        session.refreshToken
    }

    /// The token type (typically "bearer").
    public var tokenType: String {
        session.tokenType
    }

    /// The number of seconds until the session expires.
    public var expiresIn: Double {
        Double(session.expiresIn)
    }

    /// The epoch timestamp (seconds since 1970) when the session expires.
    public var expiresAt: Double {
        Double(session.expiresAt.epochSeconds)
    }
}

public class User {
    fileprivate let userInfo: io.github.jan.supabase.auth.user.UserInfo

    init(userInfo: io.github.jan.supabase.auth.user.UserInfo) {
        self.userInfo = userInfo
    }

    public var id: UUID { UUID(uuidString: userInfo.id)! }
//    public var appMetadata: [String: AnyJSON]
//    public var userMetadata: [String: AnyJSON]
    public var aud: String { userInfo.aud }
    public var confirmationSentAt: Date? { instant2date(userInfo.confirmationSentAt) }
    public var recoverySentAt: Date? { instant2date(userInfo.recoverySentAt) }
    public var emailChangeSentAt: Date? { instant2date(userInfo.emailChangeSentAt) }
    public var newEmail: String? { userInfo.newEmail }
    public var invitedAt: Date? { instant2date(userInfo.invitedAt) }
    public var actionLink: String? { userInfo.actionLink }
    public var email: String? { userInfo.email }
    public var phone: String? { userInfo.phone }
    public var createdAt: Date { instant2date(userInfo.createdAt)! }
    public var confirmedAt: Date? { instant2date(userInfo.confirmedAt) }
    public var emailConfirmedAt: Date? { instant2date(userInfo.emailConfirmedAt) }
    public var phoneConfirmedAt: Date? { instant2date(userInfo.phoneConfirmedAt) }
    public var lastSignInAt: Date? { instant2date(userInfo.lastSignInAt) }
    public var role: String? { userInfo.role }
    public var updatedAt: Date { instant2date(userInfo.updatedAt)! }
    public var isAnonymous: Bool { userInfo.isAnonymous == true }
//    public var identities: [UserIdentity]?
//    public var factors: [Factor]?

}

#endif
