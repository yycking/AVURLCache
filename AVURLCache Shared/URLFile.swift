//
//  URLFile.swift
//  AVURLCache
//
//  Created by Wayne Yeh on 2020/9/22.
//

import Foundation

class URLFile: NSObject {
    let queue = DispatchQueue(label: "URLFile")
    private lazy var session: URLSession = {
        return URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }()
    private var dataTask: URLSessionDataTask?
    private var fileHandle: FileHandle?
    private var localFile: URL
    private var tempFile: URL
    var response: HTTPURLResponse?
    
    init?(url: URL) {
        let fileName = url.lastPathComponent
        guard let cache = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        localFile = cache.appendingPathComponent(fileName)
        tempFile = cache.appendingPathComponent("_\(fileName)")
        
        super.init()
        guard FileManager.default.fileExists(atPath: localFile.path) else {
            var offset: UInt64 = 0
            if FileManager.default.fileExists(atPath: tempFile.path) {
                let attributes = try? FileManager.default.attributesOfItem(atPath: tempFile.path)
                offset = attributes?[.size] as? UInt64 ?? 0
            } else {
                FileManager.default.createFile(atPath: tempFile.path, contents: nil, attributes: nil)
            }
            fileHandle = FileHandle(forUpdatingAtPath: tempFile.path)
            
            var request = URLRequest(url: url)
            request.rangeStart = Int64(offset)
            
            let dataTask = self.session.dataTask(with: request)
            dataTask.resume()
            self.dataTask = dataTask
            
            return
        }
        fileHandle = FileHandle(forReadingAtPath: localFile.path)
        let attributes = try? FileManager.default.attributesOfItem(atPath: localFile.path)
        let length = attributes?[.size] as? UInt64 ?? 0
        self.response = HTTPURLResponse(url: url, contentLength: Int64(length))
    }
    
    deinit {
        dataTask?.cancel()
        fileHandle?.closeFile()
    }
}

extension URLFile: URLSessionDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        queue.async { [weak self] in
            guard let self = self else { return }
            if let url = self.response?.url {
                let length = self.fileHandle?.seekToEndOfFile() ?? 0
                self.response = HTTPURLResponse(url: url, contentLength: Int64(length))
            }
            
            self.fileHandle?.closeFile()
            
            try? FileManager.default.moveItem(at: self.tempFile, to: self.localFile)
            self.fileHandle = FileHandle(forReadingAtPath: self.localFile.path)
        }
    }
}

extension URLFile: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        queue.async { [weak fileHandle] in
            guard let fileHandle = fileHandle else { return }
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 416 {
                completionHandler(.cancel)
                
                if let url = response.url {
                    let expectedContentLength: Int64 = dataTask.originalRequest?.rangeStart ?? response.expectedContentLength
                    self.response = HTTPURLResponse(url: url, contentLength: expectedContentLength)
                }
                
                return
            }
            self.response = httpResponse
        }
        
        completionHandler(.allow)
    }
}

extension URLFile {
    func loadData(from: UInt64, length: Int, back: @escaping (Data) -> Void) {
        queue.async { [weak fileHandle] in
            guard let fileHandle = fileHandle else { return }
            let dataLength = fileHandle.seekToEndOfFile()
            guard dataLength > from else { return }
            fileHandle.seek(toFileOffset: from)
            let data = fileHandle.readData(ofLength: length)
            back(data)
        }
    }
}
