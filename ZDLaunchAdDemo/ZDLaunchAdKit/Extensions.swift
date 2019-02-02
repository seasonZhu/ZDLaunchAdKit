//
//  Extensions.swift
//  ZDLaunchAdDemo
//
//  Created by season on 2018/7/30.
//  Copyright © 2018年 season. All rights reserved.
//

import Foundation

// MARK: - 字符串判断
extension String {
    
    /// 是否带有http或者https
    var isUrl: Bool {
        return (hasPrefix("http") || hasPrefix("https")) ? true : false
    }
    
    /// 是否带有.mp4后缀
    var isVideo: Bool {
        return hasSuffix(".mp4") ? true : false
    }
    
    /// 是否包含子字符串
    ///
    /// - Parameter subString: 子字符串
    /// - Returns: 结果
    func containsSubString(_ subString: String) -> Bool {
        return (self as NSString).range(of: subString).location == NSNotFound ? false : true
    }
}


//MARK:- md5加密
/*
extension String {
    
    /// 加密
    var md5: String {
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = CUnsignedInt(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        CC_MD5(str!, strLen, result)
        let hash = NSMutableString()
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i])
        }
        
        return String(format: hash as String)
    }
}
 */

// MARK: - 通过Data判断图片类型, From Kingfisher

/// 图片类型枚举
///
/// - unknown:
/// - png:
/// - jpeg:
/// - gif:
/// - bmp:
enum ImageFormat {
    case unknown, png, jpeg, gif, bmp
}

/// 图片数据头
private struct ImageHeaderData {
    static var PNG: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    static var JPEG_SOI: [UInt8] = [0xFF, 0xD8]
    static var JPEG_IF: [UInt8] = [0xFF]
    static var GIF: [UInt8] = [0x47, 0x49, 0x46]
    static var BMP: [UInt8] = [0x42, 0x4D]
}

// MARK: - 数据判断图片类型
extension Data {
    
    /// 图片类型
    var imageFormat: ImageFormat {
        var buffer = [UInt8](repeating: 0, count: 8)
        (self as NSData).getBytes(&buffer, length: 8)
        if buffer == ImageHeaderData.PNG {
            return .png
        } else if buffer[0] == ImageHeaderData.JPEG_SOI[0] &&
            buffer[1] == ImageHeaderData.JPEG_SOI[1] &&
            buffer[2] == ImageHeaderData.JPEG_IF[0] {
            return .jpeg
        } else if buffer[0] == ImageHeaderData.GIF[0] &&
            buffer[1] == ImageHeaderData.GIF[1] &&
            buffer[2] == ImageHeaderData.GIF[2] {
            return .gif
        } else if buffer[0] == ImageHeaderData.BMP[0] &&
            buffer[1] == ImageHeaderData.BMP[1] {
            return .bmp
        }
        
        return .unknown
    }
    
    /// 通过文件名获取本地图片数据
    ///
    /// - Parameter fileName: 文件名
    /// - Returns: 图片数据
    static func getData(by fileName: String) -> Data? {
        guard let path = Bundle.main.path(forResource: fileName, ofType: nil) else {
            return nil
        }
        
        var data: Data?
        let url = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: path) {
            data = try? Data.init(contentsOf: url)
        }
        return data
    }
}

// MARK: - 通知名称的分类
extension Notification.Name {
    
    static let ZDLaunchAdWaitDataDurationArrive = Notification.Name("ZDLaunchAdWaitDataDurationArrive")
    static let ZDLaunchAdDetailPageWillShow = Notification.Name("ZDLaunchAdDetailPageWillShow")
    static let ZDLaunchAdDetailPageShowFinish = Notification.Name("ZDLaunchAdDetailPageShowFinish")
    static let ZDLaunchAdGIFImageCycleOnceFinish = Notification.Name("ZDLaunchAdGIFImageCycleOnceFinish")
    static let ZDLaunchAdVideoCycleOnceFinish = Notification.Name("ZDLaunchAdVideoCycleOnceFinish")
    static let ZDLaunchAdVideoPlayFailed = Notification.Name("ZDLaunchAdVideoPlayFailed")
}
