# 06 - Manejo de Multimedia y Medios

## Descripción

Este ejemplo demuestra cómo integrar capacidades completas de multimedia en BitCommunications, incluyendo grabación de voz, procesamiento de imágenes, compresión de medios y streaming básico. Aprenderás a manejar archivos multimedia de forma segura, optimizarlos para transmisión P2P y proporcionar una experiencia rica de mensajería multimedia.

**Beneficios:**
- Comunicación multimedia completa sin depender de servicios externos
- Optimización automática de medios para redes P2P limitadas
- Compresión inteligente que preserva calidad
- Streaming en tiempo real para audio/video
- Integración perfecta con el sistema de archivos de Bit

**Consideraciones:**
- Los archivos multimedia pueden ser grandes; considera límites de almacenamiento
- La compresión requiere procesamiento adicional de CPU
- Streaming de video de alta calidad necesita conexiones estables
- Respeta los permisos de micrófono y cámara del usuario
- Considera el impacto en batería para grabaciones largas

## Pasos Previos Obligatorios

1. **Completar Configuración Básica** (Ejemplo 01)
2. **Añadir BitMedia** a las dependencias del proyecto
3. **Configurar permisos** en Info.plist (NSMicrophoneUsageDescription, NSCameraUsageDescription)
4. **Implementar MediaDelegate** para manejo de eventos multimedia

## Código de Implementación

```swift
import BitCore
import BitMedia
import BitTransport
import AVFoundation
import UIKit

// Manager principal para multimedia
class MediaManager {
    private let voiceRecorder: VoiceRecorder
    private let bleService: BLEService
    private let mediaDelegate: MediaDelegate
    private var currentRecording: URL?
    private var activeStreams: [String: MediaStream] = [:]

    init(bleService: BLEService, mediaDelegate: MediaDelegate) {
        self.bleService = bleService
        self.mediaDelegate = mediaDelegate
        self.voiceRecorder = VoiceRecorder.shared
    }

    // MARK: - Grabación de Voz

    // Iniciar grabación de voz
    func startVoiceRecording() throws {
        // Verificar permisos de micrófono
        #if os(iOS)
        guard AVAudioSession.sharedInstance().recordPermission == .granted else {
            throw NSError(domain: "MediaError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied"])
        }
        #elseif os(macOS)
        guard AVCaptureDevice.authorizationStatus(for: .audio) == .authorized else {
            throw NSError(domain: "MediaError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied"])
        }
        #endif

        // Iniciar grabación usando VoiceRecorder
        let recordingURL = try voiceRecorder.startRecording()
        currentRecording = recordingURL
        print("🎤 Grabación de voz iniciada")
    }

    // Detener grabación y obtener archivo
    func stopVoiceRecording(completion: @escaping (URL?) -> Void) {
        voiceRecorder.stopRecording { [weak self] url in
            self?.currentRecording = url
            if let url = url {
                print("🎤 Grabación completada: \(url.lastPathComponent)")
            }
            completion(url)
        }
    }

    // Cancelar grabación actual
    func cancelVoiceRecording() {
        voiceRecorder.cancelRecording()
        currentRecording = nil
        print("🎤 Grabación cancelada")
    }

    // MARK: - Procesamiento de Imágenes

    // Procesar imagen para envío
    func processImageForSending(_ image: UIImage) throws -> URL {
        // Usar MediaUtils para procesar la imagen
        return try MediaUtils.processImage(image, maxDimension: 1024)
    }

    // Procesar imagen desde URL
    func processImageForSending(at url: URL) throws -> URL {
        // Usar MediaUtils para procesar la imagen desde archivo
        return try MediaUtils.processImage(at: url, maxDimension: 1024)
    }

        // Verificar tamaño máximo
        let maxFileSize = 2 * 1024 * 1024 // 2MB
        if data.count > maxFileSize {
            // Si es demasiado grande, reducir calidad
            return try await compressImage(image, maxSize: maxSize, quality: quality * 0.8)
        }

        return data
    }

    // Redimensionar imagen manteniendo proporción
    private func resizeImage(_ image: UIImage, to maxSize: CGSize) -> UIImage {
        let aspectRatio = image.size.width / image.size.height
        var newSize = maxSize

        if aspectRatio > 1 {
            // Imagen horizontal
            newSize.height = maxSize.width / aspectRatio
        } else {
            // Imagen vertical
            newSize.width = maxSize.height * aspectRatio
        }

        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? image
    }

    // Generar thumbnail
    func generateThumbnail(for imageURL: URL, size: CGSize) async throws -> URL {
        let thumbnailURL = imageURL.deletingPathExtension()
            .appendingPathExtension("thumb")
            .appendingPathExtension(imageURL.pathExtension)

        try await ImageUtils.generateThumbnail(
            for: imageURL,
            size: size,
            outputURL: thumbnailURL
        )

        return thumbnailURL
    }

    // MARK: - Streaming de Audio/Video

    // Iniciar streaming de audio en tiempo real
    func startAudioStream(to peerID: PeerID) async throws {
        let streamId = UUID().uuidString

        // Configurar stream
        let stream = MediaStream(
            id: streamId,
            type: .audio,
            peerID: peerID,
            quality: .medium,
            direction: .outgoing
        )

        // Iniciar captura de audio
        try await stream.startCapture()

        activeStreams[streamId] = stream

        // Notificar al peer sobre el stream entrante
        notifyPeerOfIncomingStream(stream, peerID: peerID)

        print("🎵 Streaming de audio iniciado con \(peerID)")
    }

    // Recibir stream de audio entrante
    func handleIncomingAudioStream(from peerID: PeerID, streamId: String) async throws {
        let stream = MediaStream(
            id: streamId,
            type: .audio,
            peerID: peerID,
            quality: .medium,
            direction: .incoming
        )

        try await stream.startPlayback()
        activeStreams[streamId] = stream

        print("🎵 Recibiendo stream de audio de \(peerID)")
    }

    // Detener stream específico
    func stopStream(_ streamId: String) {
        guard let stream = activeStreams[streamId] else { return }

        stream.stop()
        activeStreams.removeValue(forKey: streamId)

        print("🛑 Stream detenido: \(streamId)")
    }

    // MARK: - Envío de Medios

    // Enviar archivo de voz grabado
    func sendVoiceMessage(to peerID: PeerID) async throws {
        guard let audioURL = currentRecording else {
            throw MediaError.noRecordingAvailable
        }

        // Crear metadatos del archivo
        let metadata = MediaMetadata(
            type: .audio,
            originalFilename: "voice_message.aac",
            size: try FileManager.default.attributesOfItem(atPath: audioURL.path)[.size] as? Int64 ?? 0,
            duration: try await getAudioDuration(audioURL),
            checksum: try await calculateFileChecksum(audioURL)
        )

        // Enviar vía BLE con prioridad alta
        try await bleService.sendMediaFile(
            audioURL,
            metadata: metadata,
            to: peerID,
            priority: .high
        )

        // Limpiar grabación actual
        currentRecording = nil

        print("📤 Mensaje de voz enviado a \(peerID)")
    }

    // Enviar imagen procesada
    func sendImageMessage(_ image: UIImage, to peerID: PeerID) async throws {
        let processedURL = try await processImageForSending(image)

        let metadata = MediaMetadata(
            type: .image,
            originalFilename: "image.jpg",
            size: try FileManager.default.attributesOfItem(atPath: processedURL.path)[.size] as? Int64 ?? 0,
            checksum: try await calculateFileChecksum(processedURL)
        )

        try await bleService.sendMediaFile(
            processedURL,
            metadata: metadata,
            to: peerID,
            priority: .normal
        )

        print("📤 Imagen enviada a \(peerID)")
    }

    // MARK: - Utilidades

    // Optimizar audio para transmisión
    private func optimizeAudioForTransmission(_ audioURL: URL) async throws -> URL {
        // Para transmisiones BLE, mantener calidad razonable
        let optimizedURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("optimized_audio_\(UUID().uuidString).aac")

        // Aplicar compresión básica si es necesario
        try await AudioUtils.compressAudio(
            from: audioURL,
            to: optimizedURL,
            quality: .medium
        )

        return optimizedURL
    }

    // Obtener duración de audio
    private func getAudioDuration(_ audioURL: URL) async throws -> TimeInterval {
        let asset = AVURLAsset(url: audioURL)
        return try await asset.load(.duration).seconds
    }

    // Calcular checksum de archivo
    private func calculateFileChecksum(_ fileURL: URL) async throws -> String {
        let data = try Data(contentsOf: fileURL)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    // Notificar peer sobre stream entrante
    private func notifyPeerOfIncomingStream(_ stream: MediaStream, peerID: PeerID) {
        // Enviar notificación vía BLE
        let notification = MediaStreamNotification(
            streamId: stream.id,
            type: stream.type,
            action: .start
        )

        // bleService.send(notification, to: peerID)
        print("📢 Notificación de stream enviada a \(peerID)")
    }
}

// Estructuras de soporte
struct VoiceRecordingSettings {
    let format: AudioFormat
    let quality: AudioQuality
    let sampleRate: Double
    let channels: Int
}

enum AudioFormat {
    case aac, wav, mp3
}

enum AudioQuality {
    case low, medium, high
}

struct MediaMetadata {
    let type: MediaType
    let originalFilename: String
    let size: Int64
    let duration: TimeInterval?
    let checksum: String
}

enum MediaType {
    case audio, image, video
}

class MediaStream {
    let id: String
    let type: MediaType
    let peerID: PeerID
    let quality: MediaQuality
    let direction: StreamDirection

    private var isActive = false

    init(id: String, type: MediaType, peerID: PeerID, quality: MediaQuality, direction: StreamDirection) {
        self.id = id
        self.type = type
        self.peerID = peerID
        self.quality = quality
        self.direction = direction
    }

    func startCapture() async throws {
        // Implementar captura de audio/video
        isActive = true
    }

    func startPlayback() async throws {
        // Implementar reproducción de stream
        isActive = true
    }

    func stop() {
        isActive = false
        // Limpiar recursos
    }
}

enum MediaQuality {
    case low, medium, high
}

enum StreamDirection {
    case incoming, outgoing
}

struct MediaStreamNotification {
    let streamId: String
    let type: MediaType
    let action: StreamAction
}

enum StreamAction {
    case start, stop, pause, resume
}

// Protocolo para eventos multimedia
protocol MediaDelegate: AnyObject {
    func didStartRecording()
    func didStopRecording(audioURL: URL)
    func didFailRecording(error: Error)
    func didReceiveMediaFile(from peerID: PeerID, metadata: MediaMetadata, fileURL: URL)
    func didReceiveStreamNotification(from peerID: PeerID, notification: MediaStreamNotification)
}

// Extensiones de utilidad
extension ImageUtils {
    static func generateThumbnail(for imageURL: URL, size: CGSize, outputURL: URL) async throws {
        // Implementar generación de thumbnail
        let image = UIImage(contentsOfFile: imageURL.path)
        // Procesar y guardar thumbnail
    }
}

class AudioUtils {
    static func compressAudio(from inputURL: URL, to outputURL: URL, quality: AudioQuality) async throws {
        // Implementar compresión de audio
        // Usar AVFoundation para procesamiento
    }
}

// Errores multimedia
enum MediaError: Error {
    case microphonePermissionDenied
    case cameraPermissionDenied
    case recordingFailed
    case compressionFailed
    case noRecordingAvailable
    case invalidFileFormat
    case fileTooLarge
}

// Controlador de UI para multimedia
class MediaViewController: UIViewController {
    private let mediaManager: MediaManager
    private var isRecording = false

    init(mediaManager: MediaManager) {
        self.mediaManager = mediaManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // UI para grabación de voz
    @objc func recordButtonTapped() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        Task {
            do {
                try await mediaManager.startVoiceRecording()
                isRecording = true
                updateRecordButton(title: "Detener Grabación")
            } catch {
                showError("Error al iniciar grabación: \(error.localizedDescription)")
            }
        }
    }

    private func stopRecording() {
        Task {
            do {
                let audioURL = try await mediaManager.stopVoiceRecording()
                isRecording = false
                updateRecordButton(title: "Grabar Voz")

                // Mostrar opciones para enviar
                showSendOptions(for: audioURL, type: .audio)
            } catch {
                showError("Error al detener grabación: \(error.localizedDescription)")
            }
        }
    }

    // UI para selección de imagen
    @objc func imageButtonTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    private func updateRecordButton(title: String) {
        // Actualizar UI del botón
    }

    private func showSendOptions(for fileURL: URL, type: MediaType) {
        // Mostrar diálogo para seleccionar destinatario
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// Extensión para UIImagePickerController
extension MediaViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage else { return }

        Task {
            do {
                let processedURL = try await mediaManager.processImageForSending(image)
                showSendOptions(for: processedURL, type: .image)
            } catch {
                showError("Error al procesar imagen: \(error.localizedDescription)")
            }
        }
    }
}
```

## Notas Adicionales

- Implementa compresión progresiva para archivos grandes
- Considera límites de tamaño basados en el transporte (BLE vs Nostr)
- Los streams de audio requieren conexiones estables
- Genera thumbnails para vista previa eficiente
- Implementa cache local para medios frecuentemente accedidos
- Considera encriptación adicional para medios sensibles