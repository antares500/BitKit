# 08 - Grupos de Chat y Moderación

## Descripción

Este ejemplo demuestra cómo implementar un sistema completo de grupos de chat con moderación de contenido, roles de usuario, analytics y gestión comunitaria en BitCommunications. Aprenderás a crear comunidades seguras, moderar conversaciones, gestionar permisos y analizar el comportamiento de los grupos para mantener entornos positivos.

**Beneficios:**
- Creación de comunidades temáticas y privadas
- Moderación automática e manual de contenido
- Sistema de roles y permisos granulares
- Analytics para entender el comportamiento de la comunidad
- Moderación distribuida sin puntos centrales de fallo

**Consideraciones:**
- La moderación requiere consenso distribuido
- Los grupos grandes pueden generar mucho tráfico
- Implementa límites para prevenir spam
- Considera el impacto en privacidad de los analytics
- Maneja conflictos entre moderadores
- Los roles deben ser verificables criptográficamente

## Pasos Previos Obligatorios

1. **Completar Configuración Básica** (Ejemplo 01)
2. **Configurar BLE Mesh** (Ejemplo 02)
3. **Añadir BitCommunications** a las dependencias del proyecto
4. **Implementar GroupChatManager** y **ModerationManager**

## Código de Implementación

```swift
import BitCore
import BitCommunications
import BitBLE
import Combine

// Manager principal de grupos
class GroupManager {
    private let groupChatManager: GroupChatManager
    private let moderationManager: ModerationManager
    private let analyticsManager: AnalyticsManager
    private let bleService: BLEService

    // Estado de grupos
    private var activeGroups: [GroupID: Group] = [:]
    private var groupMemberships: [PeerID: Set<GroupID>] = [:]
    private var cancellables = Set<AnyCancellable>()

    init(bleService: BLEService) {
        self.bleService = bleService
        self.groupChatManager = GroupChatManager(transport: bleService)
        self.moderationManager = ModerationManager()
        self.analyticsManager = AnalyticsManager()

        setupGroupEventHandling()
    }

    // MARK: - Creación y Gestión de Grupos

    // Crear nuevo grupo
    func createGroup(
        name: String,
        description: String? = nil,
        isPrivate: Bool = false,
        maxMembers: Int? = nil
    ) async throws -> Group {
        let creator = try getCurrentPeerID()

        let group = Group(
            id: GroupID(),
            name: name,
            description: description,
            creator: creator,
            createdAt: Date(),
            isPrivate: isPrivate,
            maxMembers: maxMembers,
            settings: GroupSettings.default
        )

        // Crear grupo en el manager
        try await groupChatManager.createGroup(group)

        // Añadir creador como admin
        try await addMember(to: group.id, peerID: creator, role: .admin)

        // Registrar grupo activo
        activeGroups[group.id] = group

        print("👥 Grupo creado: \(name) por \(creator)")
        return group
    }

    // Unirse a grupo existente
    func joinGroup(_ groupID: GroupID) async throws {
        let member = try getCurrentPeerID()

        // Verificar que el grupo existe y es accesible
        guard let group = try await groupChatManager.getGroup(groupID) else {
            throw GroupError.groupNotFound
        }

        // Verificar límites de miembros
        if let maxMembers = group.maxMembers,
           try await groupChatManager.getMemberCount(groupID) >= maxMembers {
            throw GroupError.groupFull
        }

        // Unirse al grupo
        try await groupChatManager.joinGroup(groupID, as: member)

        // Añadir a membresías locales
        groupMemberships[member, default: []].insert(groupID)
        activeGroups[groupID] = group

        print("✅ Unido al grupo: \(group.name)")
    }

    // Abandonar grupo
    func leaveGroup(_ groupID: GroupID) async throws {
        let member = try getCurrentPeerID()

        try await groupChatManager.leaveGroup(groupID, member: member)

        // Remover de membresías locales
        groupMemberships[member]?.remove(groupID)
        activeGroups.removeValue(forKey: groupID)

        print("👋 Abandonado grupo: \(groupID)")
    }

    // MARK: - Gestión de Miembros

    // Añadir miembro al grupo
    func addMember(to groupID: GroupID, peerID: PeerID, role: GroupRole = .member) async throws {
        let requester = try getCurrentPeerID()

        // Verificar permisos
        guard try await hasPermission(groupID, peerID: requester, permission: .manageMembers) else {
            throw GroupError.insufficientPermissions
        }

        // Añadir miembro
        try await groupChatManager.addMember(to: groupID, peerID: peerID, role: role)

        // Notificar analytics
        await analyticsManager.trackEvent(.memberAdded(groupID: groupID, peerID: peerID))

        print("👤 Miembro añadido: \(peerID) al grupo \(groupID)")
    }

    // Remover miembro del grupo
    func removeMember(from groupID: GroupID, peerID: PeerID) async throws {
        let requester = try getCurrentPeerID()

        // Verificar permisos
        guard try await hasPermission(groupID, peerID: requester, permission: .manageMembers) else {
            throw GroupError.insufficientPermissions
        }

        // No permitir remover al creador
        if let group = activeGroups[groupID], group.creator == peerID {
            throw GroupError.cannotRemoveCreator
        }

        try await groupChatManager.removeMember(from: groupID, peerID: peerID)

        // Remover de membresías locales
        groupMemberships[peerID]?.remove(groupID)

        // Notificar analytics
        await analyticsManager.trackEvent(.memberRemoved(groupID: groupID, peerID: peerID))

        print("🚫 Miembro removido: \(peerID) del grupo \(groupID)")
    }

    // Cambiar rol de miembro
    func changeMemberRole(in groupID: GroupID, peerID: PeerID, newRole: GroupRole) async throws {
        let requester = try getCurrentPeerID()

        // Verificar permisos (solo admins pueden cambiar roles)
        guard try await hasPermission(groupID, peerID: requester, permission: .manageRoles) else {
            throw GroupError.insufficientPermissions
        }

        // No permitir degradar al creador
        if let group = activeGroups[groupID], group.creator == peerID && newRole != .admin {
            throw GroupError.cannotChangeCreatorRole
        }

        try await groupChatManager.changeMemberRole(in: groupID, peerID: peerID, newRole: newRole)

        print("🔄 Rol cambiado: \(peerID) ahora es \(newRole) en \(groupID)")
    }

    // MARK: - Mensajería Grupal

    // Enviar mensaje al grupo
    func sendGroupMessage(_ content: String, to groupID: GroupID) async throws {
        let sender = try getCurrentPeerID()

        // Verificar membresía
        guard try await groupChatManager.isMember(of: groupID, peerID: sender) else {
            throw GroupError.notAMember
        }

        // Verificar permisos de escritura
        guard try await hasPermission(groupID, peerID: sender, permission: .sendMessages) else {
            throw GroupError.insufficientPermissions
        }

        // Aplicar moderación previa al envío
        let moderatedContent = try await moderationManager.moderateContent(content, in: groupID)

        // Crear mensaje grupal
        let message = GroupMessage(
            id: MessageID(),
            groupID: groupID,
            sender: sender,
            content: moderatedContent,
            timestamp: Date(),
            messageType: .text
        )

        // Enviar mensaje
        try await groupChatManager.sendMessage(message)

        // Registrar en analytics
        await analyticsManager.trackEvent(.messageSent(groupID: groupID, sender: sender))

        print("📤 Mensaje enviado al grupo \(groupID): \(moderatedContent.prefix(50))...")
    }

    // Obtener mensajes del grupo
    func getGroupMessages(_ groupID: GroupID, limit: Int = 50) async throws -> [GroupMessage] {
        let requester = try getCurrentPeerID()

        // Verificar membresía
        guard try await groupChatManager.isMember(of: groupID, peerID: requester) else {
            throw GroupError.notAMember
        }

        return try await groupChatManager.getMessages(for: groupID, limit: limit)
    }

    // MARK: - Moderación

    // Reportar contenido
    func reportContent(messageID: MessageID, in groupID: GroupID, reason: ModerationReason) async throws {
        let reporter = try getCurrentPeerID()

        // Verificar membresía
        guard try await groupChatManager.isMember(of: groupID, peerID: reporter) else {
            throw GroupError.notAMember
        }

        try await moderationManager.reportContent(
            messageID: messageID,
            groupID: groupID,
            reporter: reporter,
            reason: reason
        )

        print("🚨 Contenido reportado: \(messageID) en grupo \(groupID)")
    }

    // Acción de moderación (requiere permisos)
    func moderateContent(messageID: MessageID, in groupID: GroupID, action: ModerationAction) async throws {
        let moderator = try getCurrentPeerID()

        // Verificar permisos de moderación
        guard try await hasPermission(groupID, peerID: moderator, permission: .moderate) else {
            throw GroupError.insufficientPermissions
        }

        try await moderationManager.takeAction(
            on: messageID,
            in: groupID,
            action: action,
            moderator: moderator
        )

        // Registrar en analytics
        await analyticsManager.trackEvent(.moderationAction(
            groupID: groupID,
            moderator: moderator,
            action: action
        ))

        print("⚖️ Acción de moderación: \(action) en mensaje \(messageID)")
    }

    // MARK: - Analytics y Estadísticas

    // Obtener estadísticas del grupo
    func getGroupStats(_ groupID: GroupID) async throws -> GroupStats {
        let requester = try getCurrentPeerID()

        // Verificar permisos (solo admins y moderadores)
        guard try await hasPermission(groupID, peerID: requester, permission: .viewAnalytics) else {
            throw GroupError.insufficientPermissions
        }

        return await analyticsManager.getGroupStats(groupID)
    }

    // Obtener actividad reciente
    func getRecentActivity(_ groupID: GroupID, hours: Int = 24) async throws -> [GroupActivity] {
        let requester = try getCurrentPeerID()

        guard try await hasPermission(groupID, peerID: requester, permission: .viewAnalytics) else {
            throw GroupError.insufficientPermissions
        }

        return await analyticsManager.getRecentActivity(groupID, hours: hours)
    }

    // MARK: - Utilidades

    // Verificar permisos
    private func hasPermission(_ groupID: GroupID, peerID: PeerID, permission: GroupPermission) async throws -> Bool {
        let role = try await groupChatManager.getMemberRole(in: groupID, peerID: peerID)
        return role.permissions.contains(permission)
    }

    // Obtener PeerID actual
    private func getCurrentPeerID() throws -> PeerID {
        // Implementar obtención del PeerID actual
        return PeerID(data: Data([0x01, 0x02, 0x03, 0x04])) // Placeholder
    }

    // Configurar manejo de eventos de grupo
    private func setupGroupEventHandling() {
        // Suscribirse a eventos de grupo
        groupChatManager.groupEvents
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                Task {
                    await self?.handleGroupEvent(event)
                }
            }
            .store(in: &cancellables)

        // Suscribirse a eventos de moderación
        moderationManager.moderationEvents
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                Task {
                    await self?.handleModerationEvent(event)
                }
            }
            .store(in: &cancellables)
    }

    // Manejar eventos de grupo
    private func handleGroupEvent(_ event: GroupEvent) async {
        switch event {
        case .memberJoined(let groupID, let peerID):
            print("👋 \(peerID) se unió al grupo \(groupID)")
            await analyticsManager.trackEvent(.memberJoined(groupID: groupID, peerID: peerID))

        case .memberLeft(let groupID, let peerID):
            print("👋 \(peerID) abandonó el grupo \(groupID)")
            await analyticsManager.trackEvent(.memberLeft(groupID: groupID, peerID: peerID))

        case .messageReceived(let message):
            // Aplicar moderación automática
            if let violation = await moderationManager.checkForViolations(message) {
                // Tomar acción automática si está configurado
                do {
                    try await moderateContent(
                        messageID: message.id,
                        in: message.groupID,
                        action: .autoRemove
                    )
                } catch {
                    print("Error en moderación automática: \(error.localizedDescription)")
                }
            }
        }
    }

    // Manejar eventos de moderación
    private func handleModerationEvent(_ event: ModerationEvent) async {
        switch event {
        case .contentReported(let report):
            print("🚨 Reporte recibido: \(report.messageID) - \(report.reason)")

        case .actionTaken(let action):
            print("⚖️ Acción tomada: \(action.action) en \(action.messageID)")
        }
    }
}

// Estructuras de datos para grupos
struct Group: Identifiable, Codable {
    let id: GroupID
    let name: String
    let description: String?
    let creator: PeerID
    let createdAt: Date
    var isPrivate: Bool
    var maxMembers: Int?
    var settings: GroupSettings
    var isActive: Bool = true
}

struct GroupID: Hashable, Codable, CustomStringConvertible {
    let uuid: UUID

    init() {
        self.uuid = UUID()
    }

    init(uuid: UUID) {
        self.uuid = uuid
    }

    var description: String {
        return uuid.uuidString.prefix(8).description
    }
}

struct GroupSettings: Codable {
    var allowInvites: Bool = true
    var requireApproval: Bool = false
    var autoModerate: Bool = true
    var maxMessageLength: Int = 1000
    var languageFilter: Bool = false

    static let `default` = GroupSettings()
}

enum GroupRole: String, Codable {
    case member, moderator, admin

    var permissions: Set<GroupPermission> {
        switch self {
        case .member:
            return [.sendMessages, .readMessages]
        case .moderator:
            return [.sendMessages, .readMessages, .moderate, .manageMembers, .viewAnalytics]
        case .admin:
            return [.sendMessages, .readMessages, .moderate, .manageMembers, .manageRoles, .viewAnalytics, .deleteGroup]
        }
    }
}

enum GroupPermission {
    case sendMessages, readMessages, moderate, manageMembers, manageRoles, viewAnalytics, deleteGroup
}

struct GroupMessage: Identifiable, Codable {
    let id: MessageID
    let groupID: GroupID
    let sender: PeerID
    let content: String
    let timestamp: Date
    let messageType: MessageType
    var isModerated: Bool = false
    var moderationReason: ModerationReason?
}

struct MessageID: Hashable, Codable {
    let uuid: UUID

    init() {
        self.uuid = UUID()
    }
}

enum MessageType: String, Codable {
    case text, image, audio, file
}

enum ModerationReason: String, Codable {
    case spam, harassment, inappropriate, offTopic, other
}

enum ModerationAction: String, Codable {
    case warn, remove, ban, autoRemove
}

// Estructuras para analytics
struct GroupStats: Codable {
    let memberCount: Int
    let messageCount: Int
    let activeMembers: Int
    let reportsCount: Int
    let averageMessagesPerDay: Double
    let topContributors: [PeerID]
}

struct GroupActivity: Codable {
    let type: ActivityType
    let peerID: PeerID
    let timestamp: Date
    let details: String?
}

enum ActivityType: String, Codable {
    case messageSent, memberJoined, memberLeft, contentReported, moderationAction
}

// Eventos
enum GroupEvent {
    case memberJoined(groupID: GroupID, peerID: PeerID)
    case memberLeft(groupID: GroupID, peerID: PeerID)
    case messageReceived(message: GroupMessage)
    case groupUpdated(group: Group)
}

enum ModerationEvent {
    case contentReported(report: ContentReport)
    case actionTaken(action: ModerationActionTaken)
}

struct ContentReport: Codable {
    let messageID: MessageID
    let groupID: GroupID
    let reporter: PeerID
    let reason: ModerationReason
    let timestamp: Date
}

struct ModerationActionTaken: Codable {
    let messageID: MessageID
    let groupID: GroupID
    let moderator: PeerID
    let action: ModerationAction
    let timestamp: Date
}

// Errores
enum GroupError: Error {
    case groupNotFound
    case groupFull
    case notAMember
    case insufficientPermissions
    case cannotRemoveCreator
    case cannotChangeCreatorRole
    case invalidGroupName
    case groupAlreadyExists
}

// Controlador de UI para grupos
class GroupViewController: UIViewController {
    private let groupManager: GroupManager
    private var currentGroup: Group?
    private var messages: [GroupMessage] = []

    init(groupManager: GroupManager) {
        self.groupManager = groupManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // UI para crear grupo
    @objc func createGroupTapped() {
        let alert = UIAlertController(title: "Crear Grupo", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Nombre del grupo"
        }

        alert.addAction(UIAlertAction(title: "Crear", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            Task {
                try? await self?.createNewGroup(name: name)
            }
        })

        present(alert, animated: true)
    }

    private func createNewGroup(name: String) async throws {
        let group = try await groupManager.createGroup(name: name)
        currentGroup = group
        // Actualizar UI
        print("Grupo creado: \(group.name)")
    }

    // UI para enviar mensaje
    @objc func sendMessageTapped() {
        guard let groupID = currentGroup?.id else { return }

        let alert = UIAlertController(title: "Enviar Mensaje", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Mensaje"
        }

        alert.addAction(UIAlertAction(title: "Enviar", style: .default) { [weak self] _ in
            guard let content = alert.textFields?.first?.text, !content.isEmpty else { return }
            Task {
                try? await self?.groupManager.sendGroupMessage(content, to: groupID)
            }
        })

        present(alert, animated: true)
    }

    // UI para reportar mensaje
    func reportMessage(_ message: GroupMessage) {
        let alert = UIAlertController(title: "Reportar Mensaje", message: "Selecciona el motivo", preferredStyle: .actionSheet)

        for reason in ModerationReason.allCases {
            alert.addAction(UIAlertAction(title: reason.rawValue, style: .default) { [weak self] _ in
                Task {
                    try? await self?.groupManager.reportContent(
                        messageID: message.id,
                        in: message.groupID,
                        reason: reason
                    )
                }
            })
        }

        present(alert, animated: true)
    }
}
```

## Notas Adicionales

- Implementa consenso distribuido para decisiones de moderación
- Considera límites de tamaño para grupos grandes
- Implementa encriptación end-to-end para mensajes grupales
- Proporciona feedback visual para acciones de moderación
- Considera migración automática de grupos entre transportes
- Implementa cache local para mensajes recientes