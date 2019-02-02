//
//  ZDLaunchAdCacheManager.swift
//  ZDLaunchAdDemo
//
//  Created by season on 2018/7/27.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

typealias SaveCompletionCallback = (Bool, URL) -> Void

/// 缓存与文件管理器
class ZDLaunchAdCacheManager {
    
    /// 默认路径
    private static let defaultPath = launchAdCachePath
    
    /// 通过传递的路径判断 文件或者文件夹, 如果不存在就进行创建, 这个方法一定要调用呀
    ///
    /// - Parameter path: 路径
    static func checkDirectory(path: String = defaultPath) {
        let fileManager = FileManager.default
        
        //  是否是文件夹
        var isDir: ObjCBool = false
        if !fileManager.fileExists(atPath: path, isDirectory: &isDir) {
            createBaseDirectory(at: path)
        }else {
            if !isDir.boolValue {
                do {
                    try fileManager.removeItem(atPath: path)
                    createBaseDirectory(at: path)
                }catch {
                    print("removeItem at Path Error")
                }
            }else {
                print("The \(path) is Exist ")
            }
        }
    }
    
    /// 通过网址获取本地的图片缓存
    ///
    /// - Parameter url: 网址
    /// - Returns: 图片缓存 图片数据缓存
    static func getCacheImageWithUrl(_ url: URL?) -> (cacheImage: UIImage?, cacheData: Data?) {
        if url == nil {
            return (nil, nil)
        }
        guard let path = imagePathWithUrl(url!),  let data = try? Data.init(contentsOf: URL(fileURLWithPath: path)) else {
            return (nil, nil)
        }
        return (UIImage(data: data), data)
    }
    
    /// 保存图片数据到文件夹中
    ///
    /// - Parameters:
    ///   - data: 数据
    ///   - url: 通过url去生成文件名
    /// - Returns: 保存是否成功
    private static func saveImageData(_ data: Data, by url: URL) -> Bool {
        let path = launchAdCachePath + "/" +  keyWithUrl(url)
        let result = FileManager.default.createFile(atPath: path, contents: data, attributes: nil)
        if !result {
            print("cache image error for URL: \(url) to \(path), please check the ZDLaunchAdCache file is Exit")
        }
        return result
    }
    
    /// 异步保存图片到文件夹中
    ///
    /// - Parameters:
    ///   - data: 数据
    ///   - url: 通过url去生成文件名
    ///   - callback: 回调
    static func asyncSaveImageData(_ data: Data?, to url: URL, callback: SaveCompletionCallback? = nil) {
        
        guard let data = data else {
            callback?(false, url)
            return
        }
        
        DispatchQueue.global().async {
            let result = saveImageData(data, by: url)
            DispatchQueue.main.async {
                callback?(result, url)
            }
        }
    }
    
    /// 保存视频
    ///
    /// - Parameters:
    ///   - location: 所在的临时文件
    ///   - url: 通过url去生成文件名,进而保存到目标文件中
    /// - Returns: 保存是否成功
    private static func saveVideoAtLocation(_ location: URL, url: URL) -> Bool {
        let savePath = launchAdCachePath + "/" +  videoNameWithUrl(url)
        let savePathUrl = URL(fileURLWithPath: savePath)
        do {
            try FileManager.default.moveItem(at: location, to: savePathUrl)
            return true
        } catch {
            print("cache video error for URL: \(url) to \(savePath), please check the ZDLaunchAdCache file is Exit")
            return false
        }
    }
    
    /// 异步保存视频
    ///
    /// - Parameters:
    ///   - location: 所在的临时文件
    ///   - url: 通过url去生成文件名,进而保存到目标文件中
    ///   - callback: 回调
    static func asyncSaveVideoAtLocation(_ location: URL, url: URL, callback: SaveCompletionCallback? = nil) {
        DispatchQueue.global().async {
            let result = saveVideoAtLocation(location, url: url)
            DispatchQueue.main.async {
                callback?(result, url)
            }
        }
    }
    
    /// 通过url获取视频在本地的缓存地址
    ///
    /// - Parameter url: 网址
    /// - Returns: 本地缓存地址
    static func getCacheVideoFileUrlWithUrl(_ url: URL) -> URL? {
        let savePath = launchAdCachePath + "/" + videoNameWithUrl(url)
        if FileManager.default.fileExists(atPath: savePath) {
            let path = URL(fileURLWithPath: savePath)
            return path
        }
        return nil
    }
}

extension ZDLaunchAdCacheManager {
    
    /// 缓存文件夹路径
    static var launchAdCachePath: String {
        let path = NSHomeDirectory() + "/Library/ZDLaunchAdCache"
        return path
    }
    
    /// 通过网址获取图片所在的缓存路径
    ///
    /// - Parameter url: 网址
    /// - Returns: 路径
    static func imagePathWithUrl(_ url: URL?) -> String? {
        guard let unwrappedUrl = url else {
            return nil
        }
        return launchAdCachePath + "/" + keyWithUrl(unwrappedUrl)
    }
    
    /// 通过网址获取视频所在的缓存路径
    ///
    /// - Parameter url: 网址
    /// - Returns: 路径
    static func videoPathWithUrl(_ url: URL?) -> String? {
        guard let unwrappedUrl = url else {
            return nil
        }
        return launchAdCachePath + "/" + videoNameWithUrl(unwrappedUrl)
    }
    
    /// 通过文件名获取视频所在的缓存路径
    ///
    /// - Parameter fileName: 文件名
    /// - Returns: 路径
    static func videoPathWithFileName(_ fileName: String?) -> String? {
        guard let name = fileName else {
            return nil
        }
        return launchAdCachePath + "/" + name.md5 + ".mp4"
    }
    
    
    /// 通过url字符串获取图片或者视频在本地的缓存路径
    ///
    /// - Parameters:
    ///   - urlString: url字符串
    ///   - isVideo: 是否是视频
    /// - Returns: 路径
    static func getPath(urlString: String, isVideo: Bool = false) -> String? {
        if urlString.isEmpty {
            return nil
        }
        
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        guard let path = isVideo ? videoPathWithUrl(url) : imagePathWithUrl(url) else {
            return nil
        }
        
        return path
    }
}

extension ZDLaunchAdCacheManager {
    
    /// 通过url检查本地是否有该图片的缓存
    ///
    /// - Parameter url: 网址
    /// - Returns: 是否有缓存
    static func checkImageInCacheWithUrl(_ url: URL) -> Bool {
        guard let path = imagePathWithUrl(url) else {
            return false
        }
        return FileManager.default.fileExists(atPath: path)
    }
    
    /// 通过url检查本地是否有该视频的缓存
    ///
    /// - Parameter url: 网址
    /// - Returns: 是否有缓存
    static func checkVideoInCacheWithUrl(_ url: URL) -> Bool {
        guard let path = videoPathWithUrl(url) else {
            return false
        }
        return FileManager.default.fileExists(atPath: path)
    }
    
    /// 通过文件名检查本地是否有该视频的缓存
    ///
    /// - Parameter fileName: 文件名
    /// - Returns: 是否有缓存
    static func checkVideoInCacheWithFileName(_ fileName: String) -> Bool {
        guard  let path = videoPathWithFileName(fileName) else {
            return false
        }
        return FileManager.default.fileExists(atPath: path)
    }
}


extension ZDLaunchAdCacheManager {
    
    /// 异步通过UserDefaults保存当前下载图片的url
    ///
    /// - Parameter url: 网址
    static func asyncSaveImageUrl(_ url: String?) {
        guard let unwrappedUrl = url else {
            return
        }
        DispatchQueue.global().async {
            UserDefaults.standard.set(unwrappedUrl, forKey: ZDCacheImageUrlStringKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    /// 通过UserDefaults获取当前下载图片的url
    ///
    /// - Returns: 网址
    static func getCacheImageUrl() -> String? {
        return UserDefaults.standard.object(forKey: ZDCacheImageUrlStringKey) as? String
    }
    
    /// 异步通过UserDefaults保存当前下载视频的url
    ///
    /// - Parameter url: 网址
    static func asyncSaveVideoUrl(_ url: String?) {
        guard let unwrappedUrl = url else {
            return
        }
        DispatchQueue.global().async {
            UserDefaults.standard.set(unwrappedUrl, forKey: ZDCacheVideoUrlStringKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    /// 通过UserDefaults获取当前下载视频的url
    ///
    /// - Returns: 网址
    static func getCacheVideoUrl() -> String? {
        return UserDefaults.standard.object(forKey: ZDCacheVideoUrlStringKey) as? String
    }
}

extension ZDLaunchAdCacheManager {
    
    /// 清理沙盒中的所有缓存
    static func clearDiskCache() {
        DispatchQueue.global().async {
            do {
                try FileManager.default.removeItem(atPath: launchAdCachePath)
                checkDirectory()
            }catch {
                print("clearDiskCache error")
            }
        }
    }
    
    /// 通过usl数组 清理沙盒中的图片缓存
    ///
    /// - Parameter imageUrls: 图片url数组
    static func clearDiskCache(imageUrls: [URL]) {
        if imageUrls.count == 0 {
            return
        }
        DispatchQueue.global().async {
            for imageUrl in imageUrls {
                if checkImageInCacheWithUrl(imageUrl) {
                    do {
                        try FileManager.default.removeItem(atPath: imagePathWithUrl(imageUrl)!)
                    } catch {
                        print("clearDiskCache with imageUrls error")
                    }
                }
            }
        }
    }
    
    /// 除传入的usl数组外 其他的图片进行删除
    ///
    /// - Parameter imageUrls: 图片url数组
    static func clearDiskCacheExcept(imageUrls: [URL]) {
        DispatchQueue.global().async {
            let allFilePahts = allFilePathWithDirectoryPath(launchAdCachePath)
            let exceptImagePahts = filePathsWithUrls(imageUrls)
            for filePath in allFilePahts {
                if !exceptImagePahts.contains(filePath) && !filePath.isVideo {
                    do {
                        try FileManager.default.removeItem(atPath: filePath)
                    }catch {
                        print("removeItem error")
                    }
                }
            }
            print("allFilePahts: \(allFilePahts)")
        }
    }
    
    /// 清除所有的图片缓存
    static func clearDiskAllImageCache() {
        DispatchQueue.global().async {
            let allFilePahts = allFilePathWithDirectoryPath(launchAdCachePath)
            for filePath in allFilePahts {
                if !filePath.isVideo {
                    do {
                        try FileManager.default.removeItem(atPath: filePath)
                    }catch {
                        print("removeItem error")
                    }
                }
            }
            print("allFilePahts: \(allFilePahts)")
        }
    }
    
    /// 通过视频的url数组 删除沙盒中的视频
    ///
    /// - Parameter videoUrls: 视频url数组
    static func clearDiskCache(videoUrls: [URL]) {
        if videoUrls.count == 0 {
            return
        }
        DispatchQueue.global().async {
            for videoUrls in videoUrls {
                if checkVideoInCacheWithUrl(videoUrls) {
                    do {
                        try FileManager.default.removeItem(atPath: videoPathWithUrl(videoUrls)!)
                    } catch {
                        print("clearDiskCache with videoUrls error")
                    }
                }
            }
        }
    }
    
    /// 除传入的usl数组外 其他的视频进行删除
    ///
    /// - Parameter imageUrls: 视频url数组
    static func clearDiskCacheExcept(videoUrls: [URL]) {
        DispatchQueue.global().async {
            let allFilePahts = allFilePathWithDirectoryPath(launchAdCachePath)
            let exceptImagePahts = filePathsWithUrls(videoUrls, isVideo: true)
            for filePath in allFilePahts {
                if !exceptImagePahts.contains(filePath) && filePath.isVideo {
                    do {
                        try FileManager.default.removeItem(atPath: filePath)
                    }catch {
                        print("removeItem error")
                    }
                }
            }
            print("allFilePahts: \(allFilePahts)")
        }
    }
    
    /// 清除所有的视频缓存
    static func clearDiskAllVideoCache() {
        DispatchQueue.global().async {
            let allFilePahts = allFilePathWithDirectoryPath(launchAdCachePath)
            for filePath in allFilePahts {
                if filePath.isVideo {
                    do {
                        try FileManager.default.removeItem(atPath: filePath)
                    }catch {
                        print("removeItem error")
                    }
                }
            }
            print("allFilePahts: \(allFilePahts)")
        }
    }
    
    /// 计算所有缓存的大小
    ///
    /// - Returns: 返回bytes值
    static func diskCacheSize() -> Double {
        let directoryPath = launchAdCachePath
        var isDir: ObjCBool = false
        var total: UInt64 = 0
        if FileManager.default.fileExists(atPath: directoryPath, isDirectory: &isDir) {
            if isDir.boolValue {
                do {
                    let array = try FileManager.default.contentsOfDirectory(atPath: directoryPath)
                    for subPath in array {
                        let path = directoryPath + subPath
                        do {
                            let dict = try FileManager.default.attributesOfItem(atPath: path)
                            total += dict[FileAttributeKey.size] as! UInt64
                        }catch {
                            print("get attributesOfItem error")
                        }
                    }
                }catch {
                    print("get contentsOfDirectory error")
                }
            }
        }
        return Double(total)
    }
    
    /// 异步计算缓存大小
    ///
    /// - Parameter callback: 回调
    static func asyncDiskCache(callback: @escaping (Double) -> Void) {
        DispatchQueue.global().async {
            let result = diskCacheSize()
            DispatchQueue.main.async {
                callback(result)
            }
        }
    }
    
    /// 通过 网址数组 获取 缓存在沙盒中的路径
    ///
    /// - Parameters:
    ///   - urls: 网络路径数组
    ///   - isVideo: 是否是视频
    /// - Returns: 文件所在沙盒的路径数组
    static func filePathsWithUrls(_ urls: [URL], isVideo: Bool = false) -> [String] {
        var filePaths = [String]()
        
        for url in urls {
            var path = ""
            if isVideo {
                path = videoPathWithUrl(url)!
            }else {
                path = imagePathWithUrl(url)!
            }
            filePaths.append(path)
        }
        return filePaths
    }
    
    /// 获取路径下所有文件的沙盒路径
    ///
    /// - Parameter directoryPath: 路径
    /// - Returns: 文件路径数组
    static func allFilePathWithDirectoryPath(_ directoryPath: String) -> [String] {
        var array = [String]()
        do {
            let tempArray = try FileManager.default.contentsOfDirectory(atPath: directoryPath)
            for fileName in tempArray {
                var flag: ObjCBool = true
                let fullPath = directoryPath + "/" + fileName
                if FileManager.default.fileExists(atPath: fullPath, isDirectory: &flag) {
                    if !flag.boolValue {
                        array.append(fullPath)
                    }
                }
            }
        }catch {
            print("get contentsOfDirectory error")
        }
        return array
    }
}

extension ZDLaunchAdCacheManager {
    
    /// 创建基本文件夹
    ///
    /// - Parameter path: 文件夹所在的路径
    static func createBaseDirectory(at path: String) {
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            addDoNotBackupAttribute(path: path)
        }catch {
            print("create cache directory failed")
        }
    }
    
    static func addDoNotBackupAttribute(path: String) {
        var url = URL.init(fileURLWithPath: path)
        url.setTemporaryResourceValue(true, forKey: URLResourceKey.isExcludedFromBackupKey)
        /*
        do {
            try url.setTemporaryResourceValue(true, forKey: URLResourceKey.isExcludedFromBackupKey)
        }catch {
            print("error to set do not backup attribute")
        }
        */
    }
}

extension ZDLaunchAdCacheManager {
    
    /// 视频名称
    ///
    /// - Parameter url: 网址
    /// - Returns: 网址字符串的md5 + 后缀 .mp4
    static func videoNameWithUrl(_ url: URL) -> String {
        return keyWithUrl(url) + ".mp4"
    }
    
    /// 图片名称
    ///
    /// - Parameter url: 网址
    /// - Returns: 网址字符串的md5
    static func keyWithUrl(_ url: URL) -> String {
        return url.absoluteString.md5
    }
}
