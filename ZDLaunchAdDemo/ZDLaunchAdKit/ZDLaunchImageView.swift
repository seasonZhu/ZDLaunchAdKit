//
//  ZDLaunchImageView.swift
//  ZDLaunchAdDemo
//
//  Created by season on 2018/7/27.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

/// 启动页来源
///
/// - launchImage: image
/// - storyboard: 故事版
public enum SourceType {
    case launchImage, storyboard
}

/// 获取App启动图View
class ZDLaunchImageView: UIImageView {
    
    private enum PictureType: String {
        case portrait = "Portrait"
        case landscape = "Landscape"
    }

    /// 便利构造函数
    ///
    /// - Parameter sourceType: 启动页来源枚举
    convenience init(sourceType: SourceType) {
        self.init(frame: UIScreen.main.bounds)
        isUserInteractionEnabled = true
        backgroundColor = .white
        switch sourceType {
        case .launchImage:
            image = imageFromeLaunchImage()
        case .storyboard:
            image = imageFromeLaunchScreen()
        }
    }
    
    /// 获取启动图片启动图
    ///
    /// - Returns: 启动图
    private func imageFromeLaunchImage() -> UIImage? {
        if let imageP = launchImage(type: .portrait) {
            return imageP
        }
        
        if let imageL = launchImage(type: .landscape) {
            return imageL
        }
        
        return nil
    }
    
    /// 通过故事板获取启动图
    ///
    /// - Returns: 启动图
    private func imageFromeLaunchScreen() -> UIImage? {
        guard let launchStoryboardName = Bundle.main.infoDictionary?["UILaunchStoryboardName"] as? String else {
            print("从 LaunchScreen 中获取启动图失败!")
            return nil
        }
        
        guard let launchScreenStoryboard = UIStoryboard(name: launchStoryboardName, bundle: nil).instantiateInitialViewController() else {
            print("从 LaunchScreen 中获取启动图失败!")
            return nil
        }
        
        guard let view = launchScreenStoryboard.view else {
            return nil
        }
        
        view.frame = UIScreen.main.bounds
        return launchImage(frome: view)
    }
    
    /// 截取view为图片
    ///
    /// - Parameter view: view
    /// - Returns: 图片
    private func launchImage(frome view: UIView) -> UIImage? {
        let size = view.bounds.size
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        defer {
            UIGraphicsEndImageContext()
        }
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        view.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        return image
    }
    
    /// 启动图片的类型获取图片
    ///
    /// - Parameter type: 类型
    /// - Returns: 图片
    private func launchImage(type: PictureType) -> UIImage? {
        let size = UIScreen.main.bounds.size
        let viewOrientation = type.rawValue
        guard let imageDicts = Bundle.main.infoDictionary?["UILaunchImages"] as? [[String: String]] else {
            return nil
        }
        
        for dict in imageDicts {
            var imageSize = NSCoder.cgSize(for: dict["UILaunchImageSize"]!)
            
            if viewOrientation == dict["UILaunchImageOrientation"] {
                if dict["UILaunchImageOrientation"] == "Landscape"{
                   imageSize = CGSize(width: imageSize.width, height: imageSize.height)
                }
                
                if size == imageSize {
                    guard let imageName = dict["UILaunchImageName"] else {
                        return nil
                    }
                    return UIImage(named: imageName)
                }
            }
        }
        return nil
    }
}
