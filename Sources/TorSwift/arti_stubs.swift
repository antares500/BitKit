import Foundation

// Export C symbols expected by TorManager via @_cdecl so the package links
// successfully on platforms where the real Arti library isn't provided.

@_cdecl("arti_start")
public func arti_start_c(_ dataDir: UnsafePointer<CChar>?, _ socksPort: UInt16) -> Int32 {
    // No-op stub
    return 0
}

@_cdecl("arti_stop")
public func arti_stop_c() -> Int32 { 0 }

@_cdecl("arti_is_running")
public func arti_is_running_c() -> Int32 { 0 }

@_cdecl("arti_bootstrap_progress")
public func arti_bootstrap_progress_c() -> Int32 { 100 }

@_cdecl("arti_bootstrap_summary")
public func arti_bootstrap_summary_c(_ buf: UnsafeMutablePointer<CChar>?, _ len: Int32) -> Int32 {
    guard let buf = buf, len > 0 else { return 0 }
    let s = "arti-stub"
    let bytes = Array(s.utf8.prefix(Int(len - 1)))
    for i in 0..<bytes.count { buf[i] = CChar(bitPattern: bytes[i]) }
    buf[Int(min(Int(len) - 1, bytes.count))] = 0
    return Int32(bytes.count)
}

@_cdecl("arti_go_dormant")
public func arti_go_dormant_c() -> Int32 { 0 }

@_cdecl("arti_wake")
public func arti_wake_c() -> Int32 { 0 }
