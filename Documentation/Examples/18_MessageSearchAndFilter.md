# Ejemplo 18: Búsqueda y Filtro de Mensajes

```swift
let router = MessageRouter()
let results = router.searchMessages(containing: "hello", from: "peer1")
let filtered = router.filterMessages(by: "peer1")
```