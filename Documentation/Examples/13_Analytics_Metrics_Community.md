# 13 - Analytics, Métricas y Comunidad

## Descripción

Este ejemplo muestra cómo implementar un sistema completo de analytics y métricas en BitchatCommunications. Aprenderás a recopilar métricas de rendimiento, analizar patrones de uso de la comunidad, generar insights accionables, y crear dashboards que ayuden a entender y mejorar la experiencia del usuario y la salud de la red.

**Beneficios:**
- Métricas detalladas de rendimiento y uso
- Insights sobre comportamiento de la comunidad
- Detección automática de problemas de red
- Optimización basada en datos de uso real
- Dashboards personalizables para diferentes roles
- Análisis predictivo de tendencias
- Métricas de privacidad que no comprometen datos sensibles

**Consideraciones:**
- Implementa agregación apropiada para preservar privacidad
- Considera el impacto en rendimiento de recopilar métricas
- Proporciona opciones de opt-out para usuarios
- Implementa retención limitada de datos históricos
- Maneja apropiadamente datos sensibles en métricas
- Considera el costo de almacenamiento de métricas
- Implementa compresión de datos históricos

## Pasos Previos Obligatorios

1. **Completar Configuración Básica** (Ejemplo 01)
2. **Implementar TransportCoordinator** (Ejemplo 10)
3. **Crear AnalyticsEngine** y **MetricsCollector**
4. **Configurar políticas de privacidad y retención**
5. **Implementar DashboardManager**

## Código de Implementación

```swift
import BitchatCore
import BitchatBLE
import BitchatNostr
import Combine
import Charts

// Engine principal de analytics
class AnalyticsEngine {
    private let metricsCollector: MetricsCollector
    private let communityAnalyzer: CommunityAnalyzer
    private let performanceMonitor: PerformanceMonitor
    private let privacyManager: PrivacyManager

    // Estado de analytics
    private var collectedMetrics: [MetricType: [MetricDataPoint]] = [:]
    private var communityInsights: [CommunityInsight] = []
    private var performanceReports: [PerformanceReport] = []

    // Publishers para eventos
    private let metricsUpdatedPublisher = PassthroughSubject<MetricType, Never>()
    private let insightGeneratedPublisher = PassthroughSubject<CommunityInsight, Never>()
    private let performanceAlertPublisher = PassthroughSubject<PerformanceAlert, Never>()

    var metricsUpdated: AnyPublisher<MetricType, Never> {
        metricsUpdatedPublisher.eraseToAnyPublisher()
    }

    var insightGenerated: AnyPublisher<CommunityInsight, Never> {
        insightGeneratedPublisher.eraseToAnyPublisher()
    }

    var performanceAlert: AnyPublisher<PerformanceAlert, Never> {
        performanceAlertPublisher.eraseToAnyPublisher()
    }

    init() {
        self.metricsCollector = MetricsCollector()
        self.communityAnalyzer = CommunityAnalyzer()
        self.performanceMonitor = PerformanceMonitor()
        self.privacyManager = PrivacyManager()

        setupPeriodicTasks()
    }

    // MARK: - Recopilación de Métricas

    // Iniciar recopilación de métricas
    func startMetricsCollection() {
        metricsCollector.startCollection()
        performanceMonitor.startMonitoring()

        print("📊 Recopilación de métricas iniciada")
    }

    // Detener recopilación de métricas
    func stopMetricsCollection() {
        metricsCollector.stopCollection()
        performanceMonitor.stopMonitoring()

        print("📊 Recopilación de métricas detenida")
    }

    // Registrar evento personalizado
    func trackEvent(_ event: AnalyticsEvent) {
        guard privacyManager.shouldTrackEvent(event) else { return }

        let metric = MetricDataPoint(
            type: .custom(event.name),
            value: event.value,
            timestamp: Date(),
            metadata: event.metadata
        )

        addMetricDataPoint(metric)
    }

    // MARK: - Análisis de Comunidad

    // Generar insights de comunidad
    func generateCommunityInsights() async {
        let insights = await communityAnalyzer.analyzeCommunity()

        for insight in insights {
            communityInsights.append(insight)
            insightGeneratedPublisher.send(insight)
        }

        print("🔍 \(insights.count) insights de comunidad generados")
    }

    // Obtener métricas de engagement
    func getEngagementMetrics(timeRange: TimeRange) async -> EngagementMetrics {
        return await communityAnalyzer.calculateEngagementMetrics(timeRange: timeRange)
    }

    // Analizar patrones de uso
    func analyzeUsagePatterns() async -> [UsagePattern] {
        return await communityAnalyzer.identifyUsagePatterns()
    }

    // MARK: - Monitoreo de Rendimiento

    // Generar reporte de rendimiento
    func generatePerformanceReport() async -> PerformanceReport {
        let report = await performanceMonitor.generateReport()

        performanceReports.append(report)

        // Verificar alertas
        if let alert = report.generateAlert() {
            performanceAlertPublisher.send(alert)
        }

        print("📈 Reporte de rendimiento generado")

        return report
    }

    // Obtener métricas de red
    func getNetworkMetrics() async -> NetworkMetrics {
        return await performanceMonitor.getNetworkMetrics()
    }

    // MARK: - Dashboards y Visualización

    // Crear dashboard personalizado
    func createDashboard(for role: UserRole) -> Dashboard {
        let config = DashboardConfiguration(for: role)
        return Dashboard(configuration: config, analyticsEngine: self)
    }

    // Obtener datos para gráfico
    func getChartData(for metric: MetricType, timeRange: TimeRange) -> ChartData {
        let dataPoints = collectedMetrics[metric] ?? []
        let filteredPoints = dataPoints.filter { timeRange.contains($0.timestamp) }

        return ChartData(
            metric: metric,
            dataPoints: filteredPoints,
            timeRange: timeRange
        )
    }

    // MARK: - Utilidades de Métricas

    // Obtener estadísticas de métrica
    func getMetricStatistics(for type: MetricType, timeRange: TimeRange) -> MetricStatistics {
        let dataPoints = collectedMetrics[type] ?? []
        let filteredPoints = dataPoints.filter { timeRange.contains($0.timestamp) }

        guard !filteredPoints.isEmpty else {
            return MetricStatistics.empty
        }

        let values = filteredPoints.map { $0.value }
        let average = values.reduce(0, +) / Double(values.count)
        let min = values.min() ?? 0
        let max = values.max() ?? 0
        let median = calculateMedian(values)

        return MetricStatistics(
            count: filteredPoints.count,
            average: average,
            min: min,
            max: max,
            median: median,
            trend: calculateTrend(filteredPoints)
        )
    }

    // MARK: - Privacidad y Cumplimiento

    // Verificar cumplimiento de privacidad
    func auditPrivacyCompliance() async -> PrivacyAuditResult {
        return await privacyManager.auditCompliance()
    }

    // Limpiar datos antiguos
    func cleanupOldData(olderThan days: Int) async {
        let cutoffDate = Date().addingTimeInterval(-Double(days) * 24 * 3600)

        for (type, dataPoints) in collectedMetrics {
            collectedMetrics[type] = dataPoints.filter { $0.timestamp > cutoffDate }
        }

        communityInsights = communityInsights.filter { $0.timestamp > cutoffDate }
        performanceReports = performanceReports.filter { $0.timestamp > cutoffDate }

        print("🧹 Datos antiguos limpiados (>\(days) días)")
    }

    // MARK: - Utilidades Privadas

    private func addMetricDataPoint(_ point: MetricDataPoint) {
        collectedMetrics[point.type, default: []].append(point)

        // Limitar tamaño del buffer
        if collectedMetrics[point.type]!.count > 1000 {
            collectedMetrics[point.type]!.removeFirst()
        }

        metricsUpdatedPublisher.send(point.type)
    }

    private func calculateMedian(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        let count = sorted.count

        if count % 2 == 0 {
            return (sorted[count/2 - 1] + sorted[count/2]) / 2
        } else {
            return sorted[count/2]
        }
    }

    private func calculateTrend(_ points: [MetricDataPoint]) -> Trend {
        guard points.count >= 2 else { return .stable }

        let recent = Array(points.suffix(10))
        guard recent.count >= 2 else { return .stable }

        let firstHalf = recent.prefix(recent.count / 2)
        let secondHalf = recent.suffix(recent.count / 2)

        let firstAvg = firstHalf.map { $0.value }.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.map { $0.value }.reduce(0, +) / Double(secondHalf.count)

        let change = (secondAvg - firstAvg) / firstAvg

        if change > 0.05 {
            return .increasing
        } else if change < -0.05 {
            return .decreasing
        } else {
            return .stable
        }
    }

    private func setupPeriodicTasks() {
        // Generar insights cada hora
        Timer.publish(every: 3600, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.generateCommunityInsights() }
            }
            .store(in: &cancellables)

        // Generar reportes de rendimiento cada 30 minutos
        Timer.publish(every: 1800, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.generatePerformanceReport() }
            }
            .store(in: &cancellables)

        // Limpiar datos antiguos diariamente
        Timer.publish(every: 86400, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.cleanupOldData(olderThan: 30) }
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()
}

// Recopilador de métricas
class MetricsCollector {
    private var isCollecting = false
    private var timers: [String: Timer] = [:]

    func startCollection() {
        guard !isCollecting else { return }

        isCollecting = true

        // Métricas de mensajes
        startMetricTimer("messageRate", interval: 60) {
            // Recopilar tasa de mensajes
            let messageCount = 0 // Implementar conteo real
            return Double(messageCount)
        }

        // Métricas de conexiones
        startMetricTimer("connectionCount", interval: 30) {
            // Recopilar número de conexiones activas
            let connectionCount = 0 // Implementar conteo real
            return Double(connectionCount)
        }

        // Métricas de batería
        startMetricTimer("batteryLevel", interval: 300) {
            // Recopilar nivel de batería
            return Double(UIDevice.current.batteryLevel)
        }

        print("📊 Recopilación de métricas iniciada")
    }

    func stopCollection() {
        isCollecting = false

        timers.values.forEach { $0.invalidate() }
        timers.removeAll()

        print("📊 Recopilación de métricas detenida")
    }

    private func startMetricTimer(_ name: String, interval: TimeInterval, collector: @escaping () -> Double) {
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            let value = collector()
            let metric = MetricDataPoint(
                type: .system(name),
                value: value,
                timestamp: Date(),
                metadata: [:]
            )

            // Enviar a analytics engine
            NotificationCenter.default.post(
                name: .metricCollected,
                object: nil,
                userInfo: ["metric": metric]
            )
        }

        timers[name] = timer
    }
}

// Analizador de comunidad
class CommunityAnalyzer {
    func analyzeCommunity() async -> [CommunityInsight] {
        var insights: [CommunityInsight] = []

        // Análisis de engagement
        let engagementInsight = await analyzeEngagement()
        insights.append(engagementInsight)

        // Análisis de crecimiento
        let growthInsight = await analyzeGrowth()
        insights.append(growthInsight)

        // Análisis de retención
        let retentionInsight = await analyzeRetention()
        insights.append(retentionInsight)

        // Análisis de salud de red
        let healthInsight = await analyzeNetworkHealth()
        insights.append(healthInsight)

        return insights
    }

    func calculateEngagementMetrics(timeRange: TimeRange) async -> EngagementMetrics {
        // Implementar cálculo de métricas de engagement
        return EngagementMetrics(
            dailyActiveUsers: 0,
            messagesPerUser: 0,
            sessionDuration: 0,
            retentionRate: 0
        )
    }

    func identifyUsagePatterns() async -> [UsagePattern] {
        // Implementar identificación de patrones de uso
        return []
    }

    private func analyzeEngagement() async -> CommunityInsight {
        // Implementar análisis de engagement
        return CommunityInsight(
            type: .engagement,
            title: "Análisis de Engagement",
            description: "La comunidad muestra niveles saludables de engagement",
            severity: .info,
            recommendations: ["Continuar con las estrategias actuales"],
            timestamp: Date()
        )
    }

    private func analyzeGrowth() async -> CommunityInsight {
        // Implementar análisis de crecimiento
        return CommunityInsight(
            type: .growth,
            title: "Crecimiento de Comunidad",
            description: "La comunidad está creciendo a un ritmo constante",
            severity: .info,
            recommendations: ["Considerar estrategias de expansión"],
            timestamp: Date()
        )
    }

    private func analyzeRetention() async -> CommunityInsight {
        // Implementar análisis de retención
        return CommunityInsight(
            type: .retention,
            title: "Retención de Usuarios",
            description: "Las tasas de retención son satisfactorias",
            severity: .info,
            recommendations: ["Monitorear tendencias de retención"],
            timestamp: Date()
        )
    }

    private func analyzeNetworkHealth() async -> CommunityInsight {
        // Implementar análisis de salud de red
        return CommunityInsight(
            type: .networkHealth,
            title: "Salud de Red",
            description: "La red opera dentro de parámetros normales",
            severity: .info,
            recommendations: ["Continuar monitoreo regular"],
            timestamp: Date()
        )
    }
}

// Monitor de rendimiento
class PerformanceMonitor {
    func generateReport() async -> PerformanceReport {
        let networkMetrics = await getNetworkMetrics()
        let systemMetrics = await getSystemMetrics()

        return PerformanceReport(
            timestamp: Date(),
            networkMetrics: networkMetrics,
            systemMetrics: systemMetrics,
            alerts: []
        )
    }

    func getNetworkMetrics() async -> NetworkMetrics {
        // Implementar recopilación de métricas de red
        return NetworkMetrics(
            latency: 0,
            throughput: 0,
            packetLoss: 0,
            connectionCount: 0
        )
    }

    func getSystemMetrics() async -> SystemMetrics {
        // Implementar recopilación de métricas del sistema
        return SystemMetrics(
            cpuUsage: 0,
            memoryUsage: 0,
            batteryLevel: 0,
            storageUsed: 0
        )
    }

    func startMonitoring() {
        // Iniciar monitoreo continuo
    }

    func stopMonitoring() {
        // Detener monitoreo
    }
}

// Manager de privacidad
class PrivacyManager {
    func shouldTrackEvent(_ event: AnalyticsEvent) -> Bool {
        // Verificar preferencias de privacidad del usuario
        return true // Placeholder
    }

    func auditCompliance() async -> PrivacyAuditResult {
        // Implementar auditoría de cumplimiento de privacidad
        return PrivacyAuditResult(
            compliant: true,
            issues: [],
            recommendations: []
        )
    }
}

// Estructuras de datos
enum MetricType: Hashable {
    case system(String)
    case custom(String)
    case message
    case connection
    case performance
}

struct MetricDataPoint {
    let type: MetricType
    let value: Double
    let timestamp: Date
    let metadata: [String: Any]
}

struct CommunityInsight {
    let type: InsightType
    let title: String
    let description: String
    let severity: InsightSeverity
    let recommendations: [String]
    let timestamp: Date
}

enum InsightType {
    case engagement, growth, retention, networkHealth, security
}

enum InsightSeverity {
    case info, warning, critical
}

struct PerformanceReport {
    let timestamp: Date
    let networkMetrics: NetworkMetrics
    let systemMetrics: SystemMetrics
    let alerts: [PerformanceAlert]

    func generateAlert() -> PerformanceAlert? {
        // Generar alertas basadas en métricas
        if networkMetrics.latency > 1000 {
            return PerformanceAlert(
                type: .highLatency,
                message: "Latencia de red elevada detectada",
                severity: .warning
            )
        }

        if systemMetrics.memoryUsage > 0.9 {
            return PerformanceAlert(
                type: .highMemoryUsage,
                message: "Uso alto de memoria detectado",
                severity: .critical
            )
        }

        return nil
    }
}

struct PerformanceAlert {
    let type: AlertType
    let message: String
    let severity: InsightSeverity
}

enum AlertType {
    case highLatency, highMemoryUsage, lowBattery, networkFailure
}

struct NetworkMetrics {
    let latency: TimeInterval
    let throughput: Double
    let packetLoss: Double
    let connectionCount: Int
}

struct SystemMetrics {
    let cpuUsage: Double
    let memoryUsage: Double
    let batteryLevel: Double
    let storageUsed: Double
}

struct EngagementMetrics {
    let dailyActiveUsers: Int
    let messagesPerUser: Double
    let sessionDuration: TimeInterval
    let retentionRate: Double
}

struct UsagePattern {
    let pattern: String
    let frequency: Double
    let description: String
}

struct MetricStatistics {
    let count: Int
    let average: Double
    let min: Double
    let max: Double
    let median: Double
    let trend: Trend

    static let empty = MetricStatistics(count: 0, average: 0, min: 0, max: 0, median: 0, trend: .stable)
}

enum Trend {
    case increasing, decreasing, stable
}

struct TimeRange {
    let start: Date
    let end: Date

    func contains(_ date: Date) -> Bool {
        return date >= start && date <= end
    }

    static let last24Hours = TimeRange(
        start: Date().addingTimeInterval(-24 * 3600),
        end: Date()
    )

    static let last7Days = TimeRange(
        start: Date().addingTimeInterval(-7 * 24 * 3600),
        end: Date()
    )

    static let last30Days = TimeRange(
        start: Date().addingTimeInterval(-30 * 24 * 3600),
        end: Date()
    )
}

struct AnalyticsEvent {
    let name: String
    let value: Double
    let metadata: [String: Any]
}

enum UserRole {
    case user, moderator, admin, developer
}

struct DashboardConfiguration {
    let role: UserRole
    let visibleMetrics: [MetricType]
    let refreshInterval: TimeInterval
    let chartTypes: [ChartType]

    init(for role: UserRole) {
        self.role = role

        switch role {
        case .user:
            self.visibleMetrics = [.message, .connection]
            self.refreshInterval = 300
            self.chartTypes = [.line, .bar]
        case .moderator:
            self.visibleMetrics = [.message, .connection, .performance]
            self.refreshInterval = 180
            self.chartTypes = [.line, .bar, .pie]
        case .admin:
            self.visibleMetrics = MetricType.allCases
            self.refreshInterval = 60
            self.chartTypes = ChartType.allCases
        case .developer:
            self.visibleMetrics = MetricType.allCases
            self.refreshInterval = 30
            self.chartTypes = ChartType.allCases
        }
    }
}

enum ChartType: CaseIterable {
    case line, bar, pie, area
}

struct ChartData {
    let metric: MetricType
    let dataPoints: [MetricDataPoint]
    let timeRange: TimeRange
}

struct PrivacyAuditResult {
    let compliant: Bool
    let issues: [String]
    let recommendations: [String]
}

// Dashboard
class Dashboard {
    let configuration: DashboardConfiguration
    private let analyticsEngine: AnalyticsEngine
    private var charts: [ChartView] = []

    init(configuration: DashboardConfiguration, analyticsEngine: AnalyticsEngine) {
        self.configuration = configuration
        self.analyticsEngine = analyticsEngine

        setupCharts()
    }

    private func setupCharts() {
        for metric in configuration.visibleMetrics {
            for chartType in configuration.chartTypes {
                let chartData = analyticsEngine.getChartData(
                    for: metric,
                    timeRange: .last24Hours
                )

                let chart = ChartView(type: chartType, data: chartData)
                charts.append(chart)
            }
        }
    }

    func refreshData() {
        for chart in charts {
            let updatedData = analyticsEngine.getChartData(
                for: chart.data.metric,
                timeRange: .last24Hours
            )
            chart.updateData(updatedData)
        }
    }

    func getStatistics(for metric: MetricType) -> MetricStatistics {
        return analyticsEngine.getMetricStatistics(for: metric, timeRange: .last24Hours)
    }
}

// Vista de gráfico
class ChartView {
    let type: ChartType
    let data: ChartData

    init(type: ChartType, data: ChartData) {
        self.type = type
        self.data = data
    }

    func updateData(_ newData: ChartData) {
        // Actualizar datos del gráfico
    }
}

// Controlador de UI para analytics
class AnalyticsViewController: UIViewController {
    private let analyticsEngine: AnalyticsEngine
    private var dashboard: Dashboard!
    private var cancellables = Set<AnyCancellable>()

    init(analyticsEngine: AnalyticsEngine) {
        self.analyticsEngine = analyticsEngine
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        startAnalytics()
    }

    private func setupUI() {
        // Crear UI para dashboard de analytics
        // Gráficos, métricas, insights
        dashboard = analyticsEngine.createDashboard(for: .admin)
    }

    private func setupBindings() {
        // Observar actualizaciones de métricas
        analyticsEngine.metricsUpdated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] metricType in
                self?.updateMetricDisplay(metricType)
            }
            .store(in: &cancellables)

        // Observar insights generados
        analyticsEngine.insightGenerated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] insight in
                self?.displayInsight(insight)
            }
            .store(in: &cancellables)

        // Observar alertas de rendimiento
        analyticsEngine.performanceAlert
            .receive(on: DispatchQueue.main)
            .sink { [weak self] alert in
                self?.displayPerformanceAlert(alert)
            }
            .store(in: &cancellables)
    }

    private func startAnalytics() {
        analyticsEngine.startMetricsCollection()

        // Generar insights iniciales
        Task {
            await analyticsEngine.generateCommunityInsights()
            _ = await analyticsEngine.generatePerformanceReport()
        }
    }

    @objc func refreshDashboard() {
        dashboard.refreshData()
        updateAllDisplays()
    }

    @objc func showEngagementMetrics() {
        Task {
            let metrics = await analyticsEngine.getEngagementMetrics(timeRange: .last7Days)
            displayEngagementMetrics(metrics)
        }
    }

    @objc func showUsagePatterns() {
        Task {
            let patterns = await analyticsEngine.analyzeUsagePatterns()
            displayUsagePatterns(patterns)
        }
    }

    @objc func auditPrivacy() {
        Task {
            let result = await analyticsEngine.auditPrivacyCompliance()
            displayPrivacyAudit(result)
        }
    }

    private func updateMetricDisplay(_ metricType: MetricType) {
        let stats = dashboard.getStatistics(for: metricType)
        // Actualizar UI con estadísticas
        print("Métrica actualizada: \(metricType) - Promedio: \(stats.average)")
    }

    private func updateAllDisplays() {
        // Actualizar todos los gráficos y métricas
        dashboard.refreshData()
    }

    private func displayInsight(_ insight: CommunityInsight) {
        // Mostrar insight en UI
        print("Insight generado: \(insight.title) - \(insight.description)")
    }

    private func displayPerformanceAlert(_ alert: PerformanceAlert) {
        // Mostrar alerta en UI
        let alertController = UIAlertController(
            title: "Alerta de Rendimiento",
            message: alert.message,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }

    private func displayEngagementMetrics(_ metrics: EngagementMetrics) {
        // Mostrar métricas de engagement
        print("Métricas de engagement: DAU=\(metrics.dailyActiveUsers), Retención=\(metrics.retentionRate)")
    }

    private func displayUsagePatterns(_ patterns: [UsagePattern]) {
        // Mostrar patrones de uso
        for pattern in patterns {
            print("Patrón: \(pattern.pattern) - Frecuencia: \(pattern.frequency)")
        }
    }

    private func displayPrivacyAudit(_ result: PrivacyAuditResult) {
        // Mostrar resultados de auditoría de privacidad
        if result.compliant {
            showSuccess("Auditoría de privacidad: Cumple con regulaciones")
        } else {
            showError("Auditoría de privacidad: \(result.issues.count) problemas encontrados")
        }
    }

    private func showSuccess(_ message: String) {
        let alert = UIAlertController(title: "Éxito", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// Extensiones para notificaciones
extension Notification.Name {
    static let metricCollected = Notification.Name("metricCollected")
}
```

## Notas Adicionales

- Implementa agregación de datos para preservar privacidad
- Considera el impacto en rendimiento de recopilar métricas detalladas
- Proporciona opciones claras de opt-out para usuarios
- Implementa retención limitada de datos históricos
- Maneja apropiadamente datos sensibles en métricas
- Considera el costo de almacenamiento de métricas a largo plazo
- Implementa compresión automática de datos históricos antiguos
- Proporciona exportación de datos para análisis externos cuando sea apropiado