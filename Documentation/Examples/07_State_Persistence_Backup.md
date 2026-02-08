# 07 - Gestión de Estado y Persistencia Segura

## Descripción

Este ejemplo muestra cómo implementar un sistema completo de gestión de estado persistente en BitchatCommunications, incluyendo identidades criptográficas, backup/restore, migración entre dispositivos y sincronización de estado. Aprenderás a manejar la persistencia segura de todas las identidades, configuraciones y datos de aplicación de manera que sobreviva reinicios, actualizaciones y cambios de dispositivo.

**Beneficios:**
- Persistencia completa de identidades y configuraciones
- Backup y restore seguros con encriptación
- Migración automática entre dispositivos
- Recuperación de estado tras fallos
- Sincronización inteligente de datos

**Consideraciones:**
- Los datos sensibles requieren encriptación adicional
- La migración entre dispositivos necesita verificación de propiedad
- Los backups pueden ser grandes; considera compresión
- Implementa rotación periódica de claves de encriptación
- Maneja conflictos de sincronización entre dispositivos

## Pasos Previos Obligatorios

1. **Completar Configuración Básica** (Ejemplo 01)
2. **Añadir BitchatState** a las dependencias del proyecto
3. **Implementar SecureIdentityStateManager** con keychain completo
4. **Configurar permisos** para acceso al keychain

## Código de Implementación

```swift
import BitchatCore
import BitchatState
import Security
import Combine

// Manager principal de estado persistente
class PersistentStateManager {
    private let identityManager: SecureIdentityStateManager
    private let keychain: KeychainManagerProtocol
    private let backupManager: BackupManager
    private let migrationManager: MigrationManager

    // Estado en memoria
    private var cachedIdentities: [String: CryptographicIdentity] = [:]
    private var cachedSocialIdentities: [String: SocialIdentity] = [:]
    private var cancellables = Set<AnyCancellable>()

    init(keychain: KeychainManagerProtocol) {
        self.keychain = keychain
        self.identityManager = SecureIdentityStateManager(keychain: keychain)
        self.backupManager = BackupManager(keychain: keychain)
        self.migrationManager = MigrationManager(keychain: keychain)

        setupStateSynchronization()
    }

    // MARK: - Gestión de Identidades Criptográficas

    // Crear nueva identidad criptográfica
    func createCryptographicIdentity(
        noisePublicKey: Data,
        signingPublicKey: Data? = nil,
        claimedNickname: String? = nil
    ) async throws -> CryptographicIdentity {
        // Generar fingerprint único
        let fingerprint = try generateFingerprint(for: noisePublicKey)

        // Crear identidad
        let identity = CryptographicIdentity(
            fingerprint: fingerprint,
            noisePublicKey: noisePublicKey,
            signingPublicKey: signingPublicKey,
            claimedNickname: claimedNickname,
            firstSeen: Date(),
            lastSeen: Date(),
            trustLevel: .unknown,
            verificationCount: 0
        )

        // Persistir en keychain
        try await identityManager.upsertCryptographicIdentity(
            fingerprint: fingerprint,
            noisePublicKey: noisePublicKey,
            signingPublicKey: signingPublicKey,
            claimedNickname: claimedNickname
        )

        // Cache en memoria
        cachedIdentities[fingerprint] = identity

        print("🔐 Nueva identidad criptográfica creada: \(fingerprint)")
        return identity
    }

    // Obtener identidad por fingerprint
    func getCryptographicIdentity(fingerprint: String) async throws -> CryptographicIdentity? {
        // Buscar en cache primero
        if let cached = cachedIdentities[fingerprint] {
            return cached
        }

        // Buscar en persistencia
        guard let identity = try await identityManager.getCryptographicIdentity(fingerprint: fingerprint) else {
            return nil
        }

        // Cache y retornar
        cachedIdentities[fingerprint] = identity
        return identity
    }

    // Actualizar confianza de identidad
    func updateIdentityTrust(fingerprint: String, newTrustLevel: TrustLevel) async throws {
        try await identityManager.updateIdentityTrust(fingerprint: fingerprint, trustLevel: newTrustLevel)

        // Actualizar cache
        if var identity = cachedIdentities[fingerprint] {
            identity.trustLevel = newTrustLevel
            cachedIdentities[fingerprint] = identity
        }

        print("🔒 Confianza actualizada para \(fingerprint): \(newTrustLevel)")
    }

    // MARK: - Gestión de Identidades Sociales

    // Crear identidad social
    func createSocialIdentity(
        peerID: PeerID,
        displayName: String,
        bio: String? = nil,
        avatarData: Data? = nil
    ) async throws -> SocialIdentity {
        let identity = SocialIdentity(
            peerID: peerID,
            displayName: displayName,
            bio: bio,
            avatarData: avatarData,
            createdAt: Date(),
            lastUpdated: Date(),
            isActive: true
        )

        try await identityManager.saveSocialIdentity(identity)
        cachedSocialIdentities[peerID.id] = identity

        print("👤 Nueva identidad social creada para \(peerID)")
        return identity
    }

    // Obtener identidad social
    func getSocialIdentity(peerID: PeerID) async throws -> SocialIdentity? {
        if let cached = cachedSocialIdentities[peerID.id] {
            return cached
        }

        let identity = try await identityManager.getSocialIdentity(peerID: peerID)
        if let identity = identity {
            cachedSocialIdentities[peerID.id] = identity
        }

        return identity
    }

    // MARK: - Gestión de Estado de Aplicación

    // Guardar configuración de aplicación
    func saveAppConfiguration(_ config: AppConfiguration) async throws {
        let data = try JSONEncoder().encode(config)
        let encryptedData = try await encryptSensitiveData(data)

        try keychain.save(
            key: "app_config",
            data: encryptedData,
            service: "bitchat.app"
        )

        print("⚙️ Configuración de aplicación guardada")
    }

    // Cargar configuración de aplicación
    func loadAppConfiguration() async throws -> AppConfiguration? {
        guard let encryptedData = try keychain.load(key: "app_config", service: "bitchat.app") else {
            return nil
        }

        let data = try await decryptSensitiveData(encryptedData)
        let config = try JSONDecoder().decode(AppConfiguration.self, from: data)

        print("⚙️ Configuración de aplicación cargada")
        return config
    }

    // MARK: - Backup y Restore

    // Crear backup completo
    func createFullBackup() async throws -> BackupData {
        let identities = try await identityManager.exportAllIdentities()
        let config = try await loadAppConfiguration()
        let timestamp = Date()

        let backup = BackupData(
            identities: identities,
            configuration: config,
            timestamp: timestamp,
            version: currentBackupVersion
        )

        print("💾 Backup completo creado con \(identities.count) identidades")
        return backup
    }

    // Restaurar desde backup
    func restoreFromBackup(_ backup: BackupData) async throws {
        // Verificar versión de backup
        guard backup.version <= currentBackupVersion else {
            throw StateError.backupVersionTooNew
        }

        // Restaurar identidades
        try await identityManager.importIdentities(backup.identities)

        // Restaurar configuración
        if let config = backup.configuration {
            try await saveAppConfiguration(config)
        }

        // Limpiar cache
        cachedIdentities.removeAll()
        cachedSocialIdentities.removeAll()

        print("🔄 Restauración completada desde backup de \(backup.timestamp)")
    }

    // MARK: - Migración entre Dispositivos

    // Exportar datos para migración
    func exportForMigration() async throws -> MigrationData {
        let identities = try await identityManager.exportAllIdentities()
        let config = try await loadAppConfiguration()

        let migrationData = MigrationData(
            identities: identities,
            configuration: config,
            deviceId: try getCurrentDeviceId(),
            timestamp: Date()
        )

        print("📤 Datos exportados para migración")
        return migrationData
    }

    // Importar datos de migración
    func importMigrationData(_ migrationData: MigrationData) async throws {
        // Verificar que no es del mismo dispositivo
        let currentDeviceId = try getCurrentDeviceId()
        guard migrationData.deviceId != currentDeviceId else {
            throw StateError.migrationFromSameDevice
        }

        // Verificar timestamp (datos no demasiado antiguos)
        let maxAge: TimeInterval = 7 * 24 * 3600 // 7 días
        guard Date().timeIntervalSince(migrationData.timestamp) < maxAge else {
            throw StateError.migrationDataTooOld
        }

        // Importar datos
        try await identityManager.importIdentities(migrationData.identities)

        if let config = migrationData.configuration {
            try await saveAppConfiguration(config)
        }

        print("📥 Migración completada desde dispositivo \(migrationData.deviceId)")
    }

    // MARK: - Sincronización de Estado

    // Configurar sincronización entre dispositivos
    private func setupStateSynchronization() {
        // Suscribirse a cambios en identidades
        identityManager.identityChanges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] change in
                self?.handleIdentityChange(change)
            }
            .store(in: &cancellables)

        // Configurar sincronización automática
        setupAutoSync()
    }

    // Manejar cambios en identidades
    private func handleIdentityChange(_ change: IdentityChange) {
        switch change.type {
        case .added, .updated:
            // Invalidar cache
            cachedIdentities.removeValue(forKey: change.fingerprint)
            cachedSocialIdentities.removeValue(forKey: change.peerID?.id ?? "")

        case .removed:
            cachedIdentities.removeValue(forKey: change.fingerprint)
            cachedSocialIdentities.removeValue(forKey: change.peerID?.id ?? "")
        }

        print("🔄 Cambio de identidad procesado: \(change.type) - \(change.fingerprint)")
    }

    // Configurar sincronización automática
    private func setupAutoSync() {
        // Sincronizar cada hora
        Timer.publish(every: 3600, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    try? await self?.performAutoSync()
                }
            }
            .store(in: &cancellables)
    }

    // Realizar sincronización automática
    private func performAutoSync() async throws {
        // Sincronizar identidades críticas
        try await identityManager.syncCriticalIdentities()

        // Verificar integridad de datos
        try await verifyDataIntegrity()

        print("🔄 Sincronización automática completada")
    }

    // MARK: - Utilidades de Seguridad

    // Generar fingerprint para clave pública
    private func generateFingerprint(for publicKey: Data) throws -> String {
        let hash = SHA256.hash(data: publicKey)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    // Encriptar datos sensibles
    private func encryptSensitiveData(_ data: Data) async throws -> Data {
        // Usar clave derivada del keychain
        let key = try await deriveEncryptionKey()
        return try AES.GCM.seal(data, using: key).combined!
    }

    // Desencriptar datos sensibles
    private func decryptSensitiveData(_ encryptedData: Data) async throws -> Data {
        let key = try await deriveEncryptionKey()
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }

    // Derivar clave de encriptación
    private func deriveEncryptionKey() async throws -> SymmetricKey {
        // Usar una clave maestra del keychain
        guard let masterKeyData = try keychain.load(key: "master_key", service: "bitchat.crypto") else {
            // Generar nueva clave maestra
            let newKey = SymmetricKey(size: .bits256)
            let keyData = newKey.withUnsafeBytes { Data($0) }
            try keychain.save(key: "master_key", data: keyData, service: "bitchat.crypto")
            return newKey
        }

        return SymmetricKey(data: masterKeyData)
    }

    // Obtener ID único del dispositivo
    private func getCurrentDeviceId() throws -> String {
        // Usar identifierForVendor como ID de dispositivo
        guard let deviceId = UIDevice.current.identifierForVendor?.uuidString else {
            throw StateError.deviceIdUnavailable
        }
        return deviceId
    }

    // Verificar integridad de datos
    private func verifyDataIntegrity() async throws {
        // Verificar que las identidades críticas existen
        let criticalIdentities = try await identityManager.getCriticalIdentities()

        for identity in criticalIdentities {
            guard try await identityManager.verifyIdentityIntegrity(identity) else {
                print("⚠️ Integridad comprometida para identidad: \(identity.fingerprint)")
                // Intentar reparar o alertar
            }
        }
    }
}

// Estructuras de datos
struct AppConfiguration: Codable {
    var theme: String = "system"
    var notificationsEnabled: Bool = true
    var autoBackupEnabled: Bool = true
    var maxCacheSize: Int = 100 // MB
    var preferredTransport: String = "ble"
    var privacyLevel: String = "balanced"
}

struct BackupData: Codable {
    let identities: [ExportedIdentity]
    let configuration: AppConfiguration?
    let timestamp: Date
    let version: Int
}

struct MigrationData: Codable {
    let identities: [ExportedIdentity]
    let configuration: AppConfiguration?
    let deviceId: String
    let timestamp: Date
}

struct ExportedIdentity: Codable {
    let type: IdentityType
    let data: Data // Encriptado
}

enum IdentityType {
    case cryptographic, social, ephemeral
}

enum TrustLevel: String, Codable {
    case unknown, verified, trusted, blocked
}

struct IdentityChange {
    let type: ChangeType
    let fingerprint: String
    let peerID: PeerID?
}

enum ChangeType {
    case added, updated, removed
}

// Managers de soporte
class BackupManager {
    private let keychain: KeychainManagerProtocol

    init(keychain: KeychainManagerProtocol) {
        self.keychain = keychain
    }

    func createEncryptedBackup(_ data: BackupData) async throws -> Data {
        let jsonData = try JSONEncoder().encode(data)
        // Encriptar con clave adicional
        return jsonData // Placeholder
    }

    func decryptBackup(_ encryptedData: Data) async throws -> BackupData {
        // Desencriptar y decodificar
        return try JSONDecoder().decode(BackupData.self, from: encryptedData)
    }
}

class MigrationManager {
    private let keychain: KeychainManagerProtocol

    init(keychain: KeychainManagerProtocol) {
        self.keychain = keychain
    }

    func validateMigrationData(_ data: MigrationData) -> Bool {
        // Validar integridad y frescura
        return true // Placeholder
    }

    func performMigration(_ data: MigrationData) async throws {
        // Ejecutar migración paso a paso
        print("Migrating data from device: \(data.deviceId)")
    }
}

// Errores de estado
enum StateError: Error {
    case backupVersionTooNew
    case migrationFromSameDevice
    case migrationDataTooOld
    case deviceIdUnavailable
    case dataIntegrityViolation
    case encryptionFailed
}

// Controlador de UI para gestión de estado
class StateManagementViewController: UIViewController {
    private let stateManager: PersistentStateManager

    init(stateManager: PersistentStateManager) {
        self.stateManager = stateManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // UI para crear backup
    @objc func createBackupTapped() {
        Task {
            do {
                let backup = try await stateManager.createFullBackup()

                // Mostrar opciones para guardar backup
                showBackupOptions(backup)
            } catch {
                showError("Error creando backup: \(error.localizedDescription)")
            }
        }
    }

    // UI para restaurar backup
    @objc func restoreBackupTapped() {
        // Mostrar selector de archivo
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        picker.delegate = self
        present(picker, animated: true)
    }

    // UI para migración
    @objc func migrateDataTapped() {
        Task {
            do {
                let migrationData = try await stateManager.exportForMigration()

                // Compartir datos de migración
                shareMigrationData(migrationData)
            } catch {
                showError("Error exportando datos: \(error.localizedDescription)")
            }
        }
    }

    private func showBackupOptions(_ backup: BackupData) {
        // Mostrar diálogo con opciones de guardado
        let alert = UIAlertController(title: "Backup Creado", message: "Backup creado exitosamente", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func shareMigrationData(_ data: MigrationData) {
        // Compartir datos via AirDrop o QR
        print("Sharing migration data...")
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// Extensión para UIDocumentPickerViewController
extension StateManagementViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        Task {
            do {
                let data = try Data(contentsOf: url)
                let backup = try await BackupManager(keychain: KeychainManager()).decryptBackup(data)
                try await stateManager.restoreFromBackup(backup)

                showSuccess("Backup restaurado exitosamente")
            } catch {
                showError("Error restaurando backup: \(error.localizedDescription)")
            }
        }
    }

    private func showSuccess(_ message: String) {
        let alert = UIAlertController(title: "Éxito", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
```

## Notas Adicionales

- Implementa rotación periódica de claves de encriptación
- Considera particionamiento de datos para backups más pequeños
- Implementa verificación de integridad con hashes
- Maneja conflictos de sincronización entre dispositivos
- Proporciona feedback visual durante operaciones largas
- Considera compresión para reducir tamaño de backups