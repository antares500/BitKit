//
// SecurityConfig.swift
// bitchatKit
//
// Centralized security configuration for BitchatKit
// All security-related limits and parameters with configurable defaults
//

import Foundation

/// Configura todos los parámetros de seguridad del sistema
public class SecurityConfig {
    /// Singleton compartido con configuración por defecto
    public static var shared = SecurityConfig()
    
    // MARK: - Signature Verification
    
    /// Habilita la verificación de firmas digitales en paquetes recibidos
    /// - Default: true (recomendado para producción)
    public var enableSignatureVerification: Bool = true
    
    /// Requiere que todos los paquetes tengan firma válida (rechaza si no)
    /// - Default: false (permite paquetes sin firma para compatibilidad)
    public var requireSignatures: Bool = false
    
    // MARK: - Rate Limiting & DoS Protection
    
    /// Límite de paquetes por segundo por peer
    /// - Default: 10.0 paquetes/s
    /// - Rango recomendado: 5.0 - 50.0
    public var rateLimitPacketsPerSecond: Double = 10.0
    
    /// Ventana de tiempo para rate limiting (segundos)
    /// - Default: 1.0 segundo
    public var rateLimitWindowSeconds: TimeInterval = 1.0
    
    /// Máximo número de paquetes pendientes por peer antes de bloquear
    /// - Default: 100
    public var maxPendingPacketsPerPeer: Int = 100
    
    /// Timeout para bloqueo de peers que exceden rate limit (segundos)
    /// - Default: 60.0 (1 minuto)
    public var rateLimitBanTimeoutSeconds: TimeInterval = 60.0
    
    // MARK: - Timestamp Validation
    
    /// Tolerancia para timestamps futuros (previene manipulación de tiempo)
    /// - Default: 300.0 (5 minutos)
    /// - Rango recomendado: 60.0 - 600.0
    public var timestampToleranceSeconds: TimeInterval = 300.0
    
    /// Máxima edad de mensajes aceptados (segundos)
    /// - Default: 900.0 (15 minutos)
    public var maxMessageAgeSeconds: TimeInterval = 900.0
    
    /// Habilita sincronización de tiempo con peers confiables
    /// - Default: false
    public var enableTimeSynchronization: Bool = false
    
    // MARK: - Content Validation
    
    /// Habilita validación de contenido de paquetes
    /// - Default: true
    public var enableContentValidation: Bool = true
    
    /// Máximo tamaño de payload permitido (bytes)
    /// - Default: 1_048_576 (1 MB)
    /// - Rango recomendado: 1024 - 10_485_760
    public var maxPayloadSizeBytes: Int = 1_048_576
    
    /// Máximo número de fragmentos por transferencia
    /// - Default: 1000
    public var maxFragmentsPerTransfer: Int = 1000
    
    /// Lista de patrones de bytes prohibidos en payloads
    /// Puede usar para detectar malware conocido
    public var forbiddenPayloadPatterns: [Data] = []
    
    /// Habilita escaneo profundo de payloads (más lento pero más seguro)
    /// - Default: false
    public var enableDeepPayloadScan: Bool = false
    
    // MARK: - PeerID Validation
    
    /// Habilita verificación estricta de PeerID
    /// - Default: true
    public var enablePeerIDValidation: Bool = true
    
    /// Requiere que PeerID esté vinculado a clave pública verificada
    /// - Default: false (puede causar incompatibilidades)
    public var requireVerifiedPeerID: Bool = false
    
    /// Lista blanca de peers confiables (vacía = todos permitidos)
    public var trustedPeers: Set<String> = []
    
    /// Lista negra de peers bloqueados
    public var blockedPeers: Set<String> = []
    
    // MARK: - Encryption & Storage
    
    /// Habilita encriptación de paquetes en almacenamiento local
    /// - Default: true (recomendado)
    public var enableLocalEncryption: Bool = true
    
    /// Algoritmo de encriptación para almacenamiento
    /// - Options: "AES256-GCM", "ChaCha20-Poly1305"
    public var localEncryptionAlgorithm: String = "AES256-GCM"
    
    /// Auto-rotación de claves de encriptación (días)
    /// - Default: 30.0 (1 mes)
    /// - 0 = deshabilitado
    public var keyRotationIntervalDays: Double = 30.0
    
    // MARK: - GCS Filter Security
    
    /// Mínimo False Positive Rate permitido para filtros GCS
    /// - Default: 0.0001 (0.01%)
    public var gcsMinTargetFpr: Double = 0.0001
    
    /// Máximo False Positive Rate permitido para filtros GCS
    /// - Default: 0.25 (25%)
    public var gcsMaxTargetFpr: Double = 0.25
    
    /// Máximo número de elementos en filtro GCS
    /// - Default: 10000
    public var gcsMaxElements: Int = 10_000
    
    /// Validación estricta de parámetros GCS
    /// - Default: true
    public var gcsStrictValidation: Bool = true
    
    // MARK: - Gossip Protocol Security
    
    /// Máximo número de saltos (hops) para propagación
    /// - Default: 7
    /// - Rango recomendado: 3 - 10
    public var maxGossipHops: UInt8 = 7
    
    /// Probabilidad de reenvío en gossip (0.0 - 1.0)
    /// - Default: 0.8 (80%)
    public var gossipRelayProbability: Double = 0.8
    
    /// Habilita deduplicación de paquetes
    /// - Default: true
    public var enablePacketDeduplication: Bool = true
    
    /// Capacidad del caché de deduplicación
    /// - Default: 1000
    public var deduplicationCacheSize: Int = 1000
    
    // MARK: - Connection Security
    
    /// Requiere autenticación mutua en conexiones iniciales
    /// - Default: false
    public var requireMutualAuthentication: Bool = false
    
    /// Timeout para handshake de autenticación (segundos)
    /// - Default: 10.0
    public var authenticationTimeoutSeconds: TimeInterval = 10.0
    
    /// Habilita Noise Protocol Framework para encriptación de transporte
    /// - Default: true
    public var enableNoiseEncryption: Bool = true
    
    /// Versión mínima de protocolo aceptada
    /// - Default: 1
    public var minProtocolVersion: UInt8 = 1
    
    // MARK: - Audit & Logging
    
    /// Habilita logging detallado de eventos de seguridad
    /// - Default: true
    public var enableSecurityAuditLog: Bool = true
    
    /// Retención de logs de auditoría (días)
    /// - Default: 90.0
    public var auditLogRetentionDays: Double = 90.0
    
    /// Habilita alertas en tiempo real para eventos críticos
    /// - Default: true
    public var enableSecurityAlerts: Bool = true
    
    // MARK: - Tor Integration Security
    
    /// Habilita protección contra ataques de temporización
    /// - Default: true
    public var enableTimingAttackProtection: Bool = true
    
    /// Añade delay aleatorio a operaciones para prevenir timing attacks (ms)
    /// - Default: 10.0
    /// - Rango: 0 - 100
    public var timingJitterMs: Double = 10.0
    
    // MARK: - Configuration Validation
    
    /// Valida que la configuración actual es segura
    /// - Returns: true si pasa todas las validaciones
    public func validate() -> (isValid: Bool, warnings: [String]) {
        var warnings: [String] = []
        
        // Rate limiting
        if rateLimitPacketsPerSecond < 1.0 {
            warnings.append("⚠️ rateLimitPacketsPerSecond muy bajo: \(rateLimitPacketsPerSecond)")
        }
        if rateLimitPacketsPerSecond > 100.0 {
            warnings.append("⚠️ rateLimitPacketsPerSecond muy alto: \(rateLimitPacketsPerSecond)")
        }
        
        // Timestamp tolerance
        if timestampToleranceSeconds > 600.0 {
            warnings.append("⚠️ timestampToleranceSeconds muy alto: \(timestampToleranceSeconds)s")
        }
        
        // Payload size
        if maxPayloadSizeBytes > 10_485_760 {
            warnings.append("⚠️ maxPayloadSizeBytes muy alto: \(maxPayloadSizeBytes) bytes")
        }
        
        // GCS validation
        if gcsMinTargetFpr >= gcsMaxTargetFpr {
            warnings.append("❌ gcsMinTargetFpr debe ser < gcsMaxTargetFpr")
            return (false, warnings)
        }
        
        // Encryption
        if !enableLocalEncryption && enableSecurityAuditLog {
            warnings.append("⚠️ Encriptación local deshabilitada pero audit log habilitado")
        }
        
        // Signature verification
        if !enableSignatureVerification {
            warnings.append("⚠️ Verificación de firmas deshabilitada - riesgo de seguridad")
        }
        
        return (true, warnings)
    }
    
    // MARK: - Presets
    
    /// Configuración de alta seguridad (para datos sensibles)
    public static func highSecurity() -> SecurityConfig {
        let config = SecurityConfig()
        config.enableSignatureVerification = true
        config.requireSignatures = true
        config.rateLimitPacketsPerSecond = 5.0
        config.timestampToleranceSeconds = 60.0
        config.maxPayloadSizeBytes = 524_288 // 512 KB
        config.enableContentValidation = true
        config.enableDeepPayloadScan = true
        config.requireVerifiedPeerID = true
        config.enableLocalEncryption = true
        config.requireMutualAuthentication = true
        config.enableTimingAttackProtection = true
        config.gcsStrictValidation = true
        config.maxGossipHops = 5
        return config
    }
    
    /// Configuración balanceada (recomendada por defecto)
    public static func balanced() -> SecurityConfig {
        return SecurityConfig() // usa defaults
    }
    
    /// Configuración de bajo overhead (para dispositivos con recursos limitados)
    public static func lowOverhead() -> SecurityConfig {
        let config = SecurityConfig()
        config.enableSignatureVerification = true
        config.requireSignatures = false
        config.rateLimitPacketsPerSecond = 20.0
        config.timestampToleranceSeconds = 300.0
        config.enableContentValidation = false
        config.enableDeepPayloadScan = false
        config.requireVerifiedPeerID = false
        config.enableLocalEncryption = false
        config.requireMutualAuthentication = false
        config.enableTimingAttackProtection = false
        config.gcsStrictValidation = false
        return config
    }
    
    // MARK: - Initializer
    
    public init() {}
}
