# 03 - Integración Nostr

## Descripción

Este ejemplo demuestra cómo integrar el protocolo Nostr para comunicaciones globales a través de relays públicos. Nostr proporciona alcance mundial al publicar mensajes en servidores descentralizados, complementando perfectamente las comunicaciones locales BLE. Esta configuración híbrida permite tanto comunicación offline local como global online, creando una experiencia de mensajería verdaderamente distribuida.

**Beneficios:**
- Comunicación global sin depender de una única plataforma centralizada
- Mensajes persistentes en relays públicos para acceso desde cualquier dispositivo
- Integración perfecta con la web descentralizada
- Resistencia a la censura al usar múltiples relays

**Consideraciones:**
- Requiere conectividad a internet para relays Nostr
- Los mensajes son públicos por defecto (aunque se pueden encriptar)
- Dependencia de la disponibilidad y confiabilidad de relays externos
- Mayor latencia comparado con BLE local
- Considera la privacidad: los relays pueden ver metadatos de mensajes

## Pasos Previos Obligatorios

1. **Completar Configuración Básica** (Ejemplo 01)
2. **Añadir BitNostr** a las dependencias del proyecto
3. **Configurar conectividad de red** (necesaria para relays)
4. **Implementar NostrIdentityBridge** si usas identidades Nostr personalizadas

## Código de Implementación

```swift
import BitCore
import BitNostr
import BitState

// Controlador para integración Nostr
class NostrController {
    private let keychain: MiKeychain
    private let delegate: MiDelegate
    private var nostrManager: NostrRelayManager?
    private var identityBridge: NostrIdentityBridge?

    init(keychain: MiKeychain, delegate: MiDelegate) {
        self.keychain = keychain
        self.delegate = delegate
    }

    // Configurar y conectar a relays Nostr
    func configurarNostr() {
        // Inicializar manager de relays Nostr
        nostrManager = NostrRelayManager.shared

        // Configurar identity bridge (opcional, para identidades personalizadas)
        identityBridge = NostrIdentityBridge(keychain: keychain)

        // Conectar a relays públicos confiables
        conectarARelaysPublicos()

        print("Nostr configurado - listo para comunicación global")
    }

    // Conectar a relays desde CSV o personalizados
    private func conectarARelays() {
        // Cargar relays desde CSV de bitchat
        let relays = loadRelaysFromCSV()
        
        // Para red privada, filtrar por proximidad o seleccionar específicos
        let selectedRelays = relays.prefix(10).map { $0.url } // Usar primeros 10
        
        // Conectar a relays seleccionados
        for relayURL in selectedRelays {
            if relayURL.hasPrefix("ws://") || relayURL.hasPrefix("wss://") {
                nostrManager?.connect(to: relayURL)
                print("Conectando a relay: \(relayURL)")
            }
        }
    }

    private func loadRelaysFromCSV() -> [Relay] {
        // Implementación similar al ejemplo 01
        return []
    }

    // Publicar un evento de texto (mensaje público)
    func publicarMensaje(_ contenido: String, etiquetas: [String] = []) {
        guard !contenido.isEmpty else { return }

        // Crear evento Nostr de tipo 1 (texto)
        let evento = NostrEvent(
            kind: 1,  // Kind 1 = texto/note
            content: contenido,
            tags: crearEtiquetas(etiquetas)
        )

        // Enviar evento a relays conectados
        nostrManager?.sendEvent(evento)

        print("Mensaje publicado en Nostr: \(contenido)")
    }

    // Crear etiquetas para el evento
    private func crearEtiquetas(_ etiquetasPersonalizadas: [String]) -> [[String]] {
        var tags = [[String]]()

        // Añadir etiquetas personalizadas como topics
        for etiqueta in etiquetasPersonalizadas {
            tags.append(["t", etiqueta])  // Tag 't' para topics
        }

        // Añadir metadatos útiles
        tags.append(["client", "BitCommunications"])

        return tags
    }

    // Suscribirse a eventos de un autor específico
    func seguirAutor(hexPubKey: String) {
        // Crear filtro para eventos de texto de este autor
        let filtro = NostrFilter(
            authors: [hexPubKey],  // Solo eventos de este autor
            kinds: [1],            // Solo eventos de texto
            limit: 50              // Últimos 50 eventos
        )

        // Suscribirse usando un ID único para esta suscripción
        let subscriptionID = "seguir_\(hexPubKey)"
        nostrManager?.subscribe(
            filter: filtro,
            id: subscriptionID,
            relayUrls: nil  // Usar todos los relays conectados
        )

        print("Siguiendo autor: \(hexPubKey)")
    }

    // Suscribirse a un topic/hashtag específico
    func seguirTopic(_ topic: String) {
        let filtro = NostrFilter(
            tags: ["t": [topic]],  // Eventos con tag 't' que contenga este topic
            kinds: [1],
            limit: 20
        )

        let subscriptionID = "topic_\(topic)"
        nostrManager?.subscribe(
            filter: filtro,
            id: subscriptionID,
            relayUrls: nil
        )

        print("Siguiendo topic: #\(topic)")
    }

    // Dejar de seguir una suscripción
    func dejarDeSeguir(subscriptionID: String) {
        nostrManager?.closeSubscription(id: subscriptionID)
        print("Suscripción cerrada: \(subscriptionID)")
    }

    // Obtener identidad Nostr actual (si está configurada)
    func obtenerIdentidadActual() -> String? {
        do {
            return try identityBridge?.getCurrentNostrIdentity()
        } catch {
            print("Error obteniendo identidad Nostr: \(error)")
            return nil
        }
    }

    // Crear un mensaje privado encriptado (DM)
    func enviarMensajePrivado(_ contenido: String, a destinatarioPubKey: String) {
        guard !contenido.isEmpty else { return }
        guard let miIdentidad = obtenerIdentidadActual() else {
            print("Error: No hay identidad Nostr configurada")
            return
        }

        // En Nostr, los DMs se encriptan usando NIP-04
        // Crear evento de kind 4 (DM encriptado)
        let evento = NostrEvent(
            kind: 4,  // Kind 4 = Direct Message encriptado
            content: contenido,  // Se encriptaría antes de enviar
            tags: [["p", destinatarioPubKey]]  // Tag con pubkey del destinatario
        )

        // En una implementación completa, aquí encriptaríamos el contenido
        // usando la clave privada del remitente y pubkey del destinatario

        nostrManager?.sendEvent(evento)
        print("DM enviado a \(destinatarioPubKey)")
    }

    // Buscar relays cercanos geográficamente
    func buscarRelaysCercanos(latitud: Double, longitud: Double) {
        // Usar BitGeo para encontrar relays cercanos
        // Esto mejoraría la velocidad y privacidad
        print("Buscando relays cercanos a (\(latitud), \(longitud))")

        // En una implementación completa, usaríamos:
        // let geoRelays = GeoRelayDirectory()
        // let relaysCercanos = geoRelays.closestRelays(toLat: latitud, lon: longitud)
    }

    // Desconectar de todos los relays
    func desconectar() {
        // Cerrar todas las suscripciones activas
        // En una implementación completa, mantener un registro de suscripciones

        // El manager no tiene método directo para desconectar todos,
        // así que esto sería un placeholder
        print("Desconectado de relays Nostr")
    }
}

// Implementación básica de NostrIdentityBridge
class NostrIdentityBridge {
    private let keychain: KeychainManagerProtocol

    init(keychain: KeychainManagerProtocol) {
        self.keychain = keychain
    }

    // Obtener la identidad Nostr actual (clave pública)
    func getCurrentNostrIdentity() throws -> String {
        // En una implementación real, esto obtendría la clave pública Nostr
        // Por ahora, devolver un placeholder
        return "npub1..."  // Placeholder para clave pública bech32
    }
}

// Extensión del delegate para eventos Nostr
extension MiDelegate {
    // Los eventos Nostr se manejarían a través del NostrRelayManager
    // y sus callbacks específicos, no a través del BitDelegate principal
}

// Ejemplo de uso en una aplicación de chat global
class GlobalChatController {
    private let nostrController: NostrController

    init(nostrController: NostrController) {
        self.nostrController = nostrController
    }

    func iniciarChatGlobal() {
        // Configurar Nostr
        nostrController.configurarNostr()

        // Seguir algunos topics populares
        nostrController.seguirTopic("nostr")
        nostrController.seguirTopic("bitcoin")

        // Publicar mensaje de bienvenida
        nostrController.publicarMensaje(
            "¡Hola desde Bit! Una app de mensajería P2P segura.",
            etiquetas: ["bitchat", "p2p", "privacy"]
        )
    }

    func publicarMensaje(_ mensaje: String) {
        nostrController.publicarMensaje(mensaje)
    }

    func seguirUsuario(_ pubKey: String) {
        nostrController.seguirAutor(hexPubKey: pubKey)
    }

    func enviarDM(_ mensaje: String, a pubKey: String) {
        nostrController.enviarMensajePrivado(mensaje, a: pubKey)
    }
}

// Funciones Avanzadas de NoiseEncryptionService

// 1. Limpiar Estado Efímero para Pánico
// Borra sesiones activas sin afectar identidad persistente
func limpiarEstadoEfimeroParaPanico() {
    noiseService?.clearEphemeralStateForPanic()
    print("Estado efímero de Noise limpiado")
}

// 2. Limpiar Identidad Persistente
// Borra claves de identidad almacenadas (usar con precaución)
func limpiarIdentidadPersistente() {
    noiseService?.clearPersistentIdentity()
    print("Identidad persistente de Noise limpiada")
}

// 3. Verificar si hay Sesión Establecida
// Comprueba si hay cifrado end-to-end activo con un peer
func tieneSesionEstablecida(peerID: PeerID) -> Bool {
    return noiseService?.hasEstablishedSession(with: peerID) ?? false
}

// 4. Verificar si hay Sesión (Incluyendo Handshake)
// Comprueba si hay cualquier sesión (activa o en progreso) con un peer
func tieneSesion(peerID: PeerID) -> Bool {
    return noiseService?.hasSession(with: peerID) ?? false
}

## Notas Adicionales

- Nostr usa un modelo de publicación-suscripción similar a Twitter
- Los mensajes son públicos por defecto; usa encriptación para privacidad
- Múltiples relays proporcionan redundancia y resistencia a fallos
- Considera la carga de los relays al suscribirte a muchos eventos
- Los NIP (Nostr Improvement Proposals) definen estándares adicionales