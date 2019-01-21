//
//  ZDLaunchAdDownloader.swift
//  ZDLaunchAdDemo
//
//  Created by season on 2018/7/26.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

typealias DownloadImageCompletedCallback = (_ image: UIImage?, _ data: Data?, _ error: Error?) -> ()
typealias DownloadVideoCompletedCallback = (_ location: URL?, _ error: Error?) -> ()
typealias DownloadProgressCallback = (_ total: Int64, _ current: Int64) -> ()
public typealias BatchDownLoadAndCacheCompletedCallback = (_ completedArray: [[String: String]]) -> ()

/// 下载协议
protocol ZDLaunchAdDownloaderDelegate: class {
    func downloadFinish(url: URL)
}

/// 下载器基类
class ZDLaunchAdDownloader: NSObject {
    
    weak var delegate: ZDLaunchAdDownloaderDelegate?
    
    fileprivate var session: URLSession?
    
    fileprivate var downloadTask: URLSessionDownloadTask!
    
    fileprivate var totalLength: Int64 = 0
    
    fileprivate var currentLength: Int64 = 0
    
    fileprivate var progressCallback: DownloadProgressCallback?
    
    fileprivate var url: URL!
}


/// 图片下载器
class ZDLaunchAdImageDownloader: ZDLaunchAdDownloader {
    private var completedCallback: DownloadImageCompletedCallback?
    
    @discardableResult
    init(url: URL, delegateQueue: OperationQueue, progressCallback: DownloadProgressCallback? = nil, completedCallback: DownloadImageCompletedCallback? = nil) {
        super.init()
        self.url = url
        self.progressCallback = progressCallback
        self.completedCallback = completedCallback
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 15.0
        session = URLSession.init(configuration: sessionConfiguration, delegate: self, delegateQueue: delegateQueue)
        downloadTask = session!.downloadTask(with: URLRequest(url: url))
        downloadTask.resume()
    }
}

extension ZDLaunchAdImageDownloader: URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let protectionSpace = challenge.protectionSpace
        if protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            guard let serverTrust = protectionSpace.serverTrust else {
                completionHandler(.useCredential, nil)
                return
            }
            completionHandler(.useCredential, URLCredential.init(trust: serverTrust))
        }else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

extension ZDLaunchAdImageDownloader: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let data = try? Data(contentsOf: location) else {
            self.completedCallback?(nil, nil, nil)
            self.completedCallback = nil
            return
        }
        
        let image = UIImage(data: data)
        DispatchQueue.main.async {
            self.completedCallback?(image, data, nil)
            self.completedCallback = nil
            self.delegate?.downloadFinish(url: self.url)
        }
        
        self.session?.invalidateAndCancel()
        self.session = nil
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        currentLength = totalBytesWritten
        totalLength = totalBytesExpectedToWrite
        print("image download currentLength:\(currentLength), totalLength:\(totalLength)")
        progressCallback?(totalLength, currentLength)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("didCompleteWithError: \(String(describing: error))")
        
        DispatchQueue.main.async {
            self.completedCallback?(nil, nil, error)
            self.completedCallback = nil
        }
    }
}

/// 视频下载器
class ZDLaunchAdVideoDownloader: ZDLaunchAdDownloader {
    private var completedCallback: DownloadVideoCompletedCallback?
    
    @discardableResult
    init(url: URL, delegateQueue: OperationQueue, progressCallback: DownloadProgressCallback? = nil, completedCallback: DownloadVideoCompletedCallback? = nil) {
        super.init()
        self.url = url
        self.progressCallback = progressCallback
        self.completedCallback = completedCallback
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 15.0
        session = URLSession.init(configuration: sessionConfiguration, delegate: self, delegateQueue: delegateQueue)
        downloadTask = session!.downloadTask(with: URLRequest(url: url))
        downloadTask.resume()
    }
}

extension ZDLaunchAdVideoDownloader: URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let protectionSpace = challenge.protectionSpace
        if protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            guard let serverTrust = protectionSpace.serverTrust else {
                completionHandler(.useCredential, nil)
                return
            }
            completionHandler(.useCredential, URLCredential.init(trust: serverTrust))
        }else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

extension ZDLaunchAdVideoDownloader: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let path = ZDLaunchAdCacheManager.videoPathWithUrl(url) else {
            return
        }
        
        let toUrl = URL.init(fileURLWithPath: path)
        do {
            try FileManager.default.copyItem(at: location, to: toUrl)
            DispatchQueue.main.async {
                self.completedCallback?(toUrl, nil)
                self.completedCallback = nil
                self.delegate?.downloadFinish(url: self.url)
            }
        } catch {
            DispatchQueue.main.async {
                self.completedCallback?(nil, nil)
                self.completedCallback = nil
            }
        }
        
        self.session?.invalidateAndCancel()
        self.session = nil
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        currentLength = totalBytesWritten
        totalLength = totalBytesExpectedToWrite
        print("video download currentLength:\(currentLength), totalLength:\(totalLength)")
        progressCallback?(totalLength, currentLength)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("didCompleteWithError: \(String(describing: error))")
        
        DispatchQueue.main.async {
            self.completedCallback?(nil, error)
            self.completedCallback = nil
        }
    }
}

