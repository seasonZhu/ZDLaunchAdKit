//
//  ZDLaunchAdConfiguration.swift
//  ZDLaunchAdDemo
//
//  Created by season on 2018/7/26.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit
import AVKit

/// 动画效果
///
/// - none: 无动画
/// - fadein: 淡入
/// - lite: 放大淡入
/// - flipFromLeft: 左右翻转
/// - flipFromBottom: 下上翻转
/// - curUp: 向上翻页
public enum ShowFinishAnimate {
    case none, fadein, lite, flipFromLeft, flipFromBottom, curUp
}

/// 动画启动配置基类
public class ZDLaunchAdConfiguration {
    /// 停留时间(default 5 ,单位:秒)
    public var duration: Int = 5
    
    /// 跳过按钮类型(default squareTimeText)
    public var skipButtonType: SkipType = .squareTimeText
    
    /// 显示完成动画(default fadein)
    public var showFinishAnimate: ShowFinishAnimate = .fadein
    
    /// 显示完成动画时间(default 0.8 , 单位:秒)
    public var showFinishAnimateTime = 0.8
    
    /// 设置开屏广告的frame(default [UIScreen mainScreen].bounds)
    public var frame = UIScreen.main.bounds
    
    /// 程序从后台恢复时,是否需要展示广告(default false)
    public var showEnterForeground = false
    
    /// 点击打开页面参数
    public var openModel: Any?
    
    /// 自定义跳过按钮(若定义此视图,将会自定替换系统跳过按钮)
    public var customSkipView: UIView?
    
    /// 子视图(若定义此属性,这些视图将会被自动添加在广告视图上,frame相对于window)
    public var subViews: [UIView]?
    
    /// 占位的广告图 主要用于第一次下载视频 视频不会暂时的时候显示
    public var placeholderAdImage: UIImage?
    
}

/// 动画启动配置图片类
public class ZDLaunchImageAdConfiguration: ZDLaunchAdConfiguration {
    /// image本地图片名(jpg/gif图片请带上扩展名)或网络图片URL string
    public var imageNameOrURLString = ""
    
    /// 图片广告缩放模式(default UIViewContentModeScaleToFill)
    public var contentMode: UIView.ContentMode = .scaleToFill
    
    /// 缓存机制(default)
    public var imageOption: ZDLaunchAdImageOptions = .default
    
    /// 设置GIF动图是否只循环播放一次(true:只播放一次,false:循环播放,default false,仅对动图设置有效)
    public var gifImageCycleOnce = false
}


/// 动画启动配置视频类
public class ZDLaunchVideoAdConfiguration: ZDLaunchAdConfiguration {
    /// video本地名或网络链接URL string
    public var videoNameOrURLString = ""
    
    /// 视频缩放模式(default AVLayerVideoGravityResizeAspectFill)
    public var videoGravity: AVLayerVideoGravity = .resizeAspectFill
    
    /// 设置视频是否只循环播放一次(true:只播放一次,false循环播放,default true)
    public var isVideoCycleOnce = true
    
    /// 是否关闭音频(default true 关闭音频)
    public var isMuted = true
    
}
