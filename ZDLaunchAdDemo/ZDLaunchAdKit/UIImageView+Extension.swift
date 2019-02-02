//
//  UIImageView+Extension.swift
//  ZDLaunchAdDemo
//
//  Created by season on 2018/7/27.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

/// 为类添加扩展字段, 注意是类
final class Category<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}

protocol CategoryCompatible {
    associatedtype CompatibleType
    var expand: CompatibleType { get }
}

extension CategoryCompatible {
    public var expand: Category<Self> {
        get { return Category(self) }
    }
}

extension UIImageView: CategoryCompatible {}

extension Category where Base: UIImageView {
    func setImage(url: URL?, placeholder: UIImage? = nil, gifImageCycleOnce: Bool = true,
                  options: ZDLaunchAdImageOptions = .default,
                  gifImageCycleFinish: (() -> Void)? = nil,
                  progressCallback: DownloadProgressCallback? = nil,
                  completionCallback: ImageManagerCompletionCallback? = nil) {
        guard let unwrappedUrl = url else {
            return
        }
        
        base.image = placeholder
        
        ZDLaunchAdImageManager.share.loadImage(url: unwrappedUrl, options: options, progressCallback: progressCallback) { [weak base] (image, data, url, error)  in
            if let realData = data, realData.imageFormat == .gif  {
                //  这个地方要是想要监听gif播放一次后回调,必须将属性公开,暂时没有这个需求,先这样吧
                base?.image = UIImage.gif(data: realData)
                base?.playGif(data: realData, repeatCount: 0) {
                    gifImageCycleFinish?()
                }
            }else {
                base?.image = image
            }
            completionCallback?(image, data, url, error)
        }
    }
}


