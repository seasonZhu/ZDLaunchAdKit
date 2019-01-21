//
//  UIImageView+Extension.swift
//  ZDLaunchAdDemo
//
//  Created by season on 2018/7/27.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

/// 为类添加扩展字段, 注意是类
public final class Category<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}

public protocol CategoryCompatible {
    associatedtype CompatibleType
    var expand: CompatibleType { get }
}

public extension CategoryCompatible {
    public var expand: Category<Self> {
        get { return Category(self) }
    }
}

extension UIImageView: CategoryCompatible { }

extension Category where Base: UIImageView {
    func setImage(url: URL?, placeholder: UIImage? = nil, gifImageCycleOnce: Bool = true, options: ZDLaunchAdImageOptions, gifImageCycleFinish: (() -> ())?, progressCallback: DownloadProgressCallback? = nil, completionCallback: ImageManagerCompletionCallback? = nil) {
        guard let unwrappedUrl = url else {
            return
        }
        
        base.image = placeholder
        
        ZDLaunchAdImageManager.share.loadImage(url: unwrappedUrl, options: options, progressCallback: progressCallback) { [weak base] (image, data, url, error)  in
            if let _ = error {
                completionCallback?(image, data, url, error)
            }else {
                guard let realData = data else {
                    completionCallback?(image, data, url, error)
                    return
                }
                
                switch realData.imageFormat {
                case .gif:
                    //  这个地方要是想要监听gif播放一次后回调,必须将属性公开,暂时没有这个需求,先这样吧
                    base?.image = UIImage.gif(data: realData)
                    base?.playGif(data: realData, repeatCount: 0, runable: {
                        gifImageCycleFinish?()
                    })
                default:
                    base?.image = image
                }
                completionCallback?(image, data, url, error)
            }
        }
    }
}


