//
//  ZDLaunchAdImageManager.swift
//  ZDLaunchAdDemo
//
//  Created by season on 2018/7/26.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

/// 缓存机制枚举
///
/// - `default`: 有缓存,读取缓存,不重新下载,没缓存先下载,并缓存
/// - onlyDownload: 只下载,不缓存
/// - refreshCached: 先读缓存,再下载刷新图片和缓存
/// - cacheInBackground: 与default一样
public enum ZDLaunchAdImageOptions {
    case `default`, onlyDownload, refreshCached, cacheInBackground
}

typealias ImageManagerCompletionCallback = (UIImage?, Data?, URL?, Error?) -> Void

/// 图片管理器
class ZDLaunchAdImageManager {
    
    //MARK:- 属性设置
    private let downloadManager: ZDLaunchAdDownloadManager!

    //MARK:- 单例
    static let share = ZDLaunchAdImageManager()
    private init() {
        downloadManager = ZDLaunchAdDownloadManager.shared
    }
    
    //MARK:- 加载图片
    /// 加载图片
    ///
    /// - Parameters:
    ///   - url: 图片网址
    ///   - options: 选项 默认是default
    ///   - progressCallback: 下载进度回调
    ///   - completionCallback: 完成回调
    func loadImage(url: URL, options: ZDLaunchAdImageOptions = .default,
                   progressCallback: DownloadProgressCallback? = nil,
                   completionCallback: ImageManagerCompletionCallback? = nil) {
        switch options {
        case .default, .cacheInBackground:
            let imageResult = ZDLaunchAdCacheManager.getCacheImageWithUrl(url)
            
            if let realImage = imageResult.cacheImage, let realData = imageResult.cacheData {
                completionCallback?(realImage, realData, url, nil)
            }else {
                downloadManager.downloadImage(url: url, progressCallback: progressCallback) { (image, data, error) in
                    guard let cbImage = image, let cbData = data else {
                        completionCallback?(nil, nil, url, error)
                        return
                    }
                    completionCallback?(cbImage, cbData, url, error)
                    ZDLaunchAdCacheManager.asyncSaveImageData(cbData, to: url)
                }
            }
        case .refreshCached:
            let imageResult = ZDLaunchAdCacheManager.getCacheImageWithUrl(url)
            
            //  只从缓存中读取,然后就回调了,而对于下载器下载的结果不进行回调
            if let realImage = imageResult.cacheImage, let realData = imageResult.cacheData {
                completionCallback?(realImage, realData, url, nil)
            }
            
            downloadManager.downloadImage(url: url, progressCallback: progressCallback) { (image, data, error) in
                ZDLaunchAdCacheManager.asyncSaveImageData(data, to: url)
            }
            
        case .onlyDownload:
            downloadManager.downloadImage(url: url, progressCallback: progressCallback) { (image, data, error) in
                completionCallback?(image, data, url, error)
            }
        }
    }
}
