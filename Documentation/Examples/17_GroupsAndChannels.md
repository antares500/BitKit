# Ejemplo 17: Grupos y Canales con Moderación

```swift
let groupManager = GroupManager()
let group = groupManager.createGroup(name: "Public Chat", isPublic: true, creator: "peer1")
groupManager.joinGroup(group.id, peer: "peer2")
groupManager.moderateGroup(group.id, action: .ban(peer: "badPeer"), by: "peer1")
```