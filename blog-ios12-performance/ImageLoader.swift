//
//  ImageLoader.swift
//  blog-ios12-performance
//
//  Created by ttillage on 6/8/18.
//  Copyright © 2018 CapTech. All rights reserved.
//

import UIKit

final class ImageLoader {
    
    let session = URLSession(configuration: .ephemeral)
    private(set) var cache: [URL : UIImage] = [:]
    
    init() {
        let imageData = DiskCache.loadAll(folder: "Images")
        self.cache = ImageLoader.convertToCache(imageData)
    }
    
    func load(url: URL, completion: @escaping (URL, UIImage?) -> ()) {
        if let image = self.cache[url] {
            print("Loaded cached image for \(url.absoluteString)")
            completion(url, image)
        } else {
            self.session.dataTask(with: url, completionHandler: { data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    print("Downloaded image for \(url.absoluteString)")
                    self.cache[url] = image
                    DiskCache.save(data: data, folder: "Images", filename: url.cacheKey)
                    
                    DispatchQueue.main.async {
                        completion(url, image)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(url, nil)
                    }
                }
            }).resume()
        }
    }
    
    private static func convertToCache(_ input: [(data: Data, filename: String)]) -> [URL : UIImage] {
        var cache: [URL : UIImage] = [:]
        for (data, filename) in input {
            if let url = URL.from(cacheKey: filename), let image = UIImage(data: data) {
                cache[url] = image
            }
        }
        return cache
    }
}

private extension URL {
    
    var cacheKey: String {
        return self.absoluteString.data(using: .utf8)!.base64EncodedString().base64ToFilenameSafeBase64()
    }
    
    static func from(cacheKey: String) -> URL? {
        let convertedKey = cacheKey.filenameSafeBase64ToBase64()
        if let urlData = Data(base64Encoded: convertedKey),
            let urlString = String(data: urlData, encoding: .utf8),
            let url = URL(string: urlString) {
            return url
        }
        
        return nil
    }
}

private extension String {
    
    func base64ToFilenameSafeBase64() -> String {
        return self.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "-")
    }
    
    func filenameSafeBase64ToBase64() -> String {
        return self.replacingOccurrences(of: "_", with: "/").replacingOccurrences(of: "-", with: "=")
    }
}
