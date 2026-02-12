# 01 - Configuración Básica

## Descripción

Este ejemplo muestra cómo configurar los componentes básicos de bitKit para una aplicación de mensajería P2P. Aprenderás a implementar los protocolos requeridos, configurar la persistencia segura y manejar eventos de comunicación. Esta configuración proporciona una base sólida para cualquier aplicación que necesite comunicación peer-to-peer segura.

**Beneficios:**
- Establece una arquitectura modular que facilita la adición de transportes adicionales
- Proporciona encriptación end-to-end desde el inicio
- Maneja automáticamente la persistencia de identidades y claves

**Consideraciones:**
- Requiere implementar KeychainManagerProtocol para persistencia segura
- El delegate debe manejar todos los eventos de comunicación
- Asegúrate de solicitar permisos necesarios antes de inicializar transportes

## Pasos Previos Obligatorios

1. **Instalar el paquete** siguiendo las instrucciones de instalación en el README principal
2. **Implementar KeychainManagerProtocol** para persistencia segura de claves
3. **Crear una clase delegate** que conforme a BitDelegate
4. **Configurar permisos** en Info.plist para Bluetooth y ubicación si usas esos transportes

## Código de Implementación

```swift
import BitCore
import BitTransport
import BitState

// Paso 1: Implementar KeychainManagerProtocol para persistencia segura
// Esta implementación básica usa UserDefaults - para producción usa Keychain real
class MiKeychain: KeychainManagerProtocol {
    // Almacena claves de identidad de forma segura
    func getIdentityKey(forKey key: String) -> Data? {
        return UserDefaults.standard.data(forKey: "bitkit_\(key)")
    }

    // Guarda claves de identidad de forma segura
    func saveIdentityKey(_ data: Data, forKey key: String) -> Bool {
        UserDefaults.standard.set(data, forKey: "bitkit_\(key)")
        return UserDefaults.standard.synchronize()
    }

    // Elimina claves de identidad
    func deleteIdentityKey(forKey key: String) -> Bool {
        UserDefaults.standard.removeObject(forKey: "bitkit_\(key)")
        return UserDefaults.standard.synchronize()
    }

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

// Implementación básica de NostrIdentityBridge
class MiNostrIdentityBridge: NostrIdentityBridge {
    private let keychain: KeychainManagerProtocol

    init(keychain: KeychainManagerProtocol) {
        self.keychain = keychain
    }

    func getCurrentNostrIdentity() throws -> String {
        // Placeholder para clave pública Nostr
        return "npub1..."
    }
}
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
        let identityManager = SecureIdentityStateManager(keychain)

        // Configurar bridge de identidad Nostr
        let idBridge = MiNostrIdentityBridge(keychain: keychain)

        // Inicializar servicio BLE
        bleService = BLEService(
            keychain: keychain,
            idBridge: idBridge,
            identityManager: identityManager
        )

        // Configurar delegate
        bleService?.delegate = delegate

        // Configurar nickname visible para otros peers
        bleService?.myNickname = "MiUsuario"

        // Iniciar servicios BLE
        bleService?.startServices()

        print("bitKit configurado y listo")
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
- Para comunicación global, añade integración Nostr en el siguiente ejemplo
- Asegúrate de manejar el ciclo de vida de los servicios (start/stop) apropiadamente
- Los mensajes se encriptan automáticamente usando el protocolo Noise