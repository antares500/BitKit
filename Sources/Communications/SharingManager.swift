import Foundation
import BitCore

public protocol SharingDelegate: AnyObject {
    func didReceiveSharedContent(content: SharedContent)
}

public enum SharedContent {
    case text(String)
    case url(URL)
    case image(URL)
    case video(URL)
    case file(URL)
}

public class SharingManager {
    public weak var delegate: SharingDelegate?
    
    public init() {}
    
    // Process shared content from system sharing extensions
    public func processSharedContent(_ inputItems: [Any]) {
        for item in inputItems {
            if let itemProvider = item as? NSItemProvider {
                processItemProvider(itemProvider)
            }
        }
    }
    
    private func processItemProvider(_ provider: NSItemProvider) {
        if provider.hasItemConformingToTypeIdentifier("public.text") {
            provider.loadItem(forTypeIdentifier: "public.text", options: nil) { item, error in
                if let text = item as? String {
                    self.delegate?.didReceiveSharedContent(content: .text(text))
                }
            }
        } else if provider.hasItemConformingToTypeIdentifier("public.url") {
            provider.loadItem(forTypeIdentifier: "public.url", options: nil) { item, error in
                if let url = item as? URL {
                    self.delegate?.didReceiveSharedContent(content: .url(url))
                }
            }
        } else if provider.hasItemConformingToTypeIdentifier("public.image") {
            provider.loadItem(forTypeIdentifier: "public.image", options: nil) { item, error in
                if let url = item as? URL {
                    self.delegate?.didReceiveSharedContent(content: .image(url))
                }
            }
        } else if provider.hasItemConformingToTypeIdentifier("public.movie") {
            provider.loadItem(forTypeIdentifier: "public.movie", options: nil) { item, error in
                if let url = item as? URL {
                    self.delegate?.didReceiveSharedContent(content: .video(url))
                }
            }
        } else if provider.hasItemConformingToTypeIdentifier("public.data") {
            provider.loadItem(forTypeIdentifier: "public.data", options: nil) { item, error in
                if let url = item as? URL {
                    self.delegate?.didReceiveSharedContent(content: .file(url))
                }
            }
        }
    }
    
    // Create shareable content for system sharing
    public func createShareableContent(from message: BitMessage) -> [Any] {
        var items: [Any] = []
        
        // Since content is a String, treat it as text or try to parse as URL
        if let url = URL(string: message.content), url.scheme != nil {
            items.append(url)
        } else {
            items.append(message.content)
        }
        
        return items
    }
}