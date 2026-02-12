# 15 - Routing Inteligente y Failover

## Descripción

Este ejemplo muestra cómo implementar routing inteligente y failover automático en BitRouting. Aprenderás a configurar rutas óptimas, detección de fallos, balanceo de carga, enrutamiento geográfico y recuperación automática de conexiones caídas.

**Beneficios:**
- Enrutamiento automático basado en calidad de conexión
- Failover transparente entre transportes
- Optimización de rutas para latencia mínima
- Recuperación automática de conexiones perdidas
- Balanceo de carga inteligente

**Consideraciones:**
- Implementa timeouts apropiados para detección de fallos
- Considera el costo de batería de reintentos
- Configura prioridades de transporte según contexto
- Implementa límites de reintentos para evitar bucles
- Monitorea métricas de routing para optimización

## Pasos Previos Obligatorios

1. **Completar Configuración Básica** (Ejemplo 01)
2. **Configurar Múltiples Transportes** (Ejemplos 02-04)
3. **Añadir BitRouting** a las dependencias del proyecto

## Código de Implementación

```swift
import BitCore
import BitRouting
import BitTransport
import BitCommunications

// Router inteligente con failover
class IntelligentRouter {
    private let router = BitRouter()
    private let transportCoordinator = TransportCoordinator()
    
    init() {
        configureRouting()
        setupFailover()
    }
    
    private func configureRouting() {
        // Configurar estrategias de routing
        router.addStrategy(.lowestLatency)
        router.addStrategy(.highestBandwidth)
        router.addStrategy(.geographicProximity)
        
        // Configurar prioridades de transporte
        router.setPriority(.ble, priority: 1.0)  // Alta prioridad para BLE local
        router.setPriority(.nostr, priority: 0.8) // Buena para global
        router.setPriority(.tor, priority: 0.5)   // Baja para anonimato
        
        // Configurar rutas geográficas
        router.enableGeographicRouting(radius: 1000) // 1km para BLE
    }
    
    private func setupFailover() {
        // Configurar failover automático
        router.enableFailover(maxRetries: 3, backoffStrategy: .exponential)
        
        // Monitorear calidad de conexiones
        router.setQualityThreshold(minQuality: 0.7) { transport, quality in
            print("Calidad de \(transport) cambió a \(quality)")
            if quality < 0.5 {
                self.router.deprioritize(transport)
            }
        }
        
        // Configurar recuperación automática
        router.onConnectionLost { transport, peerID in
            print("Conexión perdida con \(peerID) en \(transport)")
            // Intentar reconectar vía otro transporte
            self.attemptReconnection(peerID)
        }
    }
    
    func sendMessageWithRouting(_ message: BitMessage, to peerID: PeerID) {
        // El router elige automáticamente el mejor transporte
        router.route(message, to: peerID) { result in
            switch result {
            case .success:
                print("Mensaje enviado exitosamente")
            case .failure(let error):
                print("Error de routing: \(error)")
                // Intentar con transporte alternativo
                self.fallbackSend(message, to: peerID)
            }
        }
    }
    
    private func attemptReconnection(_ peerID: PeerID) {
        // Intentar reconectar vía transporte alternativo
        router.findAlternativeRoute(to: peerID) { alternative in
            if let alt = alternative {
                print("Intentando reconexión vía \(alt)")
                // Implementar lógica de reconexión
            }
        }
    }
    
    private func fallbackSend(_ message: BitMessage, to peerID: PeerID) {
        // Lógica de fallback manual si el routing falla
        transportCoordinator.sendViaAnyAvailableTransport(message, to: peerID)
    }
}

// Uso en la app
let intelligentRouter = IntelligentRouter()
// El router maneja automáticamente el routing inteligente
```

    // Métodos adicionales requeridos por el protocolo
    func save(key: String, data: Data, service: String, accessible: CFString?) {
        // Implementación completa del Keychain
        // Para producción: usar Keychain Services de iOS
    }

    func load(key: String, service: String) -> Data? {
        // Implementación completa del Keychain
        return nil
    }

    func delete(key: String, service: String) {
        // Implementación completa del Keychain
    }
}

// Paso 2: Implementar BitDelegate para manejar eventos
class MiDelegate: BitDelegate {
    // Se llama cuando se recibe un mensaje de chat
    func didReceiveMessage(_ message: BitMessage) {
        print("Mensaje recibido: \(message.content)")
        // Aquí actualizarías tu UI o guardarías en base de datos
    }

    // Se llama cuando se conecta un nuevo peer
    func didConnectToPeer(_ peerID: PeerID) {
        print("Peer conectado: \(peerID)")
        // Actualizar lista de peers conectados en UI
    }

    // Se llama cuando se desconecta un peer
    func didDisconnectFromPeer(_ peerID: PeerID) {
        print("Peer desconectado: \(peerID)")
        // Remover de lista de peers conectados
    }

    // Se llama cuando cambia la lista de peers
    func didUpdatePeerList(_ peers: [PeerID]) {
        print("Lista de peers actualizada: \(peers.count) peers")
        // Actualizar UI con nueva lista
    }

    // Se llama cuando cambia el estado de Bluetooth (BLE)
    func didUpdateBluetoothState(_ state: CBManagerState) {
        print("Estado Bluetooth: \(state.rawValue)")
        // Mostrar estado en UI o manejar errores
    }

    // Se llama para mensajes públicos (broadcast)
    func didReceivePublicMessage(from peerID: PeerID, nickname: String, content: String, timestamp: Date, messageID: String?) {
        print("Mensaje público de \(nickname): \(content)")
        // Procesar mensaje público
    }

    // Se llama para payloads encriptados (mensajes privados)
    func didReceiveNoisePayload(from peerID: PeerID, type: NoisePayloadType, payload: Data, timestamp: Date) {
        print("Payload encriptado recibido de \(peerID)")
        // Desencriptar y procesar payload
    }
}

// Paso 3: Configuración e inicialización
class MiAppController {
    private let keychain = MiKeychain()
    private let delegate = MiDelegate()
    private var bleService: BLEService?

    func configurarBit() {
        // Configurar identidad segura usando el keychain
        let identityManager = SecureIdentityStateManager(keychain: keychain)

        // Configurar relays Nostr desde CSV o lista personalizada
        let relays = loadRelaysFromCSV() // Implementa esta función para cargar relays

        // Configurar red privada (opcional)
        let networkConfig = NetworkConfig.shared
        if networkConfig.isPrivate {
            // Usar relays personalizados y firma para red privada
            let customRelays = relays.map { $0.url }
            let appSignature = networkConfig.publicKey
            // Verificar firma con clave privada (no almacenar privada)
        } else {
            // Modo público: compatible con bitchat
            let customRelays: [String]? = nil
            let appSignature: String? = nil
        }

        // Inicializar servicio BLE con configuración
        bleService = BLEService(
            keychain: keychain,
            identityManager: identityManager,
            delegate: delegate,
            customRelays: customRelays,
            appSignature: appSignature
        )

        // Configurar nickname visible para otros peers
        bleService?.myNickname = "MiUsuario"

        // Iniciar servicios BLE
        bleService?.startServices()

        print("bitKit configurado y listo")
    }

    private func loadRelaysFromCSV() -> [Relay] {
        // Cargar relays desde /Users/antares500/PROYECT/bitchat/relays/online_relays_gps.csv
        // Implementa parsing CSV
        return []
    }

    func enviarMensaje() {
        // Enviar mensaje público a todos los peers conectados
        bleService?.sendMessage("¡Hola desde Bit!", mentions: [])
    }

    func detenerServicios() {
        // Detener todos los servicios cuando la app se cierra
        bleService?.stopServices()
    }
}
```

## Notas Adicionales

- Esta configuración básica proporciona comunicación BLE mesh offline
- Para comunicación global, añade BitNostr en el siguiente ejemplo
- Asegúrate de manejar el ciclo de vida de los servicios (start/stop) apropiadamente
- Los mensajes se encriptan automáticamente usando el protocolo Noise

## Gestión de Relays Nostr

Para configurar relays personalizados, carga la lista desde el CSV de bitchat:

```swift
struct Relay {
    let url: String
    let latitude: Double
    let longitude: Double
}

func loadRelaysFromCSV() -> [Relay] {
    let csvPath = "/Users/antares500/PROYECT/bitchat/relays/online_relays_gps.csv"
    guard let content = try? String(contentsOfFile: csvPath) else { return [] }
    let lines = content.split(separator: "\n").dropFirst() // Skip header
    return lines.compactMap { line in
        let components = line.split(separator: ",")
        guard components.count == 3,
              let lat = Double(components[1]),
              let lon = Double(components[2]) else { return nil }
        return Relay(url: String(components[0]), latitude: lat, longitude: lon)
    }
}
```

## Configuración de Red Privada

Para crear una red privada con firma:

```swift
import secp256k1

struct NetworkConfig {
    var isPrivate: Bool = false
    var networkName: String = ""
    var publicKey: String = ""
    var signature: String = ""
    var version: Int = 1

    mutating func regenerateKey() {
        let privateKey = try! secp256k1.Signing.PrivateKey()
        let publicKeyData = privateKey.publicKey.xonly.bytes
        publicKey = publicKeyData.hexString
        version += 1
        let message = (networkName + "\(version)").data(using: .utf8)!
        let signatureData = try! privateKey.signature(for: message).rawRepresentation
        signature = signatureData.hexString
    }

    func verifySignature() -> Bool {
        guard let publicKeyData = Data(hexString: publicKey),
              let signatureData = Data(hexString: signature),
              let sig = try? secp256k1.Signing.ECDSASignature(rawRepresentation: signatureData) else { return false }
        let message = (networkName + "\(version)").data(using: .utf8)!
        return secp256k1.Signing.PublicKey(xonlyBytes: publicKeyData).isValidSignature(sig, for: message)
    }
}
```

Esto permite redes aisladas con verificación de integridad.