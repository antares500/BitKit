# Ejemplo 16: Notificaciones Push y Alertas

Este ejemplo muestra cómo integrar notificaciones para alertas de mensajes entrantes.

```swift
let notificationService = NotificationService()
let router = MessageRouter()
notificationService.observeIncomingMessages(from: router)
// Ahora, cada mensaje entrante genera una alerta push.
```