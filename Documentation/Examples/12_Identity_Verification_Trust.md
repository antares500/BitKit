# 12 - Verificación de Identidad y Sistemas de Confianza

## Descripción

Este ejemplo demuestra cómo implementar un sistema completo de verificación de identidades y gestión de confianza en BitCommunications. Aprenderás a crear y verificar identidades criptográficas, gestionar niveles de confianza, implementar attestations distribuidas, y construir una red de confianza que resista ataques Sybil y mantenga la privacidad.

**Beneficios:**
- Verificación criptográfica de identidades sin autoridad central
- Sistema de confianza distribuido y resistente a la censura
- Attestations verificables que prueban reputación
- Protección contra ataques Sybil mediante pruebas de trabajo
- Privacidad preservada con zero-knowledge proofs
- Recuperación de identidad con forward secrecy
- Integración con servicios externos de verificación

**Consideraciones:**
- Implementa timeouts apropiados para verificaciones
- Considera el costo computacional de pruebas criptográficas
- Maneja apropiadamente el almacenamiento de attestations
- Proporciona indicadores claros de nivel de confianza
- Implementa revocación de confianza cuando es necesario
- Considera el impacto en privacidad de compartir attestations
- Maneja conflictos de identidad y resolución de disputas

## Pasos Previos Obligatorios

1. **Completar Configuración Básica** (Ejemplo 01)
2. **Implementar AdvancedSecurityManager** (Ejemplo 09)
3. **Crear TrustManager** y **IdentityVerifier**
4. **Configurar políticas de confianza y attestations**
5. **Implementar ZeroKnowledgeProver**

## Código de Implementación

```swift
import BitCore
import BitNostr
import CryptoKit
import Security
import Combine

// Manager principal de confianza e identidad
class TrustManager {
    private let identityManager: IdentityManager
    private let attestationManager: AttestationManager
    private let trustEvaluator: TrustEvaluator
    private let sybilProtector: SybilProtectionManager

    // Estado de confianza
    private var trustLevels: [PeerID: TrustLevel] = [:]
    private var attestations: [PeerID: [Attestation]] = [:]
    private var identityProofs: [PeerID: IdentityProof] = [:]

    // Publishers para eventos
    private let trustLevelChangedPublisher = PassthroughSubject<(PeerID, TrustLevel), Never>()
    private let identityVerifiedPublisher = PassthroughSubject<(PeerID, VerificationResult), Never>()
    private let attestationReceivedPublisher = PassthroughSubject<Attestation, Never>()

    var trustLevelChanged: AnyPublisher<(PeerID, TrustLevel), Never> {
        trustLevelChangedPublisher.eraseToAnyPublisher()
    }

    var identityVerified: AnyPublisher<(PeerID, VerificationResult), Never> {
        identityVerifiedPublisher.eraseToAnyPublisher()
    }

    var attestationReceived: AnyPublisher<Attestation, Never> {
        attestationReceivedPublisher.eraseToAnyPublisher()
    }

    init() {
        self.identityManager = IdentityManager()
        self.attestationManager = AttestationManager()
        self.trustEvaluator = TrustEvaluator()
        self.sybilProtector = SybilProtectionManager()

        setupAttestationBindings()
    }

    // MARK: - Gestión de Identidad

    // Crear nueva identidad verificable
    func createVerifiableIdentity(displayName: String, additionalInfo: [String: String] = [:]) async throws -> Identity {
        let identity = try await identityManager.createIdentity(displayName: displayName, additionalInfo: additionalInfo)

        // Generar proof of work para protección Sybil
        let powProof = try await sybilProtector.generateProofOfWork(difficulty: .standard)

        // Crear proof de identidad
        let identityProof = IdentityProof(
            identity: identity,
            proofOfWork: powProof,
            timestamp: Date(),
            signature: try await identityManager.signIdentity(identity)
        )

        identityProofs[identity.peerID] = identityProof

        print("🆔 Identidad verificable creada: \(displayName)")

        return identity
    }

    // Verificar identidad de peer
    func verifyPeerIdentity(_ peerID: PeerID, proof: IdentityProof) async throws -> VerificationResult {
        // Verificar firma de identidad
        let signatureValid = try await identityManager.verifyIdentitySignature(proof)

        guard signatureValid else {
            return .failed(reason: "Firma de identidad inválida")
        }

        // Verificar proof of work
        let powValid = await sybilProtector.verifyProofOfWork(proof.proofOfWork, difficulty: .standard)

        guard powValid else {
            return .failed(reason: "Proof of work insuficiente")
        }

        // Verificar no expirado
        guard proof.timestamp.timeIntervalSinceNow > -TrustPolicy.identityExpirationTime else {
            return .failed(reason: "Proof de identidad expirado")
        }

        // Almacenar proof verificado
        identityProofs[peerID] = proof

        // Evaluar nivel inicial de confianza
        let initialTrust = await trustEvaluator.evaluateInitialTrust(for: peerID, with: proof)

        trustLevels[peerID] = initialTrust
        trustLevelChangedPublisher.send((peerID, initialTrust))

        let result = VerificationResult.success(trustLevel: initialTrust)
        identityVerifiedPublisher.send((peerID, result))

        print("✅ Identidad verificada: \(peerID) - Nivel de confianza: \(initialTrust)")

        return result
    }

    // MARK: - Sistema de Attestations

    // Crear attestation para peer
    func createAttestation(
        for peerID: PeerID,
        type: AttestationType,
        claim: String,
        evidence: Data? = nil,
        confidence: Double = 1.0
    ) async throws -> Attestation {
        let attestation = try await attestationManager.createAttestation(
            subject: peerID,
            type: type,
            claim: claim,
            evidence: evidence,
            confidence: confidence
        )

        // Añadir a attestations locales
        attestations[peerID, default: []].append(attestation)

        // Re-evaluar confianza
        await reevaluateTrust(for: peerID)

        print("📜 Attestation creada para \(peerID): \(type.rawValue)")

        return attestation
    }

    // Verificar attestation recibida
    func verifyAttestation(_ attestation: Attestation) async throws -> Bool {
        let isValid = try await attestationManager.verifyAttestation(attestation)

        if isValid {
            // Almacenar attestation verificada
            attestations[attestation.subject, default: []].append(attestation)
            attestationReceivedPublisher.send(attestation)

            // Re-evaluar confianza del sujeto
            await reevaluateTrust(for: attestation.subject)

            print("✅ Attestation verificada: \(attestation.type.rawValue) para \(attestation.subject)")
        } else {
            print("❌ Attestation inválida: \(attestation.type.rawValue)")
        }

        return isValid
    }

    // Solicitar attestations de confianza
    func requestTrustAttestations(for peerID: PeerID) async throws {
        let request = AttestationRequest(
            subject: peerID,
            requestedTypes: [.identity, .behavior, .reputation],
            requester: getCurrentPeerID()
        )

        try await broadcastAttestationRequest(request)

        print("📤 Solicitud de attestations enviada para \(peerID)")
    }

    // MARK: - Evaluación de Confianza

    // Obtener nivel de confianza para peer
    func getTrustLevel(for peerID: PeerID) -> TrustLevel {
        return trustLevels[peerID] ?? .unknown
    }

    // Re-evaluar confianza para peer
    private func reevaluateTrust(for peerID: PeerID) async {
        let currentAttestations = attestations[peerID] ?? []
        let newTrustLevel = await trustEvaluator.evaluateTrust(peerID, attestations: currentAttestations)

        let oldTrustLevel = trustLevels[peerID]
        if oldTrustLevel != newTrustLevel {
            trustLevels[peerID] = newTrustLevel
            trustLevelChangedPublisher.send((peerID, newTrustLevel))

            print("🔄 Confianza actualizada para \(peerID): \(oldTrustLevel?.description ?? "unknown") → \(newTrustLevel)")
        }
    }

    // Calcular confianza transitiva
    func calculateTransitiveTrust(from source: PeerID, to target: PeerID, maxHops: Int = 3) async -> TrustLevel {
        return await trustEvaluator.calculateTransitiveTrust(from: source, to: target, maxHops: maxHops)
    }

    // MARK: - Zero-Knowledge Proofs

    // Probar conocimiento de identidad sin revelarla
    func proveIdentityKnowledge(challenge: ZKChallenge) async throws -> ZKProof {
        return try await identityManager.generateZKProof(for: challenge)
    }

    // Verificar proof de conocimiento de identidad
    func verifyIdentityKnowledge(_ proof: ZKProof, challenge: ZKChallenge) async throws -> Bool {
        return try await identityManager.verifyZKProof(proof, for: challenge)
    }

    // MARK: - Gestión de Confianza

    // Revocar confianza en peer
    func revokeTrust(for peerID: PeerID, reason: String) async throws {
        // Crear attestation de revocación
        let revocationAttestation = try await createAttestation(
            for: peerID,
            type: .revocation,
            claim: reason,
            confidence: 1.0
        )

        // Reducir nivel de confianza
        trustLevels[peerID] = .distrusted

        trustLevelChangedPublisher.send((peerID, .distrusted))

        print("🚫 Confianza revocada para \(peerID): \(reason)")
    }

    // Reportar comportamiento malicioso
    func reportMaliciousBehavior(peerID: PeerID, evidence: MaliciousBehaviorEvidence) async throws {
        let attestation = try await createAttestation(
            for: peerID,
            type: .malicious,
            claim: evidence.description,
            evidence: try evidence.encoded(),
            confidence: evidence.confidence
        )

        // Penalizar confianza inmediatamente
        trustLevels[peerID] = .distrusted

        print("🚨 Comportamiento malicioso reportado: \(peerID)")
    }

    // MARK: - Integración con Servicios Externos

    // Verificar identidad con servicio externo
    func verifyWithExternalService(peerID: PeerID, service: ExternalVerificationService) async throws -> VerificationResult {
        let result = try await service.verifyIdentity(peerID)

        if case .success = result {
            // Crear attestation basada en verificación externa
            _ = try await createAttestation(
                for: peerID,
                type: .external,
                claim: "Verificado por \(service.name)",
                confidence: 0.8
            )
        }

        return result
    }

    // MARK: - Utilidades

    // Obtener identidad actual
    private func getCurrentPeerID() -> PeerID {
        // En implementación real, obtener del estado de identidad
        return PeerID(str: "current-peer-\(UUID().uuidString.prefix(8))")!
    }

    // Broadcast de solicitud de attestations
    private func broadcastAttestationRequest(_ request: AttestationRequest) async throws {
        // Implementar broadcast a través de transportes disponibles
        print("Broadcasting attestation request...")
    }

    // MARK: - Configuración

    private func setupAttestationBindings() {
        // Configurar recepción de attestations
        // (Se integraría con el sistema de mensajería)
    }
}

// Manager de identidades
class IdentityManager {
    private var identities: [PeerID: Identity] = [:]

    func createIdentity(displayName: String, additionalInfo: [String: String]) async throws -> Identity {
        let keyPair = try await generateKeyPair()
        let peerID = PeerID(data: keyPair.publicKey.rawRepresentation)!

        let identity = Identity(
            peerID: peerID,
            displayName: displayName,
            publicKey: keyPair.publicKey,
            additionalInfo: additionalInfo,
            createdAt: Date()
        )

        identities[peerID] = identity

        return identity
    }

    func signIdentity(_ identity: Identity) async throws -> Data {
        let data = try identity.encoded()
        return try await signData(data, with: identity.peerID)
    }

    func verifyIdentitySignature(_ proof: IdentityProof) async throws -> Bool {
        let data = try proof.identity.encoded()
        return try await verifySignature(proof.signature, for: data, publicKey: proof.identity.publicKey)
    }

    func generateZKProof(for challenge: ZKChallenge) async throws -> ZKProof {
        // Implementar zero-knowledge proof básico
        // En producción, usar una implementación ZK real como Bulletproofs
        let proofData = challenge.data + Data([0x01, 0x02, 0x03]) // Simulación
        return ZKProof(data: proofData)
    }

    func verifyZKProof(_ proof: ZKProof, for challenge: ZKChallenge) async throws -> Bool {
        // Verificar proof ZK básico
        let expectedData = challenge.data + Data([0x01, 0x02, 0x03])
        return proof.data == expectedData
    }

    private func generateKeyPair() async throws -> KeyPair {
        let privateKey = P256.Signing.PrivateKey()
        return KeyPair(privateKey: privateKey, publicKey: privateKey.publicKey)
    }

    private func signData(_ data: Data, with peerID: PeerID) async throws -> Data {
        // Obtener clave privada (en implementación real, del keychain)
        let privateKey = P256.Signing.PrivateKey()
        let signature = try privateKey.signature(for: data)
        return signature.rawRepresentation
    }

    private func verifySignature(_ signature: Data, for data: Data, publicKey: P256.Signing.PublicKey) async throws -> Bool {
        // Verificar firma
        let signature = try P256.Signing.ECDSASignature(rawRepresentation: signature)
        return publicKey.isValidSignature(signature, for: data)
    }
}

// Manager de attestations
class AttestationManager {
    func createAttestation(
        subject: PeerID,
        type: AttestationType,
        claim: String,
        evidence: Data?,
        confidence: Double
    ) async throws -> Attestation {
        let issuer = PeerID(str: "current-issuer-\(UUID().uuidString.prefix(8))")! // Current peer
        let issuerPublicKey = P256.Signing.PublicKey() // En implementación real, obtener del keychain
        let timestamp = Date()

        let attestation = Attestation(
            id: AttestationID(),
            subject: subject,
            issuer: issuer,
            issuerPublicKey: issuerPublicKey,
            type: type,
            claim: claim,
            evidence: evidence,
            confidence: confidence,
            timestamp: timestamp,
            signature: Data() // Se firma después
        )

        // Firmar attestation
        let signature = try await signAttestation(attestation)
        var signedAttestation = attestation
        signedAttestation.signature = signature

        return signedAttestation
    }

    func verifyAttestation(_ attestation: Attestation) async throws -> Bool {
        // Verificar firma
        let signatureValid = try await verifyAttestationSignature(attestation)

        // Verificar no expirada
        let notExpired = attestation.timestamp.timeIntervalSinceNow > -TrustPolicy.attestationExpirationTime

        // Verificar confianza del issuer
        let issuerTrusted = true // Implementar verificación de confianza del issuer

        return signatureValid && notExpired && issuerTrusted
    }

    private func signAttestation(_ attestation: Attestation) async throws -> Data {
        // Firmar attestation con clave privada
        let data = try attestation.encoded()
        let privateKey = P256.Signing.PrivateKey()
        let signature = try privateKey.signature(for: data)
        return signature.rawRepresentation
    }

    private func verifyAttestationSignature(_ attestation: Attestation) async throws -> Bool {
        // Verificar firma de attestation
        let data = try attestation.encoded()
        let signature = try P256.Signing.ECDSASignature(rawRepresentation: attestation.signature)
        return attestation.issuerPublicKey.isValidSignature(signature, for: data)
    }
}

// Evaluador de confianza
class TrustEvaluator {
    func evaluateInitialTrust(for peerID: PeerID, with proof: IdentityProof) async -> TrustLevel {
        // Evaluar basado en proof of work y otros factores
        let powStrength = proof.proofOfWork.difficulty

        switch powStrength {
        case .easy:
            return .minimal
        case .standard:
            return .basic
        case .hard:
            return .trusted
        }
    }

    func evaluateTrust(_ peerID: PeerID, attestations: [Attestation]) async -> TrustLevel {
        var trustScore = 0.0
        var totalWeight = 0.0

        for attestation in attestations {
            let weight = calculateAttestationWeight(attestation)
            let score = calculateAttestationScore(attestation)

            trustScore += score * weight
            totalWeight += weight
        }

        guard totalWeight > 0 else { return .unknown }

        let averageScore = trustScore / totalWeight

        return trustLevelFromScore(averageScore)
    }

    func calculateTransitiveTrust(from source: PeerID, to target: PeerID, maxHops: Int) async -> TrustLevel {
        // Implementar cálculo de confianza transitiva usando BFS
        var visited = Set<PeerID>()
        var queue: [(peer: PeerID, hops: Int, trust: TrustLevel)] = [(source, 0, .trusted)]
        
        while !queue.isEmpty {
            let (currentPeer, hops, currentTrust) = queue.removeFirst()
            
            if currentPeer == target {
                return currentTrust
            }
            
            if hops >= maxHops || visited.contains(currentPeer) {
                continue
            }
            
            visited.insert(currentPeer)
            
            // Obtener conexiones del peer actual (en implementación real, de la red)
            let connections = await getPeerConnections(currentPeer)
            
            for connection in connections {
                if !visited.contains(connection.peer) {
                    let transitiveTrust = min(currentTrust, connection.trust)
                    queue.append((connection.peer, hops + 1, transitiveTrust))
                }
            }
        }
        
        return .unknown
    }

    private func getPeerConnections(_ peerID: PeerID) async -> [(peer: PeerID, trust: TrustLevel)] {
        // En implementación real, obtener conexiones de la red social
        // Aquí devolver conexiones de ejemplo
        return [
            (PeerID(str: "connection-1-\(UUID().uuidString.prefix(8))")!, .trusted),
            (PeerID(str: "connection-2-\(UUID().uuidString.prefix(8))")!, .basic)
        ]
    }

    private func calculateAttestationWeight(_ attestation: Attestation) -> Double {
        // Peso basado en tipo y confianza del issuer
        let typeWeight = attestation.type.weight
        let issuerTrust = 1.0 // Implementar obtención de confianza del issuer
        let agePenalty = calculateAgePenalty(attestation.timestamp)

        return typeWeight * issuerTrust * agePenalty
    }

    private func calculateAttestationScore(_ attestation: Attestation) -> Double {
        switch attestation.type {
        case .identity:
            return 0.8
        case .behavior:
            return attestation.confidence
        case .reputation:
            return attestation.confidence
        case .external:
            return 0.7
        case .malicious:
            return -1.0
        case .revocation:
            return -0.5
        }
    }

    private func calculateAgePenalty(_ timestamp: Date) -> Double {
        let age = -timestamp.timeIntervalSinceNow
        let maxAge = TrustPolicy.attestationExpirationTime

        if age > maxAge {
            return 0.0
        }

        return 1.0 - (age / maxAge) * 0.5 // Penalización gradual
    }

    private func trustLevelFromScore(_ score: Double) -> TrustLevel {
        switch score {
        case ..<0:
            return .distrusted
        case 0..<0.3:
            return .minimal
        case 0.3..<0.6:
            return .basic
        case 0.6..<0.8:
            return .trusted
        case 0.8...:
            return .highlyTrusted
        default:
            return .unknown
        }
    }
}

// Protección contra Sybil
class SybilProtectionManager {
    func generateProofOfWork(difficulty: ProofOfWorkDifficulty) async throws -> ProofOfWork {
        let challenge = Data.random(count: 32)
        var nonce: UInt64 = 0
        let target = difficulty.target

        while true {
            let data = challenge + Data(from: nonce)
            let hash = SHA256.hash(data: data)

            if hash.starts(with: target) {
                return ProofOfWork(challenge: challenge, nonce: nonce, difficulty: difficulty)
            }

            nonce += 1

            // Evitar bucle infinito
            if nonce > UInt64.max / 2 {
                throw SybilError.proofGenerationFailed
            }
        }
    }

    func verifyProofOfWork(_ proof: ProofOfWork, difficulty: ProofOfWorkDifficulty) async -> Bool {
        let data = proof.challenge + Data(from: proof.nonce)
        let hash = SHA256.hash(data: data)

        return hash.starts(with: difficulty.target)
    }
}

// Estructuras de datos
struct Identity {
    let peerID: PeerID
    let displayName: String
    let publicKey: P256.Signing.PublicKey
    let additionalInfo: [String: String]
    let createdAt: Date

    func encoded() throws -> Data {
        // Codificar identidad como JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }
}

struct IdentityProof {
    let identity: Identity
    let proofOfWork: ProofOfWork
    let timestamp: Date
    var signature: Data
}

struct Attestation {
    let id: AttestationID
    let subject: PeerID
    let issuer: PeerID
    let issuerPublicKey: P256.Signing.PublicKey
    let type: AttestationType
    let claim: String
    let evidence: Data?
    let confidence: Double
    let timestamp: Date
    var signature: Data

    func encoded() throws -> Data {
        // Codificar attestation como JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }
}

struct AttestationID: Hashable {
    let uuid: UUID

    init() {
        self.uuid = UUID()
    }
}

enum AttestationType {
    case identity, behavior, reputation, external, malicious, revocation

    var weight: Double {
        switch self {
        case .identity: return 1.0
        case .behavior: return 0.8
        case .reputation: return 0.9
        case .external: return 0.7
        case .malicious: return 1.2
        case .revocation: return 1.1
        }
    }
}

enum TrustLevel: Comparable {
    case unknown, distrusted, minimal, basic, trusted, highlyTrusted

    var description: String {
        switch self {
        case .unknown: return "Desconocido"
        case .distrusted: return "No confiable"
        case .minimal: return "Mínima"
        case .basic: return "Básica"
        case .trusted: return "Confiable"
        case .highlyTrusted: return "Altamente confiable"
        }
    }
}

struct ProofOfWork {
    let challenge: Data
    let nonce: UInt64
    let difficulty: ProofOfWorkDifficulty
}

enum ProofOfWorkDifficulty {
    case easy, standard, hard

    var target: Data {
        switch self {
        case .easy: return Data([0xF0]) // Primer byte < 0xF0
        case .standard: return Data([0x00, 0xF0]) // Primeros 2 bytes < 0x00F0
        case .hard: return Data([0x00, 0x00, 0xF0]) // Primeros 3 bytes < 0x0000F0
        }
    }
}

struct ZKChallenge {
    let data: Data
    let parameters: [String: Any]
}

struct ZKProof {
    let data: Data
}

struct AttestationRequest {
    let subject: PeerID
    let requestedTypes: [AttestationType]
    let requester: PeerID
}

struct MaliciousBehaviorEvidence {
    let type: MaliciousBehaviorType
    let description: String
    let timestamp: Date
    let confidence: Double

    func encoded() throws -> Data {
        // Codificar evidencia como JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }
}

enum MaliciousBehaviorType {
    case spam, harassment, fraud, malware
}

enum VerificationResult {
    case success(trustLevel: TrustLevel)
    case failed(reason: String)
    case pending
}

struct TrustPolicy {
    static let identityExpirationTime: TimeInterval = 365 * 24 * 3600 // 1 año
    static let attestationExpirationTime: TimeInterval = 180 * 24 * 3600 // 6 meses
    static let maxTransitiveHops = 3
}

struct KeyPair {
    let privateKey: P256.Signing.PrivateKey
    let publicKey: P256.Signing.PublicKey
}

// Protocolos para servicios externos
protocol ExternalVerificationService {
    var name: String { get }
    func verifyIdentity(_ peerID: PeerID) async throws -> VerificationResult
}

// Errores
enum SybilError: Error {
    case proofGenerationFailed
}

enum TrustError: Error {
    case invalidAttestation
    case identityNotFound
    case verificationFailed
}

// Controlador de UI para confianza
class TrustViewController: UIViewController {
    private let trustManager: TrustManager
    private var cancellables = Set<AnyCancellable>()
    private var peerTrustCells: [PeerID: TrustCell] = [:]

    init(trustManager: TrustManager) {
        self.trustManager = trustManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }

    private func setupUI() {
        // Crear UI para mostrar niveles de confianza
        // Botones para crear attestations
        // Lista de peers con indicadores de confianza
    }

    private func setupBindings() {
        // Observar cambios en niveles de confianza
        trustManager.trustLevelChanged
            .receive(on: DispatchQueue.main)
            .sink { [weak self] peerID, trustLevel in
                self?.updatePeerTrust(peerID, trustLevel: trustLevel)
            }
            .store(in: &cancellables)

        // Observar verificaciones de identidad
        trustManager.identityVerified
            .receive(on: DispatchQueue.main)
            .sink { [weak self] peerID, result in
                self?.handleIdentityVerification(peerID, result: result)
            }
            .store(in: &cancellables)

        // Observar attestations recibidas
        trustManager.attestationReceived
            .receive(on: DispatchQueue.main)
            .sink { [weak self] attestation in
                self?.handleNewAttestation(attestation)
            }
            .store(in: &cancellables)
    }

    @objc func createIdentity() {
        let alert = UIAlertController(title: "Crear Identidad", message: "Ingresa tu nombre", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Nombre"
        }
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Crear", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }

            Task {
                do {
                    _ = try await self?.trustManager.createVerifiableIdentity(displayName: name)
                    self?.showSuccess("Identidad creada exitosamente")
                } catch {
                    self?.showError("Error creando identidad: \(error.localizedDescription)")
                }
            }
        })

        present(alert, animated: true)
    }

    @objc func verifyPeer() {
        // Mostrar lista de peers para verificar
        // Por simplicidad, usar un peer de ejemplo válido
        let peerID = PeerID(str: "verify-peer-\(UUID().uuidString.prefix(8))")!

        Task {
            do {
                // Recibir el proof del peer a través del sistema de mensajería
                // En una implementación real, el proof se recibiría como parte del handshake o mensaje
                guard let receivedProof = await receiveIdentityProofFromPeer(peerID) else {
                    showError("No se recibió proof de identidad del peer")
                    return
                }

                let result = try await trustManager.verifyPeerIdentity(peerID, proof: receivedProof)

                switch result {
                case .success(let trustLevel):
                    showSuccess("Identidad verificada - Confianza: \(trustLevel.description)")
                case .failed(let reason):
                    showError("Verificación fallida: \(reason)")
                case .pending:
                    showSuccess("Verificación en proceso")
                }
            } catch {
                showError("Error verificando identidad: \(error.localizedDescription)")
            }
        }
    }

    @objc func createAttestation() {
        // Mostrar UI para crear attestation
        let peerID = PeerID(str: "attest-peer-\(UUID().uuidString.prefix(8))")!

        Task {
            do {
                _ = try await trustManager.createAttestation(
                    for: peerID,
                    type: .behavior,
                    claim: "Buen comportamiento en chat",
                    confidence: 0.9
                )
                showSuccess("Attestation creada")
            } catch {
                showError("Error creando attestation: \(error.localizedDescription)")
            }
        }
    }

    private func updatePeerTrust(_ peerID: PeerID, trustLevel: TrustLevel) {
        if let cell = peerTrustCells[peerID] {
            cell.updateTrustLevel(trustLevel)
        } else {
            let cell = TrustCell(peerID: peerID, trustLevel: trustLevel)
            peerTrustCells[peerID] = cell
            // Añadir a UI
        }
    }

    private func handleIdentityVerification(_ peerID: PeerID, result: VerificationResult) {
        // Actualizar UI según resultado de verificación
        print("Verificación de identidad para \(peerID): \(result)")
    }

    private func handleNewAttestation(_ attestation: Attestation) {
        // Mostrar notificación de nueva attestation
        print("Nueva attestation recibida: \(attestation.type.rawValue) para \(attestation.subject)")
    }

    private func showSuccess(_ message: String) {
        let alert = UIAlertController(title: "Éxito", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // Función para recibir proof de identidad de un peer (implementación real)
    private func receiveIdentityProofFromPeer(_ peerID: PeerID) async -> IdentityProof? {
        // En una implementación real, esto esperaría un mensaje del peer con el proof
        // Por ejemplo, suscribirse a mensajes de tipo "identity_proof"
        // Aquí simulamos recepción creando un proof de ejemplo
        let identity = Identity(
            peerID: peerID,
            displayName: "Peer Example",
            publicKey: P256.Signing.PublicKey(),
            additionalInfo: [:],
            createdAt: Date()
        )
        
        let proofOfWork = ProofOfWork(challenge: Data([0x01, 0x02]), nonce: 42, difficulty: .standard)
        
        return IdentityProof(
            identity: identity,
            proofOfWork: proofOfWork,
            timestamp: Date(),
            signature: Data()
        )
    }
}

// Celda para mostrar confianza de peer
class TrustCell: UIView {
    private let peerID: PeerID
    private let trustLabel: UILabel
    private let trustIndicator: UIView

    init(peerID: PeerID, trustLevel: TrustLevel) {
        self.peerID = peerID
        self.trustLabel = UILabel()
        self.trustIndicator = UIView()

        super.init(frame: .zero)

        setupUI()
        updateTrustLevel(trustLevel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        // Configurar UI de la celda
        trustLabel.text = "Peer ID: \(peerID.id.prefix(8))..."
        trustIndicator.layer.cornerRadius = 10
    }

    func updateTrustLevel(_ level: TrustLevel) {
        trustLabel.text = "Peer ID: \(peerID.id.prefix(8))... - \(level.description)"

        // Actualizar color del indicador
        switch level {
        case .unknown:
            trustIndicator.backgroundColor = .gray
        case .distrusted:
            trustIndicator.backgroundColor = .red
        case .minimal:
            trustIndicator.backgroundColor = .orange
        case .basic:
            trustIndicator.backgroundColor = .yellow
        case .trusted:
            trustIndicator.backgroundColor = .green
        case .highlyTrusted:
            trustIndicator.backgroundColor = .blue
        }
    }
}
```

## Notas Adicionales

- Implementa timeouts apropiados para verificaciones de identidad
- Considera el costo computacional de generar proofs of work
- Proporciona indicadores visuales claros de nivel de confianza
- Implementa revocación de confianza cuando sea necesario
- Maneja apropiadamente el almacenamiento de attestations
- Considera el impacto en privacidad de compartir attestations
- Implementa verificación de attestations expiradas
- Proporciona opciones para attestations anónimas cuando sea apropiado