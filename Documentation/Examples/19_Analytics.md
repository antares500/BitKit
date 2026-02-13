# Ejemplo 19: Analytics Opcionales

```swift
let analytics = AnalyticsService()
analytics.isEnabled = true
analytics.trackEvent("messageSent")
// Suscribirse a metricsPublisher para dashboards.
```