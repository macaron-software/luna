import Foundation
import Security

/// KeychainService — stockage sécurisé du PIN via iOS Keychain.
///
/// Le PIN est stocké dans le Keychain avec :
/// - `kSecClassGenericPassword` pour le type
/// - `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` : lisible uniquement
///   quand l'appareil est déverrouillé, non exportable vers iCloud Keychain
/// - Zéro données stockées hors de l'appareil
final class KeychainService {

    static let shared = KeychainService()
    private init() {}

    private let service = "app.luna.pin"
    private let account = "luna_pin_v1"

    // MARK: - Écriture

    /// Stocke le PIN dans le Keychain.
    /// Remplace toute valeur existante (upsert).
    @discardableResult
    func storePin(_ pin: String) -> Bool {
        guard let data = pin.data(using: .utf8) else { return false }

        // Supprimer l'ancienne valeur si présente
        deletePin()

        let query: [CFString: Any] = [
            kSecClass:          kSecClassGenericPassword,
            kSecAttrService:    service,
            kSecAttrAccount:    account,
            kSecValueData:      data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Lecture

    /// Récupère le PIN depuis le Keychain.
    /// Retourne `nil` si absent ou si l'appareil est verrouillé.
    func readPin() -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let pin = String(data: data, encoding: .utf8) else {
            return nil
        }
        return pin
    }

    // MARK: - Suppression

    /// Efface le PIN du Keychain (appelé par panic wipe).
    @discardableResult
    func deletePin() -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Vérification

    /// Vérifie qu'un PIN existe dans le Keychain (vault déjà configuré).
    var hasPIN: Bool { readPin() != nil }
}
