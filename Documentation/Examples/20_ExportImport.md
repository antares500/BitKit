# Ejemplo 20: Exportación de Pruebas

```swift
let exportService = ExportService()
try exportService.exportConversation(messages: history, to: URL(fileURLWithPath: "/path/to/proof.json"))
```