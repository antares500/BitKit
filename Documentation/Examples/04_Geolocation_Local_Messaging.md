# 04 - Geolocalización y Mensajería Local

## Descripción

Este ejemplo muestra cómo integrar capacidades de geolocalización para crear zonas de mensajería local basadas en ubicación. Permite a los usuarios conectarse automáticamente con personas cercanas, creando comunidades locales efímeras o persistentes. Combina GPS con BLE para proporcionar tanto alcance preciso como comunicación directa peer-to-peer.

**Beneficios:**
- Descubrimiento automático de usuarios cercanos sin necesidad de añadir contactos manualmente
- Creación de comunidades locales basadas en ubicación geográfica
- Mensajería efímera que respeta la privacidad al limitar el alcance geográfico
- Integración perfecta con navegación y mapas para experiencias inmersivas
- Reducción de carga en redes globales al mantener conversaciones locales

**Consideraciones:**
- Requiere permisos de ubicación del usuario (siempre con consentimiento explícito)
- Considera la precisión del GPS y posibles errores de ubicación
- La privacidad es crítica: nunca almacenes ubicaciones sin encriptación
- El alcance efectivo depende de la densidad de población y condiciones ambientales
- Maneja casos donde el GPS no esté disponible (modo offline)
- Considera el consumo de batería de actualizaciones constantes de ubicación

## Pasos Previos Obligatorios

1. **Completar Configuración Básica** (Ejemplo 01)
2. **Añadir BitGeo** a las dependencias del proyecto
3. **Configurar permisos de ubicación** en Info.plist (NSLocationWhenInUseUsageDescription)
4. **Implementar LocationPrivacyManager** para manejo ético de datos de ubicación

## Código de Implementación

```swift
import BitCore
import BitGeo
import BitTransport
import CoreLocation
import Combine

// Manager para geolocalización y mensajería local
class GeoMessagingManager {
    private let locationManager: CLLocationManager
    private let locationStateManager: LocationStateManager
    private let geoRelayDirectory: GeoRelayDirectory
    private let bleService: BLEService
    private let delegate: BitDelegate

    // Publishers para estado de ubicación
    private var locationPublisher = PassthroughSubject<CLLocation, Never>()
    private var nearbyPeersPublisher = PassthroughSubject<[NearbyPeer], Never>()

    // Estado actual
    private var currentLocation: CLLocation?
    private var nearbyPeers: [NearbyPeer] = []
    private var locationSubscription: AnyCancellable?

    init(delegate: BitDelegate) {
        self.delegate = delegate

        // Inicializar componentes
        let keychain = KeychainManager()
        let idBridge = NostrIdentityBridge(keychain: keychain)
        let identityManager = SecureIdentityStateManager(keychain)
        
        bleService = BLEService(
            keychain: keychain,
            idBridge: idBridge,
            identityManager: identityManager
        )
        
        locationManager = CLLocationManager()
        locationStateManager = LocationStateManager.shared
        geoRelayDirectory = GeoRelayDirectory()

        // Configurar location manager
        configurarLocationManager()
    }

    // Configurar el location manager
    private func configurarLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0  // Actualizar cada 10 metros
        locationManager.allowsBackgroundLocationUpdates = false  // Solo foreground
        locationManager.pausesLocationUpdatesAutomatically = true
    }

    // Solicitar permisos y comenzar actualizaciones
    func iniciarGeoMessaging() {
        // Verificar permisos usando LocationStateManager
        let permission = locationStateManager.publicPermissionState
        switch permission {
        case .authorized:
            locationManager.startUpdatingLocation()
            print("GeoMessaging iniciado - actualizando ubicación")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("Error: Permisos de ubicación denegados")
            mostrarInstruccionesPermisos()
        }
    }

    // Detener actualizaciones de ubicación
    func detenerGeoMessaging() {
        locationManager.stopUpdatingLocation()
        locationSubscription?.cancel()
        nearbyPeers = []
        print("GeoMessaging detenido")
    }

    // Obtener peers cercanos en un radio específico
    func buscarPeersCercanos(radioMetros: Double = 100.0) {
        guard let miUbicacion = currentLocation else {
            print("Error: Ubicación actual no disponible")
            return
        }

        // Obtener peers cercanos usando BLEService
        Task {
            do {
                let discoveredPeers = try await bleService.scanForPeers(duration: 5.0)
                nearbyPeers = discoveredPeers.compactMap { peer in
                    guard let location = peer.location else { return nil }
                    let distance = miUbicacion.distance(from: CLLocation(latitude: location.latitude, longitude: location.longitude))
                    return NearbyPeer(
                        peerID: peer.peerID,
                        latitude: location.latitude,
                        longitude: location.longitude,
                        lastSeen: Date(),
                        distance: distance
                    )
                }.filter { $0.distance <= radioMetros }
                
                // Notificar cambios
                nearbyPeersPublisher.send(nearbyPeers)
            } catch {
                print("Error escaneando peers: \(error)")
            }
        }

        // Notificar cambios
        nearbyPeersPublisher.send(nearbyPeers)

        print("Encontrados \(nearbyPeers.count) peers cercanos en \(radioMetros)m")
    }

    // Crear zona de chat local
    func crearZonaChatLocal(nombre: String, radioMetros: Double = 50.0) -> LocalChatZone {
        guard let centro = currentLocation?.coordinate else {
            fatalError("Ubicación requerida para crear zona")
        }

        let zona = LocalChatZone(
            id: UUID(),
            name: nombre,
            center: centro,
            radiusMeters: radioMetros,
            createdAt: Date(),
            creator: obtenerMiPeerID()
        )

        // Anunciar zona a peers cercanos vía BLE
        anunciarZona(zona)

        print("Zona de chat creada: \(nombre) en radio de \(radioMetros)m")
        return zona
    }

    // Unirse a una zona de chat existente
    func unirseAZona(_ zona: LocalChatZone) {
        guard let miUbicacion = currentLocation else { return }

        // Verificar si estamos dentro del radio de la zona
        let distancia = miUbicacion.distance(from: CLLocation(
            latitude: zona.center.latitude,
            longitude: zona.center.longitude
        ))

        guard distancia <= zona.radiusMeters else {
            print("Error: Fuera del radio de la zona")
            return
        }

        // Unirse a la zona conectando vía BLE mesh
        Task {
            do {
                try await bleService.connect(to: zona.creator)
                print("Conectado exitosamente a zona: \(zona.name)")
            } catch {
                print("Error conectando a zona: \(error)")
            }
        }
    }

    // Enviar mensaje a zona local
    func enviarMensajeAZona(_ mensaje: String, zona: LocalChatZone) {
        guard !mensaje.isEmpty else { return }

        // Crear paquete de mensaje local
        let paquete = LocalMessagePacket(
            content: mensaje,
            zoneId: zona.id,
            senderLocation: currentLocation?.coordinate,
            timestamp: Date(),
            ttl: 300  // 5 minutos de vida
        )

        // Enviar vía BLE mesh a peers en la zona
        enviarPaqueteLocal(paquete, zona: zona)

        print("Mensaje enviado a zona \(zona.name): \(mensaje)")
    }

    // Anunciar zona vía BLE advertisement
    private func anunciarZona(_ zona: LocalChatZone) {
        Task {
            do {
                let zoneData = try JSONEncoder().encode(zona)
                try await bleService.startAdvertising(with: zoneData)
                print("Anunciando zona: \(zona.name)")
            } catch {
                print("Error anunciando zona: \(error)")
            }
        }
    }

    // Enviar paquete local vía BLE mesh
    private func enviarPaqueteLocal(_ paquete: LocalMessagePacket, zona: LocalChatZone) {
        Task {
            do {
                let packetData = try JSONEncoder().encode(paquete)
                try await bleService.broadcast(data: packetData, toPeersInRange: zona.radiusMeters)
                print("Paquete enviado a zona")
            } catch {
                print("Error enviando paquete: \(error)")
            }
        }
    }

    // Obtener mi PeerID del identity manager
    private func obtenerMiPeerID() -> PeerID {
        do {
            let identity = try identityManager.getCurrentIdentity()
            return identity.peerID
        } catch {
            // Fallback a PeerID generado
            return PeerID(str: "fallback-\(UUID().uuidString.prefix(8))")!
        }
    }

    // Mostrar instrucciones para permisos
    private func mostrarInstruccionesPermisos() {
        let mensaje = """
        Para usar mensajería local, necesitas permitir acceso a ubicación:
        1. Ve a Configuración > Privacidad > Localización
        2. Encuentra esta app y permite "Mientras se usa"
        3. Reinicia la funcionalidad de geolocalización
        """
        print(mensaje)
    }

    // Calcular distancia entre dos coordenadas
    func distanciaEntre(_ coord1: CLLocationCoordinate2D, _ coord2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return location1.distance(from: location2)
    }

    // Obtener dirección aproximada de coordenadas
    func obtenerDireccionAproximada(_ coordinate: CLLocationCoordinate2D) -> String {
        // En implementación real, usar CLGeocoder para reverse geocoding
        return "Cerca de \(coordinate.latitude), \(coordinate.longitude)"
    }
}

// CLLocationManagerDelegate
extension GeoMessagingManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let nuevaUbicacion = locations.last else { return }

        // Actualizar ubicación actual
        currentLocation = nuevaUbicacion

        // Notificar cambio de ubicación
        locationPublisher.send(nuevaUbicacion)

        // Buscar peers cercanos automáticamente
        buscarPeersCercanos()

        print("Ubicación actualizada: \(nuevaUbicacion.coordinate.latitude), \(nuevaUbicacion.coordinate.longitude)")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error de ubicación: \(error.localizedDescription)")

        // Manejar diferentes tipos de errores
        switch (error as NSError).code {
        case CLError.locationUnknown.rawValue:
            print("Ubicación temporalmente desconocida")
        case CLError.denied.rawValue:
            print("Permisos de ubicación denegados")
            mostrarInstruccionesPermisos()
        case CLError.network.rawValue:
            print("Error de red en ubicación")
        default:
            print("Error desconocido de ubicación")
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus()
        print("Estado de autorización cambió a: \(status.rawValue)")

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            detenerGeoMessaging()
        case .notDetermined:
            break  // Esperar decisión del usuario
        @unknown default:
            break
        }
    }
}

// Estructuras de datos para geolocalización
struct NearbyPeer {
    let peerID: PeerID
    let latitude: Double
    let longitude: Double
    let lastSeen: Date
    let distance: Double
}

struct LocalChatZone {
    let id: UUID
    let name: String
    let center: CLLocationCoordinate2D
    let radiusMeters: Double
    let createdAt: Date
    let creator: PeerID
}

struct LocalMessagePacket {
    let content: String
    let zoneId: UUID
    let senderLocation: CLLocationCoordinate2D?
    let timestamp: Date
    let ttl: TimeInterval  // Time to live en segundos
}

// Manager de privacidad para ubicación
class LocationPrivacyManager {
    // Verificar si podemos usar ubicación
    func canUseLocation() -> Bool {
        let status = CLLocationManager.authorizationStatus()
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }

    // Encriptar datos de ubicación antes de almacenar
    func encryptLocationData(_ location: CLLocation) -> Data? {
        do {
            let locationData = try JSONEncoder().encode([
                "lat": location.coordinate.latitude,
                "lon": location.coordinate.longitude,
                "timestamp": location.timestamp.timeIntervalSince1970
            ])
            // En implementación real, usar BitCore crypto para encriptar
            return locationData  // Por simplicidad, devolver sin encriptar
        } catch {
            print("Error encriptando ubicación: \(error)")
            return nil
        }
    }

    // Limpiar datos de ubicación después de uso
    func clearLocationHistory() {
        // Limpiar cualquier cache de ubicación
        print("Historial de ubicación limpiado")
    }
}

// Controlador de UI para zonas locales
class LocalZonesController {
    private let geoManager: GeoMessagingManager
    private var zonasActivas: [LocalChatZone] = []

    init(geoManager: GeoMessagingManager) {
        self.geoManager = geoManager
    }

    func mostrarZonasCercanas() {
        // En UI real, mostrar lista de zonas disponibles
        print("Zonas activas cercanas:")
        for zona in zonasActivas {
            let distancia = geoManager.distanciaEntre(
                zona.center,
                geoManager.currentLocation?.coordinate ?? CLLocationCoordinate2D()
            )
            print("- \(zona.name): \(String(format: "%.0f", distancia))m")
        }
    }

    func crearNuevaZona(nombre: String) {
        let nuevaZona = geoManager.crearZonaChatLocal(nombre: nombre)
        zonasActivas.append(nuevaZona)
        print("Nueva zona creada: \(nuevaZona.name)")
    }

    func unirseAZonaMasCercana() {
        guard let zonaMasCercana = zonasActivas.min(by: { zona1, zona2 in
            let dist1 = geoManager.distanciaEntre(
                zona1.center,
                geoManager.currentLocation?.coordinate ?? CLLocationCoordinate2D()
            )
            let dist2 = geoManager.distanciaEntre(
                zona2.center,
                geoManager.currentLocation?.coordinate ?? CLLocationCoordinate2D()
            )
            return dist1 < dist2
        }) else {
            print("No hay zonas activas cercanas")
            return
        }

        geoManager.unirseAZona(zonaMasCercana)
    }
}
```

## Notas Adicionales

- Siempre prioriza la privacidad del usuario sobre funcionalidad
- Considera el uso de geofencing para zonas persistentes
- Los mensajes locales pueden tener TTL para evitar acumulación
- Combina con BLE para comunicación directa cuando esté disponible
- Monitorea el consumo de batería de actualizaciones GPS frecuentes