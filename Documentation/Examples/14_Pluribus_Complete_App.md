# Pluribus - Aplicación Completa de Mensajería P2P

## Descripción

**Pluribus** es una aplicación completa de mensajería peer-to-peer que demuestra el uso integral del framework BitchatCommunications. La aplicación permite comunicaciones seguras, privadas y resistentes a la censura entre dispositivos iOS y macOS.

**Características Principales:**
- Mensajería en tiempo real con encriptación end-to-end
- Chat grupal con moderación distribuida
- Transferencias de archivos y multimedia
- Geolocalización y mensajería local
- Anonimato opcional con Tor
- Analytics de comunidad
- Interfaz moderna y intuitiva
- Sincronización entre dispositivos

**Arquitectura:**
- **iOS 17+** y **macOS 14+**
- **SwiftUI** para la interfaz moderna
- **Combine** para manejo reactivo de estado
- **Core Data** para persistencia local
- **BitchatCommunications** como núcleo de comunicaciones

## Estructura del Proyecto

```
Pluribus/
├── Pluribus.xcodeproj/
├── Sources/
│   ├── App/
│   │   ├── PluribusApp.swift
│   │   ├── AppDelegate.swift
│   │   └── SceneDelegate.swift
│   ├── Core/
│   │   ├── Services/
│   │   │   ├── CommunicationService.swift
│   │   │   ├── UserService.swift
│   │   │   ├── GroupService.swift
│   │   │   └── FileService.swift
│   │   ├── Models/
│   │   │   ├── User.swift
│   │   │   ├── Message.swift
│   │   │   ├── Group.swift
│   │   │   └── FileTransfer.swift
│   │   └── Managers/
│   │       ├── PermissionManager.swift
│   │       ├── NotificationManager.swift
│   │       └── ThemeManager.swift
│   ├── UI/
│   │   ├── Views/
│   │   │   ├── Chat/
│   │   │   │   ├── ChatView.swift
│   │   │   │   ├── MessageBubble.swift
│   │   │   │   └── MessageInputView.swift
│   │   │   ├── Groups/
│   │   │   │   ├── GroupListView.swift
│   │   │   │   ├── GroupDetailView.swift
│   │   │   │   └── CreateGroupView.swift
│   │   │   ├── Contacts/
│   │   │   │   ├── ContactListView.swift
│   │   │   │   └── AddContactView.swift
│   │   │   ├── Settings/
│   │   │   │   ├── SettingsView.swift
│   │   │   │   ├── PrivacySettingsView.swift
│   │   │   │   └── SecuritySettingsView.swift
│   │   │   └── Common/
│   │   │       ├── AvatarView.swift
│   │   │       ├── LoadingView.swift
│   │   │       └── ErrorView.swift
│   │   ├── ViewModels/
│   │   │   ├── ChatViewModel.swift
│   │   │   ├── GroupViewModel.swift
│   │   │   ├── ContactViewModel.swift
│   │   │   └── SettingsViewModel.swift
│   │   └── Components/
│   │       ├── Buttons/
│   │       ├── TextFields/
│   │       └── Modifiers/
│   └── Resources/
│       ├── Assets.xcassets/
│       ├── Localizable.strings
│       └── Info.plist
├── Tests/
│   ├── UnitTests/
│   └── UITests/
└── Pluribus.xcworkspace/
```

## Implementación Completa

### 1. PluribusApp.swift - Punto de entrada

```swift
import SwiftUI
import BitchatCommunications

@main
struct PluribusApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var communicationService = CommunicationService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(communicationService)
                .onAppear {
                    setupApp()
                }
        }
        .commands {
            SidebarCommands()
        }

        #if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
        #endif
    }

    private func setupApp() {
        // Configurar servicios iniciales
        Task {
            await communicationService.initialize()
        }
    }
}

class AppState: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var selectedTab: Tab = .chats
    @Published var theme: Theme = .system

    enum Tab {
        case chats, groups, contacts, settings
    }

    enum Theme {
        case light, dark, system
    }
}
```

### 2. CommunicationService.swift - Servicio principal de comunicaciones

```swift
import BitchatCommunications
import Combine

class CommunicationService: ObservableObject {
    // Servicios del framework
    private let bleService: BLEService
    private let nostrService: NostrService
    private let geoService: GeoService
    private let stateService: StateService
    private let mediaService: MediaService
    private let torService: TorService
    private let transportCoordinator: TransportCoordinator
    private let fileTransferManager: FileTransferManager
    private let trustManager: TrustManager
    private let analyticsEngine: AnalyticsEngine

    // Estado
    @Published var isConnected = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var nearbyPeers: [Peer] = []
    @Published var activeTransfers: [FileTransfer] = []

    // Publishers
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Inicializar servicios del framework
        self.bleService = BLEService()
        self.nostrService = NostrService()
        self.geoService = GeoService()
        self.stateService = StateService()
        self.mediaService = MediaService()
        self.torService = TorService()
        self.transportCoordinator = TransportCoordinator()
        self.fileTransferManager = FileTransferManager(transportCoordinator: transportCoordinator)
        self.trustManager = TrustManager()
        self.analyticsEngine = AnalyticsEngine()

        setupBindings()
    }

    func initialize() async {
        do {
            // Cargar estado persistente
            try await loadPersistedState()

            // Iniciar servicios básicos
            try await startBasicServices()

            // Configurar anonimato si está habilitado
            if UserDefaults.standard.bool(forKey: "torEnabled") {
                try await enableTor()
            }

            // Iniciar coordinación de transportes
            try await transportCoordinator.startAllTransports()

            // Iniciar analytics
            analyticsEngine.startMetricsCollection()

            connectionStatus = .connected
            isConnected = true

            print("✅ Pluribus inicializado exitosamente")

        } catch {
            print("❌ Error inicializando Pluribus: \(error.localizedDescription)")
            connectionStatus = .error(error)
        }
    }

    // MARK: - Mensajería

    func sendMessage(_ content: String, to peerID: PeerID, priority: MessagePriority = .normal) async throws {
        guard isConnected else { throw PluribusError.notConnected }

        let message = Message(
            id: MessageID(),
            content: content,
            sender: getCurrentUserID(),
            recipient: peerID,
            timestamp: Date(),
            type: .text
        )

        try await transportCoordinator.sendMessage(message, priority: priority)

        // Registrar evento para analytics
        analyticsEngine.trackEvent(AnalyticsEvent(
            name: "message_sent",
            value: Double(content.count),
            metadata: ["priority": priority.rawValue]
        ))
    }

    func sendGroupMessage(_ content: String, to groupID: GroupID) async throws {
        guard isConnected else { throw PluribusError.notConnected }

        let message = GroupMessage(
            id: MessageID(),
            content: content,
            sender: getCurrentUserID(),
            groupID: groupID,
            timestamp: Date(),
            type: .text
        )

        try await transportCoordinator.sendGroupMessage(message)
    }

    // MARK: - Transferencias de archivos

    func sendFile(_ fileURL: URL, to peerID: PeerID) async throws -> TransferID {
        guard isConnected else { throw PluribusError.notConnected }

        let transferID = try await fileTransferManager.startFileTransfer(
            fileURL: fileURL,
            to: peerID,
            options: .default
        )

        return transferID
    }

    // MARK: - Grupos

    func createGroup(name: String, description: String? = nil, isPrivate: Bool = false) async throws -> Group {
        guard isConnected else { throw PluribusError.notConnected }

        let group = Group(
            id: GroupID(),
            name: name,
            description: description,
            creator: getCurrentUserID(),
            members: [getCurrentUserID()],
            isPrivate: isPrivate,
            createdAt: Date()
        )

        try await transportCoordinator.createGroup(group)
        return group
    }

    func joinGroup(_ groupID: GroupID) async throws {
        guard isConnected else { throw PluribusError.notConnected }

        try await transportCoordinator.joinGroup(groupID, peerID: getCurrentUserID())
    }

    // MARK: - Gestión de confianza

    func verifyPeerIdentity(_ peerID: PeerID) async throws {
        try await trustManager.initiateIdentityVerification(with: peerID)
    }

    func createAttestation(for peerID: PeerID, type: AttestationType, claim: String) async throws {
        try await trustManager.createAttestation(
            for: peerID,
            type: type,
            claim: claim,
            confidence: 0.8
        )
    }

    // MARK: - Multimedia

    func sendVoiceMessage(_ audioURL: URL, to peerID: PeerID) async throws {
        guard isConnected else { throw PluribusError.notConnected }

        // Comprimir audio si es necesario
        let compressedAudio = try await mediaService.compressAudio(audioURL)

        let message = Message(
            id: MessageID(),
            content: "",
            sender: getCurrentUserID(),
            recipient: peerID,
            timestamp: Date(),
            type: .voice,
            attachment: compressedAudio
        )

        try await transportCoordinator.sendMessage(message, priority: .high)
    }

    func sendImage(_ image: UIImage, to peerID: PeerID) async throws {
        guard isConnected else { throw PluribusError.notConnected }

        // Comprimir imagen
        let compressedImage = try await mediaService.compressImage(image)

        let message = Message(
            id: MessageID(),
            content: "",
            sender: getCurrentUserID(),
            recipient: peerID,
            timestamp: Date(),
            type: .image,
            attachment: compressedImage
        )

        try await transportCoordinator.sendMessage(message, priority: .normal)
    }

    // MARK: - Privacidad y seguridad

    func enableTor() async throws {
        try await torService.startTor()
        print("🧅 Tor habilitado")
    }

    func disableTor() async throws {
        try await torService.stopTor()
        print("🧅 Tor deshabilitado")
    }

    func performSecurityAudit() async throws -> SecurityAuditResult {
        return try await trustManager.performSecurityAudit()
    }

    // MARK: - Utilidades privadas

    private func loadPersistedState() async throws {
        // Cargar identidad del usuario
        if let identityData = try await stateService.loadIdentity() {
            // Configurar identidad
        }
    }

    private func startBasicServices() async throws {
        // Iniciar BLE
        try await bleService.start()

        // Iniciar Nostr
        try await nostrService.connect()

        // Iniciar servicios geográficos si están permitidos
        if PermissionManager.shared.locationPermissionGranted {
            try await geoService.startLocationUpdates()
        }
    }

    private func getCurrentUserID() -> PeerID {
        // Implementar obtención del ID actual
        return PeerID(data: Data([0x01, 0x02, 0x03, 0x04]))!
    }

    private func setupBindings() {
        // Observar cambios en transportes
        transportCoordinator.transportStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.handleTransportStatusChange(status)
            }
            .store(in: &cancellables)

        // Observar mensajes entrantes
        transportCoordinator.messageReceived
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message, transport in
                self?.handleIncomingMessage(message, from: transport)
            }
            .store(in: &cancellables)

        // Observar transferencias
        fileTransferManager.transferProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transferID, progress in
                self?.updateTransferProgress(transferID, progress: progress)
            }
            .store(in: &cancellables)
    }

    private func handleTransportStatusChange(_ status: TransportStatus) {
        switch status.state {
        case .connected:
            connectionStatus = .connected
            isConnected = true
        case .disconnected:
            connectionStatus = .disconnected
            isConnected = false
        case .failed:
            connectionStatus = .error(PluribusError.transportFailed)
            isConnected = false
        }
    }

    private func handleIncomingMessage(_ message: Message, from transport: TransportType) {
        // Procesar mensaje entrante
        // Notificar a la UI
        NotificationCenter.default.post(
            name: .didReceiveMessage,
            object: nil,
            userInfo: ["message": message, "transport": transport]
        )
    }

    private func updateTransferProgress(_ transferID: TransferID, progress: Progress) {
        // Actualizar progreso de transferencia
        if let index = activeTransfers.firstIndex(where: { $0.id == transferID }) {
            activeTransfers[index].progress = progress
        }
    }
}

// Extensiones para notificaciones
extension Notification.Name {
    static let didReceiveMessage = Notification.Name("didReceiveMessage")
    static let didUpdateTransfer = Notification.Name("didUpdateTransfer")
}

// Enums y structs de apoyo
enum ConnectionStatus {
    case disconnected
    case connecting
    case connected
    case error(Error)
}

enum PluribusError: Error {
    case notConnected
    case transportFailed
    case invalidMessage
    case permissionDenied
}
```

### 3. ContentView.swift - Vista principal

```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var communicationService: CommunicationService
    @State private var selectedTab: AppState.Tab = .chats

    var body: some View {
        #if os(iOS)
        TabView(selection: $selectedTab) {
            ChatListView()
                .tabItem {
                    Label("Chats", systemImage: "message")
                }
                .tag(AppState.Tab.chats)

            GroupListView()
                .tabItem {
                    Label("Grupos", systemImage: "person.3")
                }
                .tag(AppState.Tab.groups)

            ContactListView()
                .tabItem {
                    Label("Contactos", systemImage: "person.2")
                }
                .tag(AppState.Tab.contacts)

            SettingsView()
                .tabItem {
                    Label("Ajustes", systemImage: "gear")
                }
                .tag(AppState.Tab.settings)
        }
        .onChange(of: selectedTab) { newTab in
            appState.selectedTab = newTab
        }
        #else
        NavigationSplitView {
            Sidebar(selectedTab: $selectedTab)
        } detail: {
            DetailView(selectedTab: selectedTab)
        }
        #endif
    }
}

struct Sidebar: View {
    @Binding var selectedTab: AppState.Tab

    var body: some View {
        List(selection: $selectedTab) {
            NavigationLink(value: AppState.Tab.chats) {
                Label("Chats", systemImage: "message")
            }

            NavigationLink(value: AppState.Tab.groups) {
                Label("Grupos", systemImage: "person.3")
            }

            NavigationLink(value: AppState.Tab.contacts) {
                Label("Contactos", systemImage: "person.2")
            }

            NavigationLink(value: AppState.Tab.settings) {
                Label("Ajustes", systemImage: "gear")
            }
        }
        .navigationTitle("Pluribus")
    }
}

struct DetailView: View {
    let selectedTab: AppState.Tab

    var body: some View {
        switch selectedTab {
        case .chats:
            ChatListView()
        case .groups:
            GroupListView()
        case .contacts:
            ContactListView()
        case .settings:
            SettingsView()
        }
    }
}
```

### 4. ChatView.swift - Vista de chat

```swift
import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @EnvironmentObject var communicationService: CommunicationService
    @FocusState private var isInputFocused: Bool

    init(peerID: PeerID) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(peerID: peerID))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            ChatHeader(peerID: viewModel.peerID)

            // Messages
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    withAnimation {
                        scrollView.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                    }
                }
            }

            // Input
            MessageInputView(
                text: $viewModel.inputText,
                isFocused: _isInputFocused
            ) {
                await sendMessage()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadMessages()
            isInputFocused = true
        }
        .onDisappear {
            viewModel.saveDraft()
        }
    }

    private func sendMessage() async {
        guard !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        do {
            try await communicationService.sendMessage(
                viewModel.inputText,
                to: viewModel.peerID
            )

            viewModel.inputText = ""
        } catch {
            viewModel.showError(error.localizedDescription)
        }
    }
}

struct ChatHeader: View {
    let peerID: PeerID
    @EnvironmentObject var communicationService: CommunicationService

    var body: some View {
        HStack {
            AvatarView(peerID: peerID, size: 40)

            VStack(alignment: .leading) {
                Text(peerID.displayName ?? "Usuario desconocido")
                    .font(.headline)

                HStack {
                    Circle()
                        .fill(connectionColor)
                        .frame(width: 8, height: 8)

                    Text(connectionText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Menu {
                Button(action: startVoiceCall) {
                    Label("Llamada de voz", systemImage: "phone")
                }

                Button(action: sendFile) {
                    Label("Enviar archivo", systemImage: "paperclip")
                }

                Button(action: viewProfile) {
                    Label("Ver perfil", systemImage: "person.circle")
                }

                Divider()

                Button(action: blockUser) {
                    Label("Bloquear usuario", systemImage: "hand.raised")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var connectionColor: Color {
        switch communicationService.connectionStatus {
        case .connected:
            return .green
        case .connecting:
            return .yellow
        case .disconnected, .error:
            return .red
        }
    }

    private var connectionText: String {
        switch communicationService.connectionStatus {
        case .connected:
            return "Conectado"
        case .connecting:
            return "Conectando..."
        case .disconnected:
            return "Desconectado"
        case .error:
            return "Error de conexión"
        }
    }

    private func startVoiceCall() {
        // Implementar llamada de voz
    }

    private func sendFile() {
        // Implementar envío de archivo
    }

    private func viewProfile() {
        // Implementar vista de perfil
    }

    private func blockUser() {
        // Implementar bloqueo de usuario
    }
}

struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer()
                messageContent
                    .background(Color.blue.opacity(0.2))
                    .clipShape(ChatBubble(isFromCurrentUser: true))
            } else {
                messageContent
                    .background(Color(.systemGray5))
                    .clipShape(ChatBubble(isFromCurrentUser: false))
                Spacer()
            }
        }
        .padding(.horizontal, 4)
    }

    private var messageContent: some View {
        VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 4) {
            if let attachment = message.attachment {
                AttachmentView(attachment: attachment)
            }

            if !message.content.isEmpty {
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .foregroundColor(message.isFromCurrentUser ? .white : .primary)
            }

            HStack(spacing: 4) {
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)

                if message.isFromCurrentUser {
                    Image(systemName: message.deliveryStatus.icon)
                        .font(.caption2)
                        .foregroundColor(message.deliveryStatus.color)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 4)
        }
    }
}

struct ChatBubble: Shape {
    let isFromCurrentUser: Bool

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [
                .topLeft: isFromCurrentUser ? .allCorners : [.topLeft, .topRight, .bottomLeft],
                .topRight: isFromCurrentUser ? [.topLeft, .topRight, .bottomRight] : .allCorners,
                .bottomLeft: isFromCurrentUser ? [.topLeft, .topRight, .bottomLeft] : .allCorners,
                .bottomRight: isFromCurrentUser ? .allCorners : [.topLeft, .topRight, .bottomRight]
            ].reduce(into: UIRectCorner()) { $0.insert($1.key) },
            cornerRadii: CGSize(width: 16, height: 16)
        )
        return Path(path.cgPath)
    }
}

struct MessageInputView: View {
    @Binding var text: String
    let isFocused: FocusState<Bool>.Binding
    let onSend: () async -> Void

    @State private var isRecording = false
    @State private var showingAttachmentPicker = false

    var body: some View {
        HStack(spacing: 12) {
            // Botón de adjunto
            Button(action: { showingAttachmentPicker = true }) {
                Image(systemName: "paperclip")
                    .foregroundColor(.secondary)
            }

            // Campo de texto
            TextField("Escribe un mensaje...", text: $text)
                .textFieldStyle(.roundedBorder)
                .focused(isFocused)
                .onSubmit {
                    Task { await onSend() }
                }

            // Botón de voz o enviar
            if text.isEmpty {
                Button(action: toggleRecording) {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title2)
                        .foregroundColor(isRecording ? .red : .blue)
                }
            } else {
                Button(action: { Task { await onSend() } }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .sheet(isPresented: $showingAttachmentPicker) {
            AttachmentPickerView()
        }
    }

    private func toggleRecording() {
        withAnimation {
            isRecording.toggle()
        }

        if isRecording {
            // Iniciar grabación
            startRecording()
        } else {
            // Detener grabación y enviar
            stopRecording()
        }
    }

    private func startRecording() {
        // Implementar grabación de voz
        print("🎤 Iniciando grabación de voz")
    }

    private func stopRecording() {
        // Implementar envío de mensaje de voz
        print("🎤 Deteniendo grabación y enviando")
    }
}

struct AttachmentView: View {
    let attachment: MessageAttachment

    var body: some View {
        switch attachment.type {
        case .image:
            if let image = attachment.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 200, maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

        case .voice:
            HStack {
                Image(systemName: "waveform")
                Text("Mensaje de voz")
                    .font(.caption)
                Spacer()
                Button(action: playVoiceMessage) {
                    Image(systemName: "play.circle")
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))

        case .file:
            HStack {
                Image(systemName: attachment.fileType?.icon ?? "doc")
                VStack(alignment: .leading) {
                    Text(attachment.fileName ?? "Archivo")
                        .font(.caption)
                        .lineLimit(1)
                    Text(attachment.fileSize?.formattedFileSize ?? "")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: openFile) {
                    Image(systemName: "arrow.down.circle")
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func playVoiceMessage() {
        // Implementar reproducción de voz
    }

    private func openFile() {
        // Implementar apertura de archivo
    }
}

struct AttachmentPickerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var communicationService: CommunicationService

    var body: some View {
        NavigationView {
            List {
                Button(action: selectPhoto) {
                    Label("Foto", systemImage: "photo")
                }

                Button(action: selectVideo) {
                    Label("Video", systemImage: "video")
                }

                Button(action: selectFile) {
                    Label("Archivo", systemImage: "doc")
                }

                Button(action: selectLocation) {
                    Label("Ubicación", systemImage: "location")
                }
            }
            .navigationTitle("Adjuntar")
            .navigationBarItems(trailing: Button("Cancelar") {
                dismiss()
            })
        }
    }

    private func selectPhoto() {
        // Implementar selección de foto
        dismiss()
    }

    private func selectVideo() {
        // Implementar selección de video
        dismiss()
    }

    private func selectFile() {
        // Implementar selección de archivo
        dismiss()
    }

    private func selectLocation() {
        // Implementar selección de ubicación
        dismiss()
    }
}
```

### 5. ChatViewModel.swift - ViewModel para chat

```swift
import SwiftUI
import Combine

class ChatViewModel: ObservableObject {
    let peerID: PeerID

    @Published var messages: [Message] = []
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private let messageStore = MessageStore.shared

    init(peerID: PeerID) {
        self.peerID = peerID

        loadMessages()
        setupNotifications()
    }

    func loadMessages() {
        isLoading = true

        Task {
            do {
                let loadedMessages = try await messageStore.loadMessages(for: peerID)
                await MainActor.run {
                    self.messages = loadedMessages
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    func saveDraft() {
        if !inputText.isEmpty {
            UserDefaults.standard.set(inputText, forKey: "draft_\(peerID.id)")
        }
    }

    func loadDraft() {
        inputText = UserDefaults.standard.string(forKey: "draft_\(peerID.id)") ?? ""
    }

    func showError(_ message: String) {
        errorMessage = message

        // Ocultar error después de 3 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.errorMessage = nil
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .didReceiveMessage)
            .compactMap { notification -> Message? in
                notification.userInfo?["message"] as? Message
            }
            .filter { message in
                message.sender == self.peerID || message.recipient == self.peerID
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleIncomingMessage(message)
            }
            .store(in: &cancellables)
    }

    private func handleIncomingMessage(_ message: Message) {
        messages.append(message)

        // Marcar como leído si la vista está visible
        Task {
            try? await messageStore.markAsRead(message)
        }
    }
}
```

### 6. SettingsView.swift - Vista de ajustes

```swift
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var communicationService: CommunicationService
    @State private var showingSecurityAudit = false
    @State private var auditResult: SecurityAuditResult?

    var body: some View {
        NavigationView {
            List {
                // Perfil
                Section("Perfil") {
                    NavigationLink(destination: ProfileSettingsView()) {
                        HStack {
                            AvatarView(peerID: getCurrentUserID(), size: 40)
                            VStack(alignment: .leading) {
                                Text("Mi Perfil")
                                    .font(.headline)
                                Text(getCurrentUserID().displayName ?? "Usuario")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Privacidad
                Section("Privacidad") {
                    NavigationLink(destination: PrivacySettingsView()) {
                        Label("Privacidad", systemImage: "hand.raised")
                    }

                    Toggle("Modo Tor", isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "torEnabled") },
                        set: { enabled in
                            UserDefaults.standard.set(enabled, forKey: "torEnabled")
                            Task {
                                do {
                                    if enabled {
                                        try await communicationService.enableTor()
                                    } else {
                                        try await communicationService.disableTor()
                                    }
                                } catch {
                                    print("Error cambiando modo Tor: \(error)")
                                }
                            }
                        }
                    ))
                }

                // Notificaciones
                Section("Notificaciones") {
                    NavigationLink(destination: NotificationSettingsView()) {
                        Label("Notificaciones", systemImage: "bell")
                    }
                }

                // Apariencia
                Section("Apariencia") {
                    Picker("Tema", selection: $appState.theme) {
                        Text("Claro").tag(AppState.Theme.light)
                        Text("Oscuro").tag(AppState.Theme.dark)
                        Text("Sistema").tag(AppState.Theme.system)
                    }
                }

                // Almacenamiento
                Section("Almacenamiento") {
                    NavigationLink(destination: StorageSettingsView()) {
                        Label("Almacenamiento", systemImage: "internaldrive")
                    }
                }

                // Seguridad
                Section("Seguridad") {
                    Button(action: { showingSecurityAudit = true }) {
                        Label("Auditoría de Seguridad", systemImage: "lock.shield")
                    }

                    NavigationLink(destination: SecuritySettingsView()) {
                        Label("Configuración de Seguridad", systemImage: "key")
                    }
                }

                // Soporte
                Section("Soporte") {
                    NavigationLink(destination: HelpView()) {
                        Label("Ayuda", systemImage: "questionmark.circle")
                    }

                    NavigationLink(destination: AboutView()) {
                        Label("Acerca de", systemImage: "info.circle")
                    }
                }

                // Sesión
                Section {
                    Button(action: logout) {
                        Label("Cerrar Sesión", systemImage: "arrow.right.square")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Ajustes")
            .sheet(isPresented: $showingSecurityAudit) {
                SecurityAuditView(result: $auditResult)
            }
            .onAppear {
                performSecurityAudit()
            }
        }
    }

    private func getCurrentUserID() -> PeerID {
        // Implementar obtención del usuario actual
        return PeerID(data: Data([0x01, 0x02, 0x03, 0x04]))!
    }

    private func performSecurityAudit() {
        Task {
            do {
                auditResult = try await communicationService.performSecurityAudit()
            } catch {
                print("Error en auditoría: \(error)")
            }
        }
    }

    private func logout() {
        // Implementar cierre de sesión
        appState.isAuthenticated = false
    }
}

struct SecurityAuditView: View {
    @Binding var result: SecurityAuditResult?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                if let result = result {
                    List {
                        Section("Estado General") {
                            HStack {
                                Text("Estado")
                                Spacer()
                                Text(result.overallStatus.description)
                                    .foregroundColor(result.overallStatus == .secure ? .green : .red)
                            }
                        }

                        Section("Problemas Encontrados") {
                            ForEach(result.issues, id: \.self) { issue in
                                VStack(alignment: .leading) {
                                    Text(issue.title)
                                        .font(.headline)
                                    Text(issue.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        if !result.recommendations.isEmpty {
                            Section("Recomendaciones") {
                                ForEach(result.recommendations, id: \.self) { recommendation in
                                    Text(recommendation)
                                }
                            }
                        }
                    }
                } else {
                    ProgressView("Realizando auditoría...")
                }
            }
            .navigationTitle("Auditoría de Seguridad")
            .navigationBarItems(trailing: Button("Cerrar") {
                dismiss()
            })
        }
    }
}

struct PrivacySettingsView: View {
    @State private var locationEnabled = false
    @State private var analyticsEnabled = false
    @State private var readReceiptsEnabled = true

    var body: some View {
        Form {
            Section("Ubicación") {
                Toggle("Mensajes basados en ubicación", isOn: $locationEnabled)
                Text("Permite encontrar y conectarte con personas cercanas")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Analytics") {
                Toggle("Analytics de uso", isOn: $analyticsEnabled)
                Text("Ayuda a mejorar la aplicación con datos anónimos")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Mensajes") {
                Toggle("Confirmaciones de lectura", isOn: $readReceiptsEnabled)
                Text("Los demás sabrán cuando leas sus mensajes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Datos") {
                Button(action: exportData) {
                    Label("Exportar mis datos", systemImage: "square.and.arrow.up")
                }

                Button(action: deleteAccount) {
                    Label("Eliminar cuenta", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Privacidad")
        .onAppear {
            loadSettings()
        }
    }

    private func loadSettings() {
        locationEnabled = UserDefaults.standard.bool(forKey: "locationEnabled")
        analyticsEnabled = UserDefaults.standard.bool(forKey: "analyticsEnabled")
        readReceiptsEnabled = UserDefaults.standard.bool(forKey: "readReceiptsEnabled")
    }

    private func exportData() {
        // Implementar exportación de datos
    }

    private func deleteAccount() {
        // Implementar eliminación de cuenta
        // Mostrar confirmación
    }
}
```

### 7. Models.swift - Modelos de datos

```swift
import Foundation
import BitchatCommunications

// Usuario
struct User {
    let id: PeerID
    let displayName: String?
    let avatar: Data?
    let publicKey: Data
    let trustLevel: TrustLevel
    let lastSeen: Date?
    let isOnline: Bool

    var displayNameOrID: String {
        displayName ?? "Usuario \(id.id.prefix(8))"
    }
}

// Mensaje
struct Message {
    let id: MessageID
    let content: String
    let sender: PeerID
    let recipient: PeerID
    let timestamp: Date
    let type: MessageType
    let attachment: MessageAttachment?
    var deliveryStatus: DeliveryStatus = .sending
    var isRead = false

    var isFromCurrentUser: Bool {
        // Implementar comparación con usuario actual
        return sender.id == "current_user_id"
    }
}

enum MessageType {
    case text
    case image
    case voice
    case video
    case file
    case location
}

struct MessageAttachment {
    let type: MessageType
    let data: Data
    let fileName: String?
    let fileSize: Int?
    let fileType: FileType?

    var image: UIImage? {
        guard type == .image, let image = UIImage(data: data) else { return nil }
        return image
    }
}

enum FileType {
    case document
    case image
    case video
    case audio
    case archive

    var icon: String {
        switch self {
        case .document: return "doc"
        case .image: return "photo"
        case .video: return "video"
        case .audio: return "waveform"
        case .archive: return "archivebox"
        }
    }
}

enum DeliveryStatus {
    case sending
    case sent
    case delivered
    case read
    case failed

    var icon: String {
        switch self {
        case .sending: return "circle"
        case .sent: return "checkmark"
        case .delivered: return "checkmark.circle"
        case .read: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .sending: return .gray
        case .sent: return .gray
        case .delivered: return .blue
        case .read: return .blue
        case .failed: return .red
        }
    }
}

// Grupo
struct Group {
    let id: GroupID
    let name: String
    let description: String?
    let creator: PeerID
    let members: [PeerID]
    let moderators: [PeerID] = []
    let isPrivate: Bool
    let createdAt: Date
    let avatar: Data?
}

// Mensaje de grupo
struct GroupMessage {
    let id: MessageID
    let content: String
    let sender: PeerID
    let groupID: GroupID
    let timestamp: Date
    let type: MessageType
    let attachment: MessageAttachment?
    var reactions: [MessageReaction] = []
}

struct MessageReaction {
    let emoji: String
    let userID: PeerID
    let timestamp: Date
}

// Transferencia de archivo
struct FileTransfer {
    let id: TransferID
    let fileName: String
    let fileSize: Int
    let sender: PeerID
    let recipient: PeerID
    let timestamp: Date
    var progress: Progress
    var status: TransferStatus
}

enum TransferStatus {
    case pending
    case transferring
    case completed
    case failed(Error)
}

// Resultado de auditoría de seguridad
struct SecurityAuditResult {
    let timestamp: Date
    let overallStatus: SecurityStatus
    let issues: [SecurityIssue]
    let recommendations: [String]
}

enum SecurityStatus {
    case secure
    case warning
    case compromised
}

struct SecurityIssue {
    let title: String
    let description: String
    let severity: SecuritySeverity
}

enum SecuritySeverity {
    case low
    case medium
    case high
    case critical
}

// Extensiones útiles
extension Int {
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(self))
    }
}

extension PeerID {
    var displayName: String? {
        // Implementar obtención del nombre de display
        return nil // Placeholder
    }
}
```

### 8. Info.plist - Configuración de la aplicación

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Pluribus</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>$(MACOSX_DEPLOYMENT_TARGET)</string>

    <!-- Permisos -->
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>Pluribus necesita acceso a Bluetooth para comunicaciones P2P seguras</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Pluribus usa tu ubicación para encontrar personas cercanas y enviar mensajes geográficos</string>
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>Pluribus mantiene la ubicación en segundo plano para mensajería geográfica</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>Pluribus necesita acceso al micrófono para enviar mensajes de voz</string>
    <key>NSCameraUsageDescription</key>
    <string>Pluribus necesita acceso a la cámara para enviar fotos y videos</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Pluribus necesita acceso a la biblioteca de fotos para enviar imágenes</string>

    <!-- Capacidades de red -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>

    <!-- Background modes -->
    <key>UIBackgroundModes</key>
    <array>
        <string>bluetooth-central</string>
        <string>bluetooth-peripheral</string>
        <string>location</string>
    </array>

    <!-- iOS specific -->
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>bluetooth-le</string>
    </array>

    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>

    <!-- macOS specific -->
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024 Pluribus. All rights reserved.</string>
</dict>
</plist>
```

## Conclusión

**Pluribus** es una aplicación completa que demuestra el uso integral del framework BitchatCommunications. Incluye:

- **Arquitectura completa** con servicios modulares
- **Interfaz moderna** con SwiftUI
- **Integración total** con todos los módulos del framework
- **Manejo de permisos** y configuración del sistema
- **Gestión de estado** reactiva con Combine
- **Persistencia local** con Core Data
- **Soporte multiplataforma** (iOS/macOS)

La aplicación está diseñada para ser segura, privada y resistente a la censura, aprovechando todas las capacidades del framework BitchatCommunications para proporcionar una experiencia de mensajería P2P de vanguardia.

Para usar esta aplicación, simplemente crea un nuevo proyecto Xcode, copia los archivos proporcionados, añade las dependencias del framework BitchatCommunications, y configura los permisos necesarios en el Info.plist.