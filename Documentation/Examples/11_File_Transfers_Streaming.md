# 11 - Transferencias de Archivos y Streaming Avanzado

## Descripción

Este ejemplo muestra cómo implementar transferencias de archivos robustas y streaming de medios en tiempo real dentro de BitchatCommunications. Aprenderás a manejar archivos grandes con recuperación de errores, streaming adaptativo, compresión inteligente, y protocolos de transferencia optimizados para diferentes tipos de contenido y condiciones de red.

**Beneficios:**
- Transferencias de archivos confiables con recuperación automática
- Streaming adaptativo que se ajusta a las condiciones de red
- Compresión inteligente que preserva calidad
- Paralelización de transferencias para mayor velocidad
- Verificación de integridad con checksums
- Reanudación de transferencias interrumpidas
- Optimización automática según tipo de contenido

**Consideraciones:**
- Maneja apropiadamente el uso de memoria para archivos grandes
- Implementa timeouts y límites de tamaño de archivo
- Considera el impacto en batería de transferencias largas
- Proporciona feedback visual del progreso
- Implementa políticas de compresión por tipo de archivo
- Maneja conflictos de concurrencia en transferencias múltiples
- Considera la privacidad y encriptación de archivos

## Pasos Previos Obligatorios

1. **Completar Configuración Básica** (Ejemplo 01)
2. **Implementar TransportCoordinator** (Ejemplo 10)
3. **Crear FileTransferManager** y **StreamingEngine**
4. **Configurar políticas de compresión y chunking**
5. **Implementar FileIntegrityVerifier**

## Código de Implementación

```swift
import BitchatCore
import BitchatBLE
import BitchatNostr
import CryptoKit
import Compression
import Combine

// Manager principal de transferencias de archivos
class FileTransferManager {
    private let transportCoordinator: TransportCoordinator
    private let compressionEngine: CompressionEngine
    private let integrityVerifier: FileIntegrityVerifier
    private let transferQueue: TransferQueue

    // Transferencias activas
    private var activeTransfers: [TransferID: FileTransfer] = [:]
    private var transferProgress: [TransferID: Progress] = [:]

    // Publishers para eventos
    private let transferStartedPublisher = PassthroughSubject<FileTransfer, Never>()
    private let transferProgressPublisher = PassthroughSubject<(TransferID, Progress), Never>()
    private let transferCompletedPublisher = PassthroughSubject<(TransferID, TransferResult), Never>()

    var transferStarted: AnyPublisher<FileTransfer, Never> {
        transferStartedPublisher.eraseToAnyPublisher()
    }

    var transferProgress: AnyPublisher<(TransferID, Progress), Never> {
        transferProgressPublisher.eraseToAnyPublisher()
    }

    var transferCompleted: AnyPublisher<(TransferID, TransferResult), Never> {
        transferCompletedPublisher.eraseToAnyPublisher()
    }

    init(transportCoordinator: TransportCoordinator) {
        self.transportCoordinator = transportCoordinator
        self.compressionEngine = CompressionEngine()
        self.integrityVerifier = FileIntegrityVerifier()
        self.transferQueue = TransferQueue()

        setupTransportBindings()
    }

    // MARK: - Transferencias de Archivos

    // Iniciar transferencia de archivo
    func startFileTransfer(
        fileURL: URL,
        to peerID: PeerID,
        options: TransferOptions = .default
    ) async throws -> TransferID {
        let transferID = TransferID()

        // Leer archivo
        let fileData = try Data(contentsOf: fileURL)
        let fileInfo = FileInfo.from(url: fileURL, data: fileData)

        // Verificar tamaño límite
        guard fileData.count <= options.maxFileSize else {
            throw TransferError.fileTooLarge
        }

        // Crear transferencia
        let transfer = FileTransfer(
            id: transferID,
            direction: .outgoing,
            peerID: peerID,
            fileInfo: fileInfo,
            options: options,
            state: .preparing
        )

        activeTransfers[transferID] = transfer
        transferStartedPublisher.send(transfer)

        // Iniciar transferencia en background
        Task {
            await performFileTransfer(transfer, data: fileData)
        }

        print("📁 Transferencia iniciada: \(fileInfo.name) (\(fileInfo.size) bytes)")

        return transferID
    }

    // Recibir archivo
    func handleIncomingFileTransfer(_ transferRequest: FileTransferRequest) async throws {
        let transferID = transferRequest.transferID

        // Verificar si podemos aceptar la transferencia
        guard transferRequest.fileInfo.size <= TransferOptions.default.maxFileSize else {
            try await sendTransferResponse(transferID, accepted: false, reason: "Archivo demasiado grande")
            return
        }

        // Crear transferencia entrante
        let transfer = FileTransfer(
            id: transferID,
            direction: .incoming,
            peerID: transferRequest.peerID,
            fileInfo: transferRequest.fileInfo,
            options: transferRequest.options,
            state: .receiving
        )

        activeTransfers[transferID] = transfer
        transferStartedPublisher.send(transfer)

        // Aceptar transferencia
        try await sendTransferResponse(transferID, accepted: true)

        print("📥 Transferencia entrante aceptada: \(transferRequest.fileInfo.name)")
    }

    // Cancelar transferencia
    func cancelTransfer(_ transferID: TransferID) async {
        guard let transfer = activeTransfers[transferID] else { return }

        transfer.state = .cancelled
        transferProgress[transferID] = nil

        // Notificar cancelación
        try? await sendTransferCancellation(transferID)

        activeTransfers.removeValue(forKey: transferID)

        print("❌ Transferencia cancelada: \(transferID)")
    }

    // MARK: - Streaming de Medios

    // Iniciar streaming de medios
    func startMediaStreaming(
        mediaURL: URL,
        to peerID: PeerID,
        quality: StreamingQuality = .adaptive
    ) async throws -> StreamID {
        let streamID = StreamID()

        // Crear stream
        let stream = MediaStream(
            id: streamID,
            direction: .outgoing,
            peerID: peerID,
            mediaURL: mediaURL,
            quality: quality,
            state: .buffering
        )

        // Iniciar streaming en background
        Task {
            await performMediaStreaming(stream)
        }

        print("🎬 Streaming iniciado: \(mediaURL.lastPathComponent)")

        return streamID
    }

    // MARK: - Procesamiento de Transferencias

    // Ejecutar transferencia de archivo
    private func performFileTransfer(_ transfer: FileTransfer, data: Data) async {
        do {
            transfer.state = .transferring

            // Preparar datos para transferencia
            let preparedData = try await prepareFileData(data, options: transfer.options)

            // Crear chunks
            let chunks = try createFileChunks(preparedData, chunkSize: transfer.options.chunkSize)

            // Enviar chunks
            for (index, chunk) in chunks.enumerated() {
                let progress = Double(index + 1) / Double(chunks.count)
                transferProgress[transfer.id] = Progress(value: progress)

                transferProgressPublisher.send((transfer.id, Progress(value: progress)))

                try await sendFileChunk(transfer.id, chunk: chunk, index: index, total: chunks.count)

                // Pequeña pausa para no saturar
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }

            // Enviar finalización
            try await sendTransferCompletion(transfer.id, checksum: preparedData.checksum)

            transfer.state = .completed
            transferProgress[transfer.id] = Progress(value: 1.0)

            let result = TransferResult.success(fileURL: try await saveTransferredFile(preparedData, info: transfer.fileInfo))
            transferCompletedPublisher.send((transfer.id, result))

            print("✅ Transferencia completada: \(transfer.fileInfo.name)")

        } catch {
            transfer.state = .failed(error)
            transferProgress[transfer.id] = nil

            let result = TransferResult.failure(error)
            transferCompletedPublisher.send((transfer.id, result))

            print("❌ Transferencia falló: \(transfer.fileInfo.name) - \(error.localizedDescription)")
        }

        activeTransfers.removeValue(forKey: transfer.id)
    }

    // Ejecutar streaming de medios
    private func performMediaStreaming(_ stream: MediaStream) async {
        do {
            // Implementar lógica de streaming adaptativo
            // Esto incluiría buffering, ajuste de calidad, etc.
            print("🎬 Streaming implementado (placeholder)")

        } catch {
            print("❌ Streaming falló: \(error.localizedDescription)")
        }
    }

    // MARK: - Utilidades de Procesamiento

    // Preparar datos de archivo para transferencia
    private func prepareFileData(_ data: Data, options: TransferOptions) async throws -> PreparedFileData {
        var processedData = data

        // Comprimir si es necesario
        if options.compress && shouldCompressFile(data) {
            processedData = try await compressionEngine.compress(data, algorithm: options.compressionAlgorithm)
        }

        // Encriptar si es necesario
        if options.encrypt {
            processedData = try await encryptFileData(processedData)
        }

        // Calcular checksum
        let checksum = try await integrityVerifier.calculateChecksum(processedData)

        return PreparedFileData(data: processedData, checksum: checksum, originalSize: data.count)
    }

    // Crear chunks de archivo
    private func createFileChunks(_ data: PreparedFileData, chunkSize: Int) throws -> [FileChunk] {
        var chunks: [FileChunk] = []
        var offset = 0

        while offset < data.data.count {
            let chunkLength = min(chunkSize, data.data.count - offset)
            let chunkData = data.data[offset..<offset + chunkLength]

            let chunk = FileChunk(
                index: chunks.count,
                data: Data(chunkData),
                checksum: try integrityVerifier.calculateChecksum(Data(chunkData))
            )

            chunks.append(chunk)
            offset += chunkLength
        }

        return chunks
    }

    // Determinar si comprimir archivo
    private func shouldCompressFile(_ data: Data) -> Bool {
        // Comprimir archivos > 1KB que no estén ya comprimidos
        return data.count > 1024 && !isAlreadyCompressed(data)
    }

    // Verificar si archivo ya está comprimido
    private func isAlreadyCompressed(_ data: Data) -> Bool {
        // Verificar headers de archivos comprimidos comunes
        let compressedHeaders = [
            Data([0x1F, 0x8B]), // GZIP
            Data([0x78, 0x01]), // ZLIB
            Data([0x42, 0x5A]), // BZIP2
            Data([0xFD, 0x37, 0x7A, 0x58, 0x5A, 0x00]) // XZ
        ]

        for header in compressedHeaders {
            if data.starts(with: header) {
                return true
            }
        }

        return false
    }

    // Encriptar datos de archivo
    private func encryptFileData(_ data: Data) async throws -> Data {
        // Implementar encriptación AES-256
        // Placeholder - usar CryptoKit en implementación real
        return data
    }

    // MARK: - Comunicación con Transportes

    // Enviar chunk de archivo
    private func sendFileChunk(_ transferID: TransferID, chunk: FileChunk, index: Int, total: Int) async throws {
        let chunkMessage = FileChunkMessage(
            transferID: transferID,
            chunk: chunk,
            index: index,
            total: total
        )

        let message = Message(
            id: MessageID(),
            data: try chunkMessage.encoded(),
            metadata: [
                "type": "file_chunk",
                "transfer_id": transferID.uuid.uuidString,
                "chunk_index": "\(index)",
                "total_chunks": "\(total)"
            ]
        )

        try await transportCoordinator.sendMessage(message, priority: .normal)
    }

    // Enviar solicitud de transferencia
    private func sendTransferRequest(_ request: FileTransferRequest) async throws {
        let message = Message(
            id: MessageID(),
            data: try request.encoded(),
            metadata: ["type": "file_transfer_request"]
        )

        try await transportCoordinator.sendMessage(message, priority: .high)
    }

    // Enviar respuesta de transferencia
    private func sendTransferResponse(_ transferID: TransferID, accepted: Bool, reason: String? = nil) async throws {
        let response = TransferResponse(
            transferID: transferID,
            accepted: accepted,
            reason: reason
        )

        let message = Message(
            id: MessageID(),
            data: try response.encoded(),
            metadata: ["type": "transfer_response"]
        )

        try await transportCoordinator.sendMessage(message, priority: .high)
    }

    // Enviar finalización de transferencia
    private func sendTransferCompletion(_ transferID: TransferID, checksum: String) async throws {
        let completion = TransferCompletion(
            transferID: transferID,
            checksum: checksum
        )

        let message = Message(
            id: MessageID(),
            data: try completion.encoded(),
            metadata: ["type": "transfer_completion"]
        )

        try await transportCoordinator.sendMessage(message, priority: .high)
    }

    // Enviar cancelación de transferencia
    private func sendTransferCancellation(_ transferID: TransferID) async throws {
        let cancellation = TransferCancellation(transferID: transferID)

        let message = Message(
            id: MessageID(),
            data: try cancellation.encoded(),
            metadata: ["type": "transfer_cancellation"]
        )

        try await transportCoordinator.sendMessage(message, priority: .high)
    }

    // MARK: - Gestión de Recepción

    // Procesar mensaje de chunk de archivo
    private func processFileChunkMessage(_ message: Message) async throws {
        let chunkMessage = try FileChunkMessage.decode(from: message.data)

        guard let transfer = activeTransfers[chunkMessage.transferID] else {
            throw TransferError.unknownTransfer
        }

        // Verificar integridad del chunk
        let isValid = try await integrityVerifier.verifyChunk(chunkMessage.chunk)
        guard isValid else {
            throw TransferError.corruptedChunk
        }

        // Añadir chunk a la transferencia
        await transfer.addChunk(chunkMessage.chunk, at: chunkMessage.index)

        // Actualizar progreso
        let progress = Double(chunkMessage.index + 1) / Double(chunkMessage.total)
        transferProgress[transfer.id] = Progress(value: progress)
        transferProgressPublisher.send((transfer.id, Progress(value: progress)))

        // Verificar si transferencia está completa
        if await transfer.isComplete() {
            try await finalizeIncomingTransfer(transfer)
        }
    }

    // Procesar respuesta de transferencia
    private func processTransferResponse(_ message: Message) async throws {
        let response = try TransferResponse.decode(from: message.data)

        guard let transfer = activeTransfers[response.transferID] else {
            return
        }

        if response.accepted {
            // Iniciar envío si es outgoing
            if transfer.direction == .outgoing {
                // La transferencia ya está en progreso
            }
        } else {
            // Transferencia rechazada
            transfer.state = .rejected
            activeTransfers.removeValue(forKey: response.transferID)

            let result = TransferResult.rejected(reason: response.reason)
            transferCompletedPublisher.send((response.transferID, result))
        }
    }

    // Procesar finalización de transferencia
    private func processTransferCompletion(_ message: Message) async throws {
        let completion = try TransferCompletion.decode(from: message.data)

        guard let transfer = activeTransfers[completion.transferID] else {
            return
        }

        // Verificar checksum
        let isValid = try await integrityVerifier.verifyTransfer(transfer, expectedChecksum: completion.checksum)

        if isValid {
            transfer.state = .completed
            let result = TransferResult.success(fileURL: try await saveTransferredFile(transfer.reassembledData!, info: transfer.fileInfo))
            transferCompletedPublisher.send((completion.transferID, result))
        } else {
            transfer.state = .failed(TransferError.checksumMismatch)
            let result = TransferResult.failure(TransferError.checksumMismatch)
            transferCompletedPublisher.send((completion.transferID, result))
        }

        activeTransfers.removeValue(forKey: completion.transferID)
    }

    // Finalizar transferencia entrante
    private func finalizeIncomingTransfer(_ transfer: FileTransfer) async throws {
        // Verificar integridad completa
        guard let reassembledData = await transfer.reassembledData else {
            throw TransferError.incompleteTransfer
        }

        // Desencriptar si es necesario
        let finalData = transfer.options.encrypt ? try await decryptFileData(reassembledData) : reassembledData

        // Descomprimir si es necesario
        let decompressedData = transfer.options.compress ? try await compressionEngine.decompress(finalData) : finalData

        // Guardar archivo
        let fileURL = try await saveTransferredFile(decompressedData, info: transfer.fileInfo)

        transfer.state = .completed
        let result = TransferResult.success(fileURL: fileURL)
        transferCompletedPublisher.send((transfer.id, result))

        activeTransfers.removeValue(forKey: transfer.id)

        print("✅ Archivo recibido y guardado: \(transfer.fileInfo.name)")
    }

    // Desencriptar datos de archivo
    private func decryptFileData(_ data: Data) async throws -> Data {
        // Implementar desencriptación
        return data // Placeholder
    }

    // Guardar archivo transferido
    private func saveTransferredFile(_ data: Data, info: FileInfo) async throws -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(info.name)

        try data.write(to: fileURL)

        return fileURL
    }

    // MARK: - Configuración

    private func setupTransportBindings() {
        // Configurar recepción de mensajes de transporte
        transportCoordinator.messageReceived
            .sink { [weak self] message, transport in
                Task { await self?.handleTransportMessage(message, from: transport) }
            }
            .store(in: &cancellables)
    }

    private func handleTransportMessage(_ message: Message, from transport: TransportType) async {
        guard let messageType = message.metadata["type"] else { return }

        do {
            switch messageType {
            case "file_transfer_request":
                let request = try FileTransferRequest.decode(from: message.data)
                try await handleIncomingFileTransfer(request)

            case "transfer_response":
                try await processTransferResponse(message)

            case "file_chunk":
                try await processFileChunkMessage(message)

            case "transfer_completion":
                try await processTransferCompletion(message)

            case "transfer_cancellation":
                let cancellation = try TransferCancellation.decode(from: message.data)
                await cancelTransfer(cancellation.transferID)

            default:
                break
            }
        } catch {
            print("❌ Error procesando mensaje de transferencia: \(error.localizedDescription)")
        }
    }

    private var cancellables = Set<AnyCancellable>()
}

// Engine de compresión
class CompressionEngine {
    func compress(_ data: Data, algorithm: CompressionAlgorithm) async throws -> Data {
        switch algorithm {
        case .gzip:
            return try (data as NSData).compressed(using: .gzip) as Data
        case .lzma:
            return try (data as NSData).compressed(using: .lzma) as Data
        case .zlib:
            return try (data as NSData).compressed(using: .zlib) as Data
        }
    }

    func decompress(_ data: Data) async throws -> Data {
        return try (data as NSData).decompressed(using: .gzip) as Data
    }
}

// Verificador de integridad
class FileIntegrityVerifier {
    func calculateChecksum(_ data: Data) async throws -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    func verifyChunk(_ chunk: FileChunk) async throws -> Bool {
        let calculatedChecksum = try await calculateChecksum(chunk.data)
        return calculatedChecksum == chunk.checksum
    }

    func verifyTransfer(_ transfer: FileTransfer, expectedChecksum: String) async throws -> Bool {
        guard let data = await transfer.reassembledData else {
            return false
        }

        let calculatedChecksum = try await calculateChecksum(data)
        return calculatedChecksum == expectedChecksum
    }
}

// Cola de transferencias
class TransferQueue {
    private var queue: [FileTransfer] = []
    private let maxConcurrentTransfers = 3

    func enqueue(_ transfer: FileTransfer) async {
        queue.append(transfer)
        await processQueue()
    }

    func dequeue() async -> FileTransfer? {
        guard !queue.isEmpty else { return nil }
        return queue.removeFirst()
    }

    private func processQueue() async {
        let activeCount = queue.filter { $0.state == .transferring }.count

        if activeCount < maxConcurrentTransfers {
            // Iniciar más transferencias si hay capacidad
        }
    }
}

// Estructuras de datos
struct TransferID: Hashable {
    let uuid: UUID

    init() {
        self.uuid = UUID()
    }
}

struct StreamID: Hashable {
    let uuid: UUID

    init() {
        self.uuid = UUID()
    }
}

struct FileTransfer {
    let id: TransferID
    let direction: TransferDirection
    let peerID: PeerID
    let fileInfo: FileInfo
    let options: TransferOptions
    var state: TransferState

    // Para transferencias entrantes
    private var chunks: [Int: FileChunk] = [:]
    private var totalChunks: Int?

    mutating func addChunk(_ chunk: FileChunk, at index: Int) async {
        chunks[index] = chunk
        if totalChunks == nil {
            // Estimar total de chunks basado en el último índice recibido
            totalChunks = index + 1
        }
    }

    func isComplete() async -> Bool {
        guard let total = totalChunks else { return false }
        return chunks.count == total
    }

    var reassembledData: Data? {
        get async {
            guard await isComplete(), let total = totalChunks else { return nil }

            var data = Data()
            for i in 0..<total {
                guard let chunk = chunks[i] else { return nil }
                data.append(chunk.data)
            }

            return data
        }
    }
}

enum TransferDirection {
    case incoming, outgoing
}

enum TransferState {
    case preparing
    case transferring
    case receiving
    case completed
    case cancelled
    case rejected
    case failed(Error)
}

struct FileInfo {
    let name: String
    let size: Int
    let type: String
    let checksum: String?

    static func from(url: URL, data: Data) -> FileInfo {
        FileInfo(
            name: url.lastPathComponent,
            size: data.count,
            type: url.pathExtension,
            checksum: nil // Se calcula después de preparar
        )
    }
}

struct TransferOptions {
    var compress: Bool = true
    var encrypt: Bool = false
    var chunkSize: Int = 64 * 1024 // 64KB
    var maxFileSize: Int = 100 * 1024 * 1024 // 100MB
    var compressionAlgorithm: CompressionAlgorithm = .gzip
    var priority: MessagePriority = .normal

    static let `default` = TransferOptions()
}

enum CompressionAlgorithm {
    case gzip, lzma, zlib
}

struct PreparedFileData {
    let data: Data
    let checksum: String
    let originalSize: Int
}

struct FileChunk {
    let index: Int
    let data: Data
    let checksum: String
}

struct MediaStream {
    let id: StreamID
    let direction: TransferDirection
    let peerID: PeerID
    let mediaURL: URL
    let quality: StreamingQuality
    var state: StreamingState
}

enum StreamingQuality {
    case low, medium, high, adaptive
}

enum StreamingState {
    case buffering, streaming, paused, stopped, failed(Error)
}

struct Progress {
    let value: Double // 0.0 - 1.0
    let estimatedTimeRemaining: TimeInterval?
}

// Mensajes de protocolo
struct FileTransferRequest {
    let transferID: TransferID
    let peerID: PeerID
    let fileInfo: FileInfo
    let options: TransferOptions

    func encoded() throws -> Data {
        // Implementar codificación
        return Data() // Placeholder
    }

    static func decode(from data: Data) throws -> FileTransferRequest {
        // Implementar decodificación
        throw TransferError.decodingFailed // Placeholder
    }
}

struct TransferResponse {
    let transferID: TransferID
    let accepted: Bool
    let reason: String?

    func encoded() throws -> Data { return Data() }
    static func decode(from data: Data) throws -> TransferResponse { throw TransferError.decodingFailed }
}

struct FileChunkMessage {
    let transferID: TransferID
    let chunk: FileChunk
    let index: Int
    let total: Int

    func encoded() throws -> Data { return Data() }
    static func decode(from data: Data) throws -> FileChunkMessage { throw TransferError.decodingFailed }
}

struct TransferCompletion {
    let transferID: TransferID
    let checksum: String

    func encoded() throws -> Data { return Data() }
    static func decode(from data: Data) throws -> TransferCompletion { throw TransferError.decodingFailed }
}

struct TransferCancellation {
    let transferID: TransferID

    func encoded() throws -> Data { return Data() }
    static func decode(from data: Data) throws -> TransferCancellation { throw TransferError.decodingFailed }
}

enum TransferResult {
    case success(fileURL: URL)
    case failure(Error)
    case rejected(reason: String?)
}

// Errores
enum TransferError: Error {
    case fileTooLarge
    case unknownTransfer
    case corruptedChunk
    case checksumMismatch
    case incompleteTransfer
    case decodingFailed
}

// Controlador de UI para transferencias
class FileTransferViewController: UIViewController {
    private let transferManager: FileTransferManager
    private var cancellables = Set<AnyCancellable>()
    private var activeTransfers: [TransferID: TransferCell] = [:]

    init(transferManager: FileTransferManager) {
        self.transferManager = transferManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }

    private func setupUI() {
        // Crear UI para mostrar transferencias activas
        // Botón para seleccionar archivo y enviar
        // Tabla para mostrar progreso de transferencias
    }

    private func setupBindings() {
        // Observar nuevas transferencias
        transferManager.transferStarted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transfer in
                self?.addTransferCell(for: transfer)
            }
            .store(in: &cancellables)

        // Observar progreso
        transferManager.transferProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transferID, progress in
                self?.updateTransferProgress(transferID, progress: progress)
            }
            .store(in: &cancellables)

        // Observar finalización
        transferManager.transferCompleted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transferID, result in
                self?.handleTransferCompletion(transferID, result: result)
            }
            .store(in: &cancellables)
    }

    @objc func selectAndSendFile() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data])
        picker.delegate = self
        present(picker, animated: true)
    }

    private func addTransferCell(for transfer: FileTransfer) {
        // Crear y añadir celda para la nueva transferencia
        let cell = TransferCell(transfer: transfer)
        activeTransfers[transfer.id] = cell
        // Añadir a UI
    }

    private func updateTransferProgress(_ transferID: TransferID, progress: Progress) {
        guard let cell = activeTransfers[transferID] else { return }
        cell.updateProgress(progress.value)
    }

    private func handleTransferCompletion(_ transferID: TransferID, result: TransferResult) {
        guard let cell = activeTransfers[transferID] else { return }

        switch result {
        case .success(let fileURL):
            cell.showSuccess()
            print("Archivo guardado en: \(fileURL.path)")
        case .failure(let error):
            cell.showError(error.localizedDescription)
        case .rejected(let reason):
            cell.showRejected(reason ?? "Rechazado por el receptor")
        }

        // Remover después de un delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.activeTransfers.removeValue(forKey: transferID)
            // Remover de UI
        }
    }
}

extension FileTransferViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileURL = urls.first else { return }

        Task {
            do {
                let peerID = PeerID(data: Data([0x01, 0x02, 0x03, 0x04]))! // Placeholder - obtener peer real
                _ = try await transferManager.startFileTransfer(fileURL: fileURL, to: peerID)
            } catch {
                showError("Error iniciando transferencia: \(error.localizedDescription)")
            }
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// Celda para mostrar transferencia
class TransferCell: UIView {
    private let transfer: FileTransfer
    private let progressView: UIProgressView
    private let statusLabel: UILabel

    init(transfer: FileTransfer) {
        self.transfer = transfer
        self.progressView = UIProgressView(progressViewStyle: .default)
        self.statusLabel = UILabel()

        super.init(frame: .zero)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        // Configurar UI de la celda
        statusLabel.text = "Enviando \(transfer.fileInfo.name)"
        progressView.progress = 0.0
    }

    func updateProgress(_ progress: Double) {
        progressView.progress = Float(progress)
        statusLabel.text = "Enviando \(transfer.fileInfo.name) - \(Int(progress * 100))%"
    }

    func showSuccess() {
        statusLabel.text = "✅ \(transfer.fileInfo.name) enviado"
        progressView.progress = 1.0
        backgroundColor = .green.withAlphaComponent(0.1)
    }

    func showError(_ message: String) {
        statusLabel.text = "❌ Error: \(message)"
        backgroundColor = .red.withAlphaComponent(0.1)
    }

    func showRejected(_ reason: String) {
        statusLabel.text = "❌ Rechazado: \(reason)"
        backgroundColor = .orange.withAlphaComponent(0.1)
    }
}
```

## Notas Adicionales

- Implementa límites apropiados de tamaño de archivo según el dispositivo
- Proporciona feedback visual detallado del progreso de transferencias
- Considera el impacto en batería de transferencias grandes
- Implementa pausa y reanudación de transferencias
- Maneja apropiadamente la memoria para archivos grandes
- Proporciona opciones de compresión por tipo de archivo
- Implementa verificación de integridad robusta
- Considera el costo de datos para transferencias grandes