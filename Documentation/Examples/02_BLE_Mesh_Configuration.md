# 02 - Configuración BLE Mesh

## Descripción

Este ejemplo extiende la configuración básica para implementar una red mesh Bluetooth Low Energy (BLE) completa. La comunicación mesh permite que los mensajes se propaguen a través de múltiples dispositivos, creando una red ad-hoc resistente que funciona sin infraestructura central. Es ideal para situaciones donde no hay conectividad a internet o se requiere comunicación local altamente confiable.

**Beneficios:**
- Comunicación offline sin depender de servidores o internet
- Propagación automática de mensajes a través de la red mesh
- Mayor alcance efectivo al usar múltiples dispositivos como repetidores
- Baja latencia para comunicaciones locales

**Consideraciones:**
- Requiere dispositivos con Bluetooth Low Energy
- El alcance efectivo depende de la densidad de dispositivos
- Mayor consumo de batería debido a la comunicación continua
- Los mensajes pueden tener latencia variable según la topología de la red
- Considera límites de tasa para evitar saturación de la red

## Pasos Previos Obligatorios

1. **Completar la Configuración Básica** (Ejemplo 01)
2. **Añadir permisos de Bluetooth** en Info.plist:
   ```xml
   <key>NSBluetoothAlwaysUsageDescription</key>
   <string>Se necesita acceso a Bluetooth para comunicaciones P2P mesh</string>
   ```
3. **Implementar Combine publishers** para observar cambios en tiempo real
4. **Configurar manejo de estado BLE** en el delegate

## Código de Implementación

```swift
import BitchatCore
import BitchatBLE
import BitchatState
import Combine

// Extender la configuración básica con BLE Mesh
class BLEMeshController {
    private let keychain: MiKeychain
    private let delegate: MiDelegate
    private let identityManager: SecureIdentityStateManager
    private var bleService: BLEService?
    private var cancellables = Set<AnyCancellable>()

    init(keychain: MiKeychain, delegate: MiDelegate) {
        self.keychain = keychain
        self.delegate = delegate
        self.identityManager = SecureIdentityStateManager(keychain: keychain)
    }

    // Configurar y iniciar BLE Mesh
    func iniciarBLEMesh() {
        // Crear servicio BLE con configuración mesh
        bleService = BLEService(
            keychain: keychain,
            identityManager: identityManager,
            delegate: delegate
        )

        // Configurar identidad del usuario
        bleService?.myNickname = "UsuarioMesh"

        // Observar cambios en peers conectados en tiempo real
        observarPeersConectados()

        // Iniciar servicios BLE
        bleService?.startServices()

        print("BLE Mesh iniciado - listo para comunicación peer-to-peer")
    }

    // Observar peers conectados usando Combine publishers
    private func observarPeersConectados() {
        bleService?.peerSnapshotPublisher
            .sink { [weak self] snapshots in
                self?.procesarPeersConectados(snapshots)
            }
            .store(in: &cancellables)
    }

    // Procesar lista de peers conectados
    private func procesarPeersConectados(_ snapshots: [TransportPeerSnapshot]) {
        print("Peers activos en mesh: \(snapshots.count)")

        for peer in snapshots where peer.isConnected {
            print("- \(peer.nickname) (\(peer.peerID)) - Conectado")

            // Verificar si el peer es favorito
            if let fingerprint = bleService?.getFingerprint(for: peer.peerID) {
                let esFavorito = delegate.isFavorite(fingerprint: fingerprint)
                if esFavorito {
                    print("  ⭐ Peer favorito detectado")
                }
            }
        }

        // Actualizar UI con lista de peers
        actualizarUIListaPeers(snapshots)
    }

    // Enviar mensaje público a toda la red mesh
    func enviarMensajePublico(_ contenido: String, menciones: [String] = []) {
        guard !contenido.isEmpty else { return }

        bleService?.sendMessage(contenido, mentions: menciones)
        print("Mensaje público enviado a mesh: \(contenido)")
    }

    // Enviar mensaje privado a un peer específico
    func enviarMensajePrivado(_ contenido: String, a peerID: PeerID, nickname: String) {
        guard !contenido.isEmpty else { return }

        let messageID = UUID().uuidString
        bleService?.sendPrivateMessage(
            contenido,
            to: peerID,
            recipientNickname: nickname,
            messageID: messageID
        )

        print("Mensaje privado enviado a \(nickname): \(contenido)")
    }

    // Obtener información detallada de un peer
    func obtenerInformacionPeer(_ peerID: PeerID) -> PeerInfo? {
        guard let service = bleService else { return nil }

        let nickname = service.peerNickname(peerID: peerID)
        let estaConectado = service.isPeerConnected(peerID)
        let fingerprint = service.getFingerprint(for: peerID)
        let estadoSesion = service.getNoiseSessionState(for: peerID)

        return PeerInfo(
            peerID: peerID,
            nickname: nickname,
            isConnected: estaConectado,
            fingerprint: fingerprint,
            sessionState: estadoSesion
        )
    }

    // Actualizar UI con lista de peers (stub)
    private func actualizarUIListaPeers(_ snapshots: [TransportPeerSnapshot]) {
        // Aquí actualizarías tu interfaz de usuario
        // Por ejemplo: tableView.reloadData()
        print("UI actualizada con \(snapshots.count) peers")
    }

    // Detener mesh y limpiar recursos
    func detenerMesh() {
        bleService?.emergencyDisconnectAll()
        bleService?.stopServices()
        cancellables.removeAll()

        print("BLE Mesh detenido")
    }
}

// Estructura auxiliar para información de peer
struct PeerInfo {
    let peerID: PeerID
    let nickname: String?
    let isConnected: Bool
    let fingerprint: String?
    let sessionState: LazyHandshakeState
}

// Extensión del delegate para manejar eventos mesh específicos
extension MiDelegate {
    // Este método ya está en BitchatDelegate, pero podemos añadir lógica específica
    func didUpdatePeerList(_ peers: [PeerID]) {
        print("Lista mesh actualizada: \(peers.count) peers totales")

        // Aquí podrías actualizar estadísticas de la red mesh
        // Por ejemplo: número de peers, topología, etc.
    }

    // Verificar si un peer es favorito (requerido por protocolo)
    func isFavorite(fingerprint: String) -> Bool {
        // Implementar lógica para verificar favoritos
        // Por ejemplo: consultar base de datos local
        return false // Stub
    }
}

// Uso típico en una aplicación
class MeshChatViewController {
    private let meshController: BLEMeshController

    init(meshController: BLEMeshController) {
        self.meshController = meshController
    }

    func viewDidLoad() {
        // Iniciar mesh cuando la vista carga
        meshController.iniciarBLEMesh()
    }

    func enviarMensaje(_ texto: String) {
        // Enviar a toda la red mesh
        meshController.enviarMensajePublico(texto)
    }

    func enviarMensajePrivado(_ texto: String, a peerID: PeerID, nickname: String) {
        // Enviar solo al peer específico
        meshController.enviarMensajePrivado(texto, a: peerID, nickname: nickname)
    }

    func viewWillDisappear() {
        // Detener mesh cuando la vista se cierra
        meshController.detenerMesh()
    }
}

// Funciones Avanzadas de BLEService

// 1. Reset de Identidad en Modo Pánico
// Útil para emergencias de seguridad, resetea claves y sesiones sin perder nickname
func resetearIdentidadParaPanico(nicknameActual: String) {
    bleService?.resetIdentityForPanic(currentNickname: nicknameActual)
    print("Identidad reseteada para pánico")
}

// 2. Enviar Notificación de Favorito
// Notifica a un peer si es marcado como favorito
func enviarNotificacionFavorito(peerID: PeerID, esFavorito: Bool) {
    bleService?.sendFavoriteNotification(to: peerID, isFavorite: esFavorito)
}

// 3. Enviar Anuncio de Broadcast
// Fuerza el envío de un anuncio para actualizar presencia
func enviarAnuncioBroadcast() {
    bleService?.sendBroadcastAnnounce()
}

// 4. Enviar Acuse de Recibo de Entrega
// Confirma recepción de un mensaje específico
func enviarAcuseEntrega(messageID: String, peerID: PeerID) {
    bleService?.sendDeliveryAck(for: messageID, to: peerID)
}

// 5. Trigger Handshake Manual
// Inicia handshake Noise manualmente si es necesario
func iniciarHandshake(peerID: PeerID) {
    bleService?.triggerHandshake(with: peerID)
}

// 6. Obtener Estado Actual de Bluetooth
// Verifica el estado del hardware BLE
func obtenerEstadoBluetooth() -> CBManagerState? {
    return bleService?.getCurrentBluetoothState()
}

// 7. Acceso Directo al Servicio Noise
// Para operaciones avanzadas de encriptación
func obtenerServicioNoise() -> NoiseEncryptionService? {
    return bleService?.getNoiseService()
}

// 8. Obtener Snapshots Actuales de Peers
// Devuelve una lista de peers con estado actual
func obtenerSnapshotsPeers() -> [TransportPeerSnapshot]? {
    return bleService?.currentPeerSnapshots()
}

## Notas Adicionales

- La red mesh se forma automáticamente cuando múltiples dispositivos ejecutan esta configuración
- Los mensajes se propagan automáticamente a través de peers intermedios
- Considera implementar límites de frecuencia para evitar spam en la red
- El rendimiento depende de la densidad de dispositivos y condiciones de radiofrecuencia
- Para debugging, monitorea el estado BLE en el delegate