// PeerDisplayNameResolver.swift
import Foundation

public class PeerDisplayNameResolver {
    public static func resolve(_ peers: [(PeerID, String?, Bool)], selfNickname: String?) -> [PeerID: String] {
        // Resolve nicknames, handling duplicates and self
        var result: [PeerID: String] = [:]
        var usedNames: Set<String> = []
        
        for (peerID, nickname, _) in peers {
            var resolvedName = nickname ?? String(peerID.id.prefix(8))
            
            // Handle self nickname
            if let selfNickname = selfNickname, resolvedName == selfNickname {
                resolvedName = "You"
            }
            
            // Handle duplicates
            var counter = 1
            var uniqueName = resolvedName
            while usedNames.contains(uniqueName) {
                uniqueName = "\(resolvedName) (\(counter))"
                counter += 1
            }
            
            usedNames.insert(uniqueName)
            result[peerID] = uniqueName
        }
        
        return result
    }
}