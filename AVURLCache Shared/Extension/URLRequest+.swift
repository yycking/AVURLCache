//
//  URLRequest+.swift
//  AVURLCache
//
//  Created by Wayne Yeh on 2020/9/23.
//

import Foundation

extension URLRequest {
    mutating func setRange(from: Int64?, to: Int64?) {
        var fields = self.allHTTPHeaderFields ?? [:]
        let start = from.flatMap{String($0)} ?? ""
        let end = to.flatMap{String($0)} ?? ""
        fields["Range"] = "bytes=\(start)-\(end)"
        self.allHTTPHeaderFields = fields
    }
    
    var range: String? {
        guard
            let fields = self.allHTTPHeaderFields,
            let range = fields["Range"],
            let result = range.split(separator: "=").last else {
            return nil
        }
        return String(result)
    }
    
    var rangeStart: Int64? {
        set {
            setRange(from: newValue, to: rangeEnd)
        }
        get {
            if let range = range?.split(separator: "-") {
                if let first = range.first, let start = Int64(first) {
                    return start
                }
            }
            return nil
        }
    }
    
    var rangeEnd: Int64? {
        set {
            setRange(from: rangeStart, to: newValue)
        }
        get {
            if let range = range?.split(separator: "-") {
                if let end = range.last, let last = Int64(end) {
                    return last
                }
            }
            return nil
        }
    }
}
