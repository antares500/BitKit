<p align="center">
  <img src="bitKit.svg" alt="bitKit Icon" width="200">
</p>

# bitKit (alpha)
Comunicaciones P2P seguras y privadas para la era moderna.

Paquete Swift modular para comunicaciones P2P seguras, privadas y resistentes a la censura. Proporciona una arquitectura completa de mensajería peer-to-peer con soporte para Bluetooth Low Energy (BLE), Nostr relays globales, geolocalización.

## Características Principales

- **🔐 Encriptación End-to-End**: Protocolo Noise con forward secrecy perfecta
- **📡 Múltiples Transportes**: BLE mesh offline, Nostr relays globales, Tor
- **🌍 Geolocalización**: Mensajería basada en ubicación y canales geo
- **🎵 Multimedia Completo**: Voz, imágenes, video, streaming y transferencias de archivos
- **👥 Grupos y Moderación**: Chat grupal con moderación distribuida y analytics
- **🛡️ Anonimato Avanzado**: Tor, zero-knowledge proofs, verificación de identidad
- **📊 Analytics de Comunidad**: Métricas detalladas, insights y dashboards
- **🔄 Arquitectura Reactiva**: Combine publishers para actualizaciones en tiempo real
- **🌐 Coordinación Inteligente**: Enrutamiento automático y failover entre transportes
- **💾 Persistencia Segura**: Keychain con migración y backup
- **📱 Multiplataforma**: iOS 17+ y macOS 14+

## Instalación

### Swift Package Manager

Añade a tu `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/antares500/bitKit.git", from: "1.2.0")
]
```

Elige los targets según tus necesidades o usa presets recomendados:

#### Presets Recomendados
```swift
// Básico (mensajería simple)
.target(name: "MiApp", dependencies: [
    "BitCore",           // Núcleo requerido
    "BitCommunications"  // Coordinación básica
])

// Completo (todo incluido)
.target(name: "MiApp", dependencies: [
    "BitKit"  // Incluye todos los módulos
])

// Personalizado (elige módulos)
.target(name: "MiApp", dependencies: [
    "BitCore",                  // Núcleo con comunicaciones básicas
    "BitTransport",             // BLE + Nostr
    "BitGeo",                   // Geolocalización
    "BitState",                 // Persistencia
    "BitMedia",                 // Multimedia
    "BitTor",                   // Anonimato
    "BitChatGroup",             // Chat y grupos
    "BitReliability",   // Confiabilidad, sync, verificación
    "BitAnalytics"              // Métricas
])
```

## Arquitectura

```
bitKit
├── BitCore          # Núcleo: protocolos, encriptación, utilidades
├── BitTransport     # Transportes: BLE mesh + Nostr relays
├── BitGeo           # Geolocalización y canales geo
├── BitState         # Persistencia segura (Keychain)
├── BitMedia         # Manejo de multimedia
├── BitTor           # Anonimato con Tor
├── BitCommunications # Coordinación de transportes
├── BitChatGroup     # Chat individual y grupal
├── BitReliability   # Confiabilidad, sync, verificación
├── BitAnalytics     # Analytics y métricas de comunidad
└── BitKit           # Todo incluido (preset completo)
```

## Configuración de Redes

bitKit permite crear **tu propia red** o **incluirte en la red bitchat** existente. Ambas opciones son compatibles con la última versión de bitchat si el usuario lo necesita.

### Mi Propia Red
- Configura aislamiento usando relays Nostr específicos o firmas de app personalizadas.
- Los mensajes se firman con claves únicas, asegurando que solo apps autorizadas los procesen.
- **Aviso**: Debes cumplir con los estándares de la red original marcados por Jack Dorsey y adaptarte a sus actualizaciones. bitchat no leerá mensajes de redes propias sin configuración explícita.

### Incluirme en la Red Bit
- Usa las mismas APIs y dependencias que bitchat para interoperabilidad completa.
- bitKit se alinea con la última versión de bitchat, permitiendo inclusión en su red mediante configuración compartida (ej. relays públicos o claves compatibles).

Ejemplo de configuración para compatibilidad:
```swift
// Para red propia: configura relays y firmas personalizadas
let communications = BitCommunications(
    customRelays: ["tu-relay.nostr"], 
    appSignature: "tu-firma-unica"
)

// Para incluirte en bitchat: usa configuración por defecto compatible
let communications = BitCommunications()  // Usa relays y firmas de bitchat
```

## Ejemplos de Uso

### Inicialización Básica

```swift
import BitCore
import BitCommunications

// Inicializar servicios básicos
let logger = BitLogger()
let core = BitCore(logger: logger)
let communications = BitCommunications(core: core)

// Configurar delegados para eventos
communications.delegate = self
```

### Enviar un Mensaje

```swift
import BitCommunications

// Enviar mensaje privado
let messageID = communications.sendMessage(
    content: "Hola, mundo!",
    to: recipientPeerID,
    options: .init(encrypt: true, sign: true)
)

// Enviar a grupo
communications.sendGroupMessage(
    content: "Mensaje grupal",
    to: groupID
)
```

### Manejo de Multimedia

```swift
import BitMedia

// Grabar voz
let recorder = VoiceRecorder()
try await recorder.requestPermission()
let audioURL = try recorder.startRecording()

// Enviar archivo
communications.sendFile(
    url: audioURL,
    to: peerID,
    metadata: .init(type: .audio)
)
```

### Geolocalización

```swift
import BitGeo

// Crear canal geo
let geoChannel = GeoChannel(
    center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
    radius: 1000
)

// Mensaje local
communications.sendGeoMessage(
    content: "Evento cercano",
    in: geoChannel
)
```

Para más ejemplos detallados, consulta la carpeta [Documentation/Examples/](Documentation/Examples/):

1. [01 - Configuración Básica](Documentation/Examples/01_Basic_Configuration.md)
2. [02 - Configuración BLE Mesh](Documentation/Examples/02_BLE_Mesh_Configuration.md)
3. [03 - Integración Nostr](Documentation/Examples/03_Nostr_Integration.md)
4. [04 - Geolocalización y Mensajería Local](Documentation/Examples/04_Geolocation_Local_Messaging.md)
5. [05 - Características Avanzadas y Personalización](Documentation/Examples/05_Advanced_Features_Customization.md)
6. [06 - Manejo de Multimedia](Documentation/Examples/06_Multimedia_Handling.md)
7. [07 - Persistencia de Estado y Backup](Documentation/Examples/07_State_Persistence_Backup.md)
8. [08 - Chat Grupal y Moderación](Documentation/Examples/08_Group_Chat_Moderation.md)
9. [09 - Seguridad Avanzada con Tor](Documentation/Examples/09_Advanced_Security_Tor.md)
10. [10 - Coordinación de Transportes](Documentation/Examples/10_Transport_Coordination.md)
11. [11 - Transferencias de Archivos y Streaming](Documentation/Examples/11_File_Transfers_Streaming.md)
12. [12 - Verificación de Identidad y Confianza](Documentation/Examples/12_Identity_Verification_Trust.md)
13. [13 - Analytics y Métricas de Comunidad](Documentation/Examples/13_Analytics_Metrics_Community.md)
14. [14 - Logging y Monitoreo](Documentation/Examples/15_Logging_Monitoring.md)
15. [15 - Enrutamiento Inteligente y Failover](Documentation/Examples/16_Routing_Intelligent_Failover.md)

## API Reference

### BitCommunications

Clase principal para coordinar comunicaciones P2P.

```swift
public class BitCommunications {
    public init(core: BitCore, transports: [Transport])
    public func start() async throws
    public func stop() async
    public func sendMessage(_ content: String, to peerID: PeerID, options: MessageOptions) -> MessageID
    public func sendGroupMessage(_ content: String, to groupID: GroupID) -> MessageID
    public func sendFile(url: URL, to peerID: PeerID, metadata: FileMetadata) async throws -> TransferID
}
```

### BitCore

Núcleo con utilidades básicas.

```swift
public class BitCore {
    public init(logger: BitLogger)
    public var encryption: EncryptionProtocol { get }
    public var keyManager: KeyManager { get }
}
```

### BitMedia

Manejo de multimedia.

```swift
public class VoiceRecorder {
    public static let shared = VoiceRecorder()
    public func requestPermission() async -> Bool
    public func startRecording() throws -> URL
    public func stopRecording() -> URL?
}
```

Para documentación completa de API, genera docs con DocC o consulta el código fuente.

### Configuración de Redes

bitKit permite crear **tu propia red** o **incluirte en la red bitchat** existente. Ambas opciones son compatibles con la última versión de bitchat si el usuario lo necesita.

### Mi Propia Red
- Configura aislamiento usando relays Nostr específicos o firmas de app personalizadas.
- Los mensajes se firman con claves únicas, asegurando que solo apps autorizadas los procesen.
- **Aviso**: Debes cumplir con los estándares de la red original marcados por Jack Dorsey y adaptarte a sus actualizaciones. bitchat no leerá mensajes de redes propias sin configuración explícita.

### Incluirme en la Red Bit
- Usa las mismas APIs y dependencias que bitchat para interoperabilidad completa.
- bitKit se alinea con la última versión de bitchat, permitiendo inclusión en su red mediante configuración compartida (ej. relays públicos o claves compatibles).

Ejemplo de configuración para compatibilidad:
```swift
// Para red propia: configura relays y firmas personalizadas
let communications = BitCommunications(
    customRelays: ["tu-relay.nostr"], 
    appSignature: "tu-firma-unica"
)

## Requisitos

- **iOS**: 17.0+
- **macOS**: 14.0+
- **Xcode**: 15.0+
- **Swift**: 5.9+

## Permisos

### iOS
Añade a tu `Info.plist`:
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Se necesita acceso a Bluetooth para comunicaciones P2P</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Se necesita ubicación para canales geográficos</string>
<key>NSMicrophoneUsageDescription</key>
<string>Se necesita micrófono para mensajes de voz</string>
```

## Contribución

1. Fork el repositorio
2. Crea una rama para tu feature
3. Añade tests
4. Envía un Pull Request

## Ejecutar Tests

Para ejecutar los tests del proyecto:

```bash
swift test
```

Esto ejecutará todos los tests definidos en la carpeta `Tests/`, incluyendo pruebas para las clases principales como `KeychainManager`, `NoiseEncryptionService`, `MessageRouter`, etc.

## Licencia

Este proyecto está bajo la licencia Unlicense. Ver [UNLICENSE](UNLICENSE) para más detalles.

## Soporte

- **Issues**: [GitHub Issues](https://github.com/antares500/bitKit/issues)
- **Discusiones**: [GitHub Discussions](https://github.com/antares500/bitKit/discussions)

---

**bitKit** - Comunicaciones P2P seguras y privadas para la era moderna.