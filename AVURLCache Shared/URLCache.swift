//
//  URLCache.swift
//  AVURLCache
//
//  Created by Wayne Yeh on 2020/9/17.
//

import AVFoundation

class URLCache: NSObject {
    static let scheme = "HttpCache"
    
    private let sourceURL: URL!
    var url: URL {
        var components = URLComponents(url: sourceURL, resolvingAgainstBaseURL: false)
        components?.scheme = Self.scheme
        return components?.url ?? sourceURL
    }
    private var data: URLFile?
    
    init(url: URL) {
        self.sourceURL = url
        self.data = URLFile(url: url)
        super.init()
        self.timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(updateData(timer:)), userInfo: nil, repeats: true)
    }
    
    private var timer: Timer!
    deinit {
        timer.invalidate()
    }
    
    private var loadingRequests: [AVAssetResourceLoadingRequest] = []
}

extension URLCache {
    static var loaders: [URL: URLCache] = [:]
    static subscript(url: URL) -> URLCache {
        if let loader = loaders[url] {
            return loader
        }
        let loader = URLCache(url: url)
        loaders[url] = loader
        
        return loader
    }
}

extension URLCache: AVAssetResourceLoaderDelegate {
    @objc func updateData(timer: Timer) {
        loadingRequests = loadingRequests.filter { loadingRequest in
            guard !loadingRequest.isCancelled,
                !loadingRequest.isFinished else {
                return false
            }
            guard
                let data = data,
                let response = data.response else {
                return true
            }
            if let informationRequest = loadingRequest.contentInformationRequest {
                loadingRequest.response = response
                
                informationRequest.contentType = response.mimeType
                informationRequest.isByteRangeAccessSupported = true
                informationRequest.contentLength = response.contentLength
            }
            
            guard let dataRequest = loadingRequest.dataRequest else {
                loadingRequest.finishLoading()
                return false
            }
            let requestedOffset = UInt64(dataRequest.currentOffset)
            let requestedLength = Int(dataRequest.currentOffset - dataRequest.requestedOffset) + dataRequest.requestedLength
            if requestedOffset + UInt64(requestedLength) == dataRequest.currentOffset {
                loadingRequest.finishLoading()
                return false
            }
            data.loadData(from: requestedOffset, length: requestedLength) {[weak dataRequest] data in
                guard let dataRequest = dataRequest,
                      !loadingRequest.isCancelled,
                      !loadingRequest.isFinished else {
                    return
                }
                dataRequest.respond(with: data)
                guard data.count == requestedLength else {
                    return
                }
                loadingRequest.finishLoading()
            }
            return true
        }
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        loadingRequests.append(loadingRequest)
        
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        loadingRequests.removeAll(where: {$0 == loadingRequest})
    }
}
