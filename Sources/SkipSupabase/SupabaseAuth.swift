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

#if canImport(UIKit)
import UIKit
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
#elseif canImport(AppKit)
import AppKit
#endif

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

    /// Sign in using an external OAuth provider (Google, GitHub, Apple, etc.).
    /// This is a platform-specific flow and may open a browser or use a native SDK.
    /// The completion handler receives a Session if the sign-in completes immediately, or nil
    /// if the flow requires a redirect or is not available on the current platform.
    public func signInWithOAuth(provider: Provider, redirectTo: String? = nil, scopes: String = "", queryParams: [(name: String, value: String)] = [], completion: @escaping (Session?) -> Void) async throws {
        // SKIP NOWARN
        // Build redirectTo with encoded query params if provided. This avoids depending on
        // platform-specific builder features and keeps query params attached to the redirect URL.
        var redirectToWithParams: String? = nil
        if let redirectTo = redirectTo {
            if queryParams.isEmpty {
                redirectToWithParams = redirectTo
            } else {
                let encodedPairs = queryParams.compactMap { pair -> String? in
                    guard let name = pair.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                          let value = pair.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
                    return "\(name)=\(value)"
                }
                if !encodedPairs.isEmpty {
                    let separator = redirectTo.contains("?") ? "&" : "?"
                    redirectToWithParams = redirectTo + separator + encodedPairs.joined(separator: "&")
                } else {
                    redirectToWithParams = redirectTo
                }
            }
        } else if !queryParams.isEmpty {
            // No redirectTo provided but query params exist — platform-specific flows may require a redirect URL.
            // For now leave redirectToWithParams nil and document TODO for platform wiring.
            // TODO: Consider constructing a default redirect URL or surface an error to the caller.
            redirectToWithParams = nil
        }

        func applyBuilder(_ builder: @escaping () -> Void) async throws {
            try await builder()
        }

        switch provider {
        case .google:
            try await auth.signInWith(io.github.jan.supabase.auth.providers.builtin.Google) {
                if let r = redirectToWithParams { self.redirectTo = r }
                if !scopes.isEmpty { self.scopes = scopes }
            }
        case .github:
            try await auth.signInWith(io.github.jan.supabase.auth.providers.builtin.GitHub) {
                if let r = redirectToWithParams { self.redirectTo = r }
                if !scopes.isEmpty { self.scopes = scopes }
            }
        case .apple:
            try await auth.signInWith(io.github.jan.supabase.auth.providers.builtin.Apple) {
                if let r = redirectToWithParams { self.redirectTo = r }
                if !scopes.isEmpty { self.scopes = scopes }
            }
        case .gitlab:
            try await auth.signInWith(io.github.jan.supabase.auth.providers.builtin.GitLab) {
                if let r = redirectToWithParams { self.redirectTo = r }
                if !scopes.isEmpty { self.scopes = scopes }
            }
        case .bitbucket:
            try await auth.signInWith(io.github.jan.supabase.auth.providers.builtin.Bitbucket) {
                if let r = redirectToWithParams { self.redirectTo = r }
                if !scopes.isEmpty { self.scopes = scopes }
            }
        }

        // If a session was created synchronously, return it; otherwise attempt to open
        // the redirect URL in the system browser when available and indicate the flow
        // requires a redirect by returning nil in the completion.
        if let s = auth.currentSessionOrNull() {
            completion(Session(session: s))
        } else {
            if let redirect = redirectToWithParams {
                openURL(redirect)
            }
            completion(nil)
        }
    }

    // Open a URL in the system browser or via the platform's APIs. This is best-effort
    // and intended for use when an OAuth provider flow requires a redirect.
    fileprivate func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        #if canImport(AuthenticationServices) && canImport(UIKit)
        // Prefer ASWebAuthenticationSession on iOS for OAuth flows.
        importAuthenticationSessionIfNeeded(url)
        #elseif canImport(UIKit)
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        #elseif canImport(AppKit)
        NSWorkspace.shared.open(url)
        #else
        // Fallback: print the URL so calling apps can handle it.
        print("Open URL: \(url.absoluteString)")
        #endif
    }

    #if canImport(AuthenticationServices) && canImport(UIKit)
    // Use ASWebAuthenticationSession to open URL and allow the system to handle callback.
    private func importAuthenticationSessionIfNeeded(_ url: URL) {
        DispatchQueue.main.async {
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: nil) { callbackURL, error in
                // No-op: the flow will be handled by the Supabase SDK or by the app's URL handler.
                if let err = error {
                    // don't crash in test
                    print("ASWebAuthenticationSession error: \(err)")
                }
            }
            session.presentationContextProvider = WebAuthPresentationContextProvider.shared
            session.start()
        }
    }

    // Presentation context provider for ASWebAuthenticationSession. Keep a shared instance so it
    // lives for the duration of the session.
    private class WebAuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
        static let shared = WebAuthPresentationContextProvider()

        func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            // Prefer window from connected scenes (iOS 13+), fall back to key window.
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                if let window = scene.windows.first(where: { $0.isKeyWindow }) {
                    return window
                }
                return scene.windows.first ?? UIWindow()
            }

            if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                return window
            }

            return UIWindow()
        }
    }
    #endif

    /// Construct the standard Supabase authorize URL for a provider and open it in the platform browser.
    /// This is a best-effort native helper for platforms where the SDK doesn't provide a native flow.
    public func signInWithOAuthNative(supabaseURL: URL, provider: Provider, redirectTo: String?, scopes: String = "", queryParams: [(name: String, value: String)] = []) {
        var components = URLComponents(url: supabaseURL, resolvingAgainstBaseURL: false)
        // Supabase authorize path is typically /auth/v1/authorize
        components?.path = (components?.path ?? "") + "/auth/v1/authorize"

        var items: [URLQueryItem] = [URLQueryItem(name: "provider", value: provider.rawValue)]
        if let redirectTo = redirectTo { items.append(URLQueryItem(name: "redirect_to", value: redirectTo)) }
        if !scopes.isEmpty { items.append(URLQueryItem(name: "scopes", value: scopes)) }
        for p in queryParams { items.append(URLQueryItem(name: p.name, value: p.value)) }
        components?.queryItems = items

        if let url = components?.url {
            openURL(url.absoluteString)
        }
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

/// OAuth providers that can be used with signInWithOAuth. Add providers as needed.
public enum Provider: String, Sendable {
    case google
    case github
    case apple
    case gitlab
    case bitbucket
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
    // SKIP INSERT: @OptIn(kotlin.time.ExperimentalTime::class)
    public var expiresAt: Double {
        Double(session.expiresAt.epochSeconds)
    }
}

// SKIP INSERT: @OptIn(kotlin.time.ExperimentalTime::class)
public class User {
    fileprivate let userInfo: io.github.jan.supabase.auth.user.UserInfo

    init(userInfo: io.github.jan.supabase.auth.user.UserInfo) {
        self.userInfo = userInfo
    }

    public var id: UUID { UUID(uuidString: userInfo.id)! }
    public var appMetadata: [String: AnyJSON] { jsonObject2Dict(userInfo.appMetadata) ?? [:] }
    public var userMetadata: [String: AnyJSON] { jsonObject2Dict(userInfo.userMetadata) ?? [:] }
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
