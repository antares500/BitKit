//
// NetworkActivationService.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation

/// Service for managing network activation state
public class NetworkActivationService {
    public static let shared = NetworkActivationService()

    public var activationAllowed: Bool = true
    public var userTorEnabled: Bool = false

    private init() {}
}