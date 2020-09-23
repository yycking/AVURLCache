//
//  HTTPURLResponse+.swift
//  AVURLCache
//
//  Created by Wayne Yeh on 2020/9/22.
//

import Foundation
import CoreServices

extension HTTPURLResponse {
    convenience init(url URL: URL, contentLength length: Int64) {
        var mimeType: String?
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, URL.pathExtension as NSString, nil)?.takeRetainedValue() {
            if let type = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                mimeType = type as String
            }
        }
        var expectedContentLength = Int.max
        if expectedContentLength > length {
            expectedContentLength = Int(length)
        }
        self.init(url: URL, mimeType: mimeType, expectedContentLength: expectedContentLength, textEncodingName: nil)
        
    }
    
    var contentLength: Int64 {
        if let range = self.allHeaderFields["content-range"] as? String,
           let last = range.split(separator: "/").last,
           let length = Int64(last) {
            return length
        } else {
            return self.expectedContentLength
        }
    }
}
