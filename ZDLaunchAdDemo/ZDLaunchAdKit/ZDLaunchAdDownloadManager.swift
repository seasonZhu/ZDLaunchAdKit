//
//  ZDLaunchAdDownloadManager.swift
//  ZDLaunchAdDemo
//
//  Created by season on 2018/7/26.
//  Copyright © 2018年 season. All rights reserved.
//

import Foundation

/// 下载管理器
class ZDLaunchAdDownloadManager {
    
    //MARK:- 属性设置
    
    /// 图片下载线程
    private var downloadImageQueue: OperationQueue!
    
    /// 视频下载线程
    private var downloadVideoQueue: OperationQueue!
    
    /// 下载任务字典
    private lazy var downloadDict: [String: ZDLaunchAdDownloader] = {
        let dict = [String: ZDLaunchAdDownloader]()
        return dict
    }()
    
    //MARK:- 单例
    static let shared = ZDLaunchAdDownloadManager()
    
    private init() {
        downloadImageQueue = OperationQueue()
        downloadImageQueue.maxConcurrentOperationCount = 6
        downloadImageQueue.name = "com.season.zhu.downloadImageQueue"
        
        downloadVideoQueue = OperationQueue()
        downloadVideoQueue.maxConcurrentOperationCount = 3
        downloadVideoQueue.name = "com.season.zhu.downloadVideoQueue"
    }
}

// MARK: - 图片下载
extension ZDLaunchAdDownloadManager {
    
    /// 下载单张图片
    ///
    /// - Parameters:
    ///   - url: 图片地址
    ///   - progressCallback: 图片进度
    ///   - completedCallback: 图片完成回调
    func downloadImage(url: URL, progressCallback: DownloadProgressCallback? = nil, completedCallback: DownloadImageCompletedCallback? = nil) {
        let key = url.absoluteString.md5
        if downloadDict.contains(where: { (dictKey, value) -> Bool in return key == dictKey }) {
            return
        }
        
        let imageDowload = ZDLaunchAdImageDownloader(url: url, delegateQueue: downloadImageQueue, progressCallback: progressCallback, completedCallback: completedCallback)
        imageDowload.delegate = self
        downloadDict.updateValue(imageDowload, forKey: key)
    }
    
    /// 下载图片并缓存
    ///
    /// - Parameters:
    ///   - url: 图片地址
    ///   - callback: 缓存完成回调
    func downloadImageAndCache(url: URL, callback: @escaping SaveCompletionCallback) {
        downloadImage(url: url, progressCallback: nil) { (image, data, error) in
            if let _ = error {
                callback(false, url)
            }else {
                guard let realData = data else {
                    callback(false, url)
                    return
                }
                
                ZDLaunchAdCacheManager.asyncSaveImageData(realData, to: url) { (result, url) in
                    callback(result, url)
                }
            }
        }
    }
    
    /// 多图下载并缓存
    ///
    /// - Parameters:
    ///   - urls: 图片地址数组
    ///   - completedCallback: 队列完成回调
    func downloadAllImageAndCache(urls: [URL], completedCallback: BatchDownLoadAndCacheCompletedCallback? = nil) {
        if urls.count == 0 { return }
        
        var resultArray = [[String: String]]()
        
        let downLoadGroup = DispatchGroup()
        for url in urls {
            if !ZDLaunchAdCacheManager.checkImageInCacheWithUrl(url) {
                downLoadGroup.enter()
                
                downloadImageAndCache(url: url) { (result, url) in
                    downLoadGroup.leave()
                    let dict = ["url": url.absoluteString, "result": "\(result)"]
                    resultArray.append(dict)
                }
            }else {
                let dict = ["url": url.absoluteString, "result": "\(true)"]
                resultArray.append(dict)
            }
        }
        downLoadGroup.notify(queue: DispatchQueue.main) {
            completedCallback?(resultArray)
        }
    }
}

// MARK: - 视频下载
extension ZDLaunchAdDownloadManager {
    
    /// 下载单个视频
    ///
    /// - Parameters:
    ///   - url: 视频地址
    ///   - progressCallback: 视频进度
    ///   - completedCallback: 视频完成回调
    func downloadVideo(url: URL, progressCallback: DownloadProgressCallback? = nil, completedCallback: DownloadVideoCompletedCallback? = nil) {
        let key = url.absoluteString.md5
        if downloadDict.contains(where: { (dictKey, value) -> Bool in return key == dictKey }) {
            return
        }
        
        let videoDowload = ZDLaunchAdVideoDownloader(url: url, delegateQueue: downloadVideoQueue, progressCallback: progressCallback, completedCallback: completedCallback)
        videoDowload.delegate = self
        downloadDict.updateValue(videoDowload, forKey: key)
    }
    
    /// 下载视频并缓存
    ///
    /// - Parameters:
    ///   - url: 视频地址
    ///   - callback: 视频缓存回调
    func downloadVideoAndCache(url: URL, callback: @escaping SaveCompletionCallback) {
        downloadVideo(url: url, progressCallback: nil) { (location, error) in
            if let _ = error {
                callback(false, url)
            }else {
                guard let realLoaction = location else {
                    callback(false, url)
                    return
                }
                
                ZDLaunchAdCacheManager.asyncSaveVideoAtLocation(realLoaction, url: url) { (result, callbackUrl) in
                    callback(result, callbackUrl)
                }
            }
        }
    }
    
    /// 多视频下载并缓存
    ///
    /// - Parameters:
    ///   - urls: 多视频地址数组
    ///   - completedCallback: 队列完成回调
    func downloadAllVideoAndCache(urls: [URL], completedCallback: BatchDownLoadAndCacheCompletedCallback? = nil) {
        if urls.count == 0 { return }
        
        var resultArray = [[String: String]]()
        
        let downLoadGroup = DispatchGroup()
        for url in urls {
            if !ZDLaunchAdCacheManager.checkVideoInCacheWithUrl(url) {
                downLoadGroup.enter()
                
                downloadVideoAndCache(url: url) { (result, url) in
                    downLoadGroup.leave()
                    let dict = ["url": url.absoluteString, "result": "\(result)"]
                    resultArray.append(dict)
                }
            }else {
                let dict = ["url": url.absoluteString, "result": "\(true)"]
                resultArray.append(dict)
            }
        }
        downLoadGroup.notify(queue: DispatchQueue.main) {
            completedCallback?(resultArray)
        }
    }
}

extension ZDLaunchAdDownloadManager: ZDLaunchAdDownloaderDelegate {
    func downloadFinish(url: URL) {
        let key = url.absoluteString.md5
        downloadDict.removeValue(forKey: key)
    }
}
