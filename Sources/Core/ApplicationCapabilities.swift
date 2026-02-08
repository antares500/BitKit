//
//  ApplicationCapabilities.swift
//  BitchatCommunications
//
//  Sistema de capacidades de aplicaciones para identificar features soportadas
//

import Foundation

/// Capacidades que puede tener una aplicación en la red Bitchat
public struct ApplicationCapabilities: OptionSet, Codable {
    public let rawValue: UInt64

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    // MARK: - Capacidades de Mensajería

    /// Soporte básico para mensajes de texto
    public static let textMessaging = ApplicationCapabilities(rawValue: 1 << 0)

    /// Soporte para mensajes multimedia (imágenes, videos)
    public static let multimediaMessaging = ApplicationCapabilities(rawValue: 1 << 1)

    /// Soporte para mensajes de voz
    public static let voiceMessaging = ApplicationCapabilities(rawValue: 1 << 2)

    /// Soporte para transferencias de archivos
    public static let fileTransfer = ApplicationCapabilities(rawValue: 1 << 3)

    // MARK: - Capacidades de Grupo

    /// Soporte para chats grupales
    public static let groupChat = ApplicationCapabilities(rawValue: 1 << 4)

    /// Moderación de grupos
    public static let groupModeration = ApplicationCapabilities(rawValue: 1 << 5)

    /// Grupos privados con invitación
    public static let privateGroups = ApplicationCapabilities(rawValue: 1 << 6)

    // MARK: - Capacidades de Seguridad

    /// Encriptación end-to-end
    public static let endToEndEncryption = ApplicationCapabilities(rawValue: 1 << 7)

    /// Verificación de identidad
    public static let identityVerification = ApplicationCapabilities(rawValue: 1 << 8)

    /// Sistema de confianza distribuido
    public static let trustSystem = ApplicationCapabilities(rawValue: 1 << 9)

    /// Auditorías de seguridad
    public static let securityAudits = ApplicationCapabilities(rawValue: 1 << 10)

    // MARK: - Capacidades de Red

    /// Soporte para Bluetooth LE mesh
    public static let bluetoothMesh = ApplicationCapabilities(rawValue: 1 << 11)

    /// Soporte para Nostr protocol
    public static let nostrProtocol = ApplicationCapabilities(rawValue: 1 << 12)

    /// Soporte para Tor (anonimato)
    public static let torSupport = ApplicationCapabilities(rawValue: 1 << 13)

    /// Geolocalización y mensajería local
    public static let geolocation = ApplicationCapabilities(rawValue: 1 << 14)

    // MARK: - Capacidades Avanzadas

    /// Analytics de comunidad
    public static let communityAnalytics = ApplicationCapabilities(rawValue: 1 << 15)

    /// Sincronización de estado
    public static let stateSync = ApplicationCapabilities(rawValue: 1 << 16)

    /// Mensajería offline-first
    public static let offlineMessaging = ApplicationCapabilities(rawValue: 1 << 17)

    /// Interfaz moderna (SwiftUI)
    public static let modernUI = ApplicationCapabilities(rawValue: 1 << 18)

    // MARK: - Presets Comunes

    /// Capacidades mínimas para una aplicación básica de mensajería
    public static let basicMessaging: ApplicationCapabilities = [
        .textMessaging,
        .endToEndEncryption,
        .bluetoothMesh
    ]

    /// Capacidades completas para una aplicación full-featured
    public static let fullFeatured: ApplicationCapabilities = [
        .textMessaging,
        .multimediaMessaging,
        .voiceMessaging,
        .fileTransfer,
        .groupChat,
        .groupModeration,
        .privateGroups,
        .endToEndEncryption,
        .identityVerification,
        .trustSystem,
        .securityAudits,
        .bluetoothMesh,
        .nostrProtocol,
        .torSupport,
        .geolocation,
        .communityAnalytics,
        .stateSync,
        .offlineMessaging,
        .modernUI
    ]

    /// Capacidades para aplicaciones especializadas en anonimato
    public static let anonymousMessaging: ApplicationCapabilities = [
        .textMessaging,
        .endToEndEncryption,
        .torSupport,
        .bluetoothMesh,
        .offlineMessaging
    ]

    /// Lista de todas las capacidades disponibles
    public static let allCapabilities: [ApplicationCapabilities] = [
        .textMessaging, .multimediaMessaging, .voiceMessaging, .fileTransfer,
        .groupChat, .groupModeration, .privateGroups,
        .endToEndEncryption, .identityVerification, .trustSystem, .securityAudits,
        .bluetoothMesh, .nostrProtocol, .torSupport, .geolocation,
        .communityAnalytics, .stateSync, .offlineMessaging, .modernUI
    ]

    /// Nombre descriptivo de la capacidad
    public var displayName: String {
        switch self {
        case .textMessaging: return "Mensajería de Texto"
        case .multimediaMessaging: return "Mensajes Multimedia"
        case .voiceMessaging: return "Mensajes de Voz"
        case .fileTransfer: return "Transferencia de Archivos"
        case .groupChat: return "Chat Grupal"
        case .groupModeration: return "Moderación de Grupos"
        case .privateGroups: return "Grupos Privados"
        case .endToEndEncryption: return "Encriptación E2E"
        case .identityVerification: return "Verificación de Identidad"
        case .trustSystem: return "Sistema de Confianza"
        case .securityAudits: return "Auditorías de Seguridad"
        case .bluetoothMesh: return "Red Bluetooth Mesh"
        case .nostrProtocol: return "Protocolo Nostr"
        case .torSupport: return "Soporte Tor"
        case .geolocation: return "Geolocalización"
        case .communityAnalytics: return "Analytics de Comunidad"
        case .stateSync: return "Sincronización de Estado"
        case .offlineMessaging: return "Mensajería Offline"
        case .modernUI: return "Interfaz Moderna"
        default: return "Capacidad Desconocida"
        }
    }

    /// Descripción detallada de la capacidad
    public var description: String {
        switch self {
        case .textMessaging:
            return "Permite enviar y recibir mensajes de texto básicos"
        case .multimediaMessaging:
            return "Soporte para compartir imágenes, videos y otros medios"
        case .voiceMessaging:
            return "Grabación y envío de mensajes de voz"
        case .fileTransfer:
            return "Transferencia segura de archivos de cualquier tipo"
        case .groupChat:
            return "Conversaciones con múltiples participantes"
        case .groupModeration:
            return "Herramientas para moderar grupos y gestionar miembros"
        case .privateGroups:
            return "Grupos que requieren invitación para unirse"
        case .endToEndEncryption:
            return "Encriptación de extremo a extremo para todos los mensajes"
        case .identityVerification:
            return "Verificación criptográfica de identidades de usuarios"
        case .trustSystem:
            return "Sistema distribuido de attestaciones y confianza"
        case .securityAudits:
            return "Auditorías automáticas de seguridad y privacidad"
        case .bluetoothMesh:
            return "Red mesh usando Bluetooth Low Energy"
        case .nostrProtocol:
            return "Integración con el protocolo Nostr"
        case .torSupport:
            return "Enrutamiento anónimo a través de la red Tor"
        case .geolocation:
            return "Mensajería basada en ubicación y descubrimiento local"
        case .communityAnalytics:
            return "Estadísticas y análisis de la comunidad"
        case .stateSync:
            return "Sincronización automática del estado entre dispositivos"
        case .offlineMessaging:
            return "Mensajería que funciona sin conexión a internet"
        case .modernUI:
            return "Interfaz de usuario moderna y accesible"
        default:
            return "Capacidad no documentada"
        }
    }

    /// Categoría de la capacidad
    public var category: CapabilityCategory {
        switch self {
        case .textMessaging, .multimediaMessaging, .voiceMessaging, .fileTransfer:
            return .messaging
        case .groupChat, .groupModeration, .privateGroups:
            return .groups
        case .endToEndEncryption, .identityVerification, .trustSystem, .securityAudits:
            return .security
        case .bluetoothMesh, .nostrProtocol, .torSupport, .geolocation:
            return .network
        case .communityAnalytics, .stateSync, .offlineMessaging, .modernUI:
            return .advanced
        default:
            return .other
        }
    }

    /// Categorías de capacidades
    public enum CapabilityCategory {
        case messaging
        case groups
        case security
        case network
        case advanced
        case other

        public var displayName: String {
            switch self {
            case .messaging: return "Mensajería"
            case .groups: return "Grupos"
            case .security: return "Seguridad"
            case .network: return "Red"
            case .advanced: return "Avanzado"
            case .other: return "Otro"
            }
        }
    }

    /// Verificar si tiene una capacidad específica
    public func hasCapability(_ capability: ApplicationCapabilities) -> Bool {
        return self.contains(capability)
    }

    /// Verificar compatibilidad con otra aplicación
    public func isCompatible(with other: ApplicationCapabilities) -> Bool {
        // Al menos debe compartir capacidades básicas de mensajería y seguridad
        let basicCapabilities: ApplicationCapabilities = [.textMessaging, .endToEndEncryption]
        return self.intersection(other).contains(basicCapabilities)
    }

    /// Capacidades faltantes para compatibilidad
    public func missingCapabilities(forCompatibilityWith other: ApplicationCapabilities) -> ApplicationCapabilities {
        let requiredForCompatibility: ApplicationCapabilities = [.textMessaging, .endToEndEncryption]
        let common = self.intersection(other)
        return requiredForCompatibility.subtracting(common)
    }
}

/// Información de aplicación que se transmite en la red
public struct ApplicationInfo: Codable {
    /// Identificador único de la aplicación
    public let appID: String

    /// Nombre de la aplicación
    public let name: String

    /// Versión de la aplicación
    public let version: String

    /// Capacidades soportadas
    public let capabilities: ApplicationCapabilities

    /// Firma criptográfica de la información
    public let signature: Data?

    /// Timestamp de creación
    public let timestamp: Date

    /// Información adicional (opcional)
    public let metadata: [String: String]?

    public init(
        appID: String,
        name: String,
        version: String,
        capabilities: ApplicationCapabilities,
        signature: Data? = nil,
        metadata: [String: String]? = nil
    ) {
        self.appID = appID
        self.name = name
        self.version = version
        self.capabilities = capabilities
        self.signature = signature
        self.timestamp = Date()
        self.metadata = metadata
    }

    /// Verificar si la aplicación es compatible con capacidades requeridas
    public func supports(_ requiredCapabilities: ApplicationCapabilities) -> Bool {
        return capabilities.contains(requiredCapabilities)
    }

    /// Obtener capacidades faltantes
    public func missingCapabilities(_ required: ApplicationCapabilities) -> ApplicationCapabilities {
        return required.subtracting(capabilities)
    }
}

/// Extensiones para trabajar con ApplicationCapabilities
public extension ApplicationCapabilities {
    /// Convertir a array de capacidades individuales
    func toArray() -> [ApplicationCapabilities] {
        return ApplicationCapabilities.allCapabilities.filter { self.contains($0) }
    }

    /// Crear desde array de capacidades
    static func fromArray(_ capabilities: [ApplicationCapabilities]) -> ApplicationCapabilities {
        return capabilities.reduce([]) { $0.union($1) }
    }

    /// Capacidades por categoría
    func capabilitiesByCategory() -> [CapabilityCategory: [ApplicationCapabilities]] {
        let all = toArray()
        var result: [CapabilityCategory: [ApplicationCapabilities]] = [:]

        for capability in all {
            result[capability.category, default: []].append(capability)
        }

        return result
    }
}

/// Protocolo para proveedores de información de aplicación
public protocol ApplicationInfoProvider {
    /// Obtener información de la aplicación actual
    func getApplicationInfo() -> ApplicationInfo

    /// Verificar si una aplicación es compatible
    func isApplicationCompatible(_ appInfo: ApplicationInfo) -> Bool

    /// Obtener capacidades mínimas requeridas
    func getMinimumRequiredCapabilities() -> ApplicationCapabilities
}

/// Implementación por defecto del proveedor de información de aplicación
public class DefaultApplicationInfoProvider: ApplicationInfoProvider {
    private let appID: String
    private let appName: String
    private let appVersion: String
    private let capabilities: ApplicationCapabilities

    public init(
        appID: String,
        appName: String,
        appVersion: String,
        capabilities: ApplicationCapabilities
    ) {
        self.appID = appID
        self.appName = appName
        self.appVersion = appVersion
        self.capabilities = capabilities
    }

    public func getApplicationInfo() -> ApplicationInfo {
        return ApplicationInfo(
            appID: appID,
            name: appName,
            version: appVersion,
            capabilities: capabilities
        )
    }

    public func isApplicationCompatible(_ appInfo: ApplicationInfo) -> Bool {
        return capabilities.isCompatible(with: appInfo.capabilities)
    }

    public func getMinimumRequiredCapabilities() -> ApplicationCapabilities {
        return [.textMessaging, .endToEndEncryption]
    }
}