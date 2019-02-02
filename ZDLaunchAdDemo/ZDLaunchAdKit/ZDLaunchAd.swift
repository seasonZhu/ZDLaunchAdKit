//
//  ZDLaunchAd.swift
//  ZDLaunchAdDemo
//
//  Created by season on 2018/7/30.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

/// ZDLaunchAdDelegate
public protocol ZDLaunchAdDelegate: class {
    
    /// 广告点击
    ///
    /// - Parameters:
    ///   - launchAd: launchAd
    ///   - model: 打开页面的参数
    ///   - clickPoint: 点击位置
    func launchAd(launchAd: ZDLaunchAd, click model: Any?, clickPoint: CGPoint)
    
    /// 图片本地读取或下载完成回调
    ///
    /// - Parameters:
    ///   - launchAd: launchAd
    ///   - image: 读取/下载的image
    ///   - imageData: 读取/下载的数据
    func launchAd(launchAd: ZDLaunchAd, imageDownoadFinish image: UIImage?, imageData: Data?, url: URL?)
    
    /// video本地读取或下载完成回调
    ///
    /// - Parameters:
    ///   - launchAd: launchAd
    ///   - path: 本地保存路径
    func launchAd(launchAd: ZDLaunchAd, videoDownloadFinish path: URL?)
    
    /// 下载进度回调
    ///
    /// - Parameters:
    ///   - launchAd: launchAd
    ///   - progress: 下载进度
    ///   - total: 总大小
    ///   - current: 已下载大小
    func launchAd(launchAd: ZDLaunchAd, downloadProgress progress: Double, total: Int64, current: Int64)
    
    /// 自定义倒计时回调
    ///
    /// - Parameters:
    ///   - launchAd: launchAd
    ///   - customSkipView: 倒计时跳过按钮
    ///   - duration: 倒计时时间
    func launchAd(launchAd: ZDLaunchAd, customSkipView: UIView?, duration: Int)
    
    /// 第一次加载视频 仅下载视频不进行视频展示 展示默认的广告图
    ///
    /// - Parameter launchAd: launchAd
    func launchAdShowDefaultAdImage(launchAd: ZDLaunchAd)
    
    /// 广告显示完成
    ///
    /// - Parameter launchAd: launchAd
    func launchAdShowFinish(launchAd: ZDLaunchAd)
    
    /// 如果你想用Kingfisher等框架加载网络广告图片,请实现此代理,注意:实现此方法后,图片缓存将不受ZDLaunchAd管理
    ///
    /// - Parameters:
    ///   - launchAd: launchAd
    ///   - imageView: 图片View
    ///   - url: 图片的url
    func launchAd(launchAd: ZDLaunchAd, imageView: UIImageView, url: URL?)
    
    /// gif播放完成
    ///
    /// - Parameters:
    ///   - launchAd: launchAd
    ///   - gifImage: gifImage
    func launchAd(launchAd: ZDLaunchAd, gifPlayFinish gifImage: UIImage?)
}

// MARK: - 代理方法可选的默认实现
extension ZDLaunchAdDelegate {
    func launchAd(launchAd: ZDLaunchAd, click model: Any?, clickPoint: CGPoint) {}
    
    func launchAd(launchAd: ZDLaunchAd, imageDownoadFinish image: UIImage?, imageData: Data?, url: URL?) {}
    
    func launchAd(launchAd: ZDLaunchAd, videoDownloadFinish path: URL?) {}
    
    func launchAd(launchAd: ZDLaunchAd, downloadProgress progress: Double, total: Int64, current: Int64) {}
    
    func launchAd(launchAd: ZDLaunchAd, customSkipView: UIView?, duration: Int) {}
    
    func launchAdShowDefaultAdImage(launchAd: ZDLaunchAd) {}
    
    func launchAdShowFinish(launchAd: ZDLaunchAd) {}
    
    func launchAd(launchAd: ZDLaunchAd, imageView: UIImageView, url: URL?) {}
    
    func launchAd(launchAd: ZDLaunchAd, gifPlayFinish gifImage: UIImage?) {}
}

/// 广告类型枚举
///
/// - image: 广告图
/// - video: 广告视频
public enum LaunchAdType {
    case image, video
}

public class ZDLaunchAd {
    //MARK:- 属性设置
    
    /// 代理
    weak var delegate: ZDLaunchAdDelegate?
    
    /// 是否正在显示广告
    private var detailPageShowing = false
    
    /// 广告类型 图片或者视频
    private var launchAdType: LaunchAdType = .image
    
    /// 启动图类型
    private var sourceType: SourceType = .launchImage
    
    /// 等待数据回来的时间
    private var waitDataDuration: Int! {
        didSet {
            startWaitDataDispathTimer()
        }
    }
    
    /// 图片广告配置
    private var imageAdConfiguration = ZDLaunchImageAdConfiguration() {
        didSet {
            //  类的链式编程set时会走该方法
            launchAdType = .image
            setUpLaunchAdImage(configuration: imageAdConfiguration)
        }
    }
    
    /// 视频广告配置
    private var videoAdConfiguration = ZDLaunchVideoAdConfiguration() {
        didSet {
            //  类的链式编程set时会走该方法
            launchAdType = .video
            setUpLaunchAdVideo(configuration: videoAdConfiguration)
        }
    }
    
    /// 跳过按钮
    private var skipButton: ZDLaunchAdButton!
    
    /// 视频view
    private var adVideoView: ZDLaunchAdVideoView!
    
    /// 窗口
    private var window: UIWindow!
    
    /// 广告停留倒计时
    private var waitDataTimer: DispatchSourceTimer?
    
    /// 跳过按钮倒计时
    private var skipTimer: DispatchSourceTimer?
    
    /// 点击的区域
    private var clickPoint = CGPoint.zero
    
    //MARK:- 单例
    static let share = ZDLaunchAd()
    private init() {
        
        ZDLaunchAdCacheManager.checkDirectory()
        
        setUpLaunchAdWindow()
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { (notification) in
            //  APP从后台进入到前台的时候会进入该方法
            self.setUpLaunchAdUIApplicationWillEnterForeground()
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { (notification) in
            self.removeOnly()
        }
        
        NotificationCenter.default.addObserver(forName: .ZDLaunchAdDetailPageWillShow, object: nil, queue: nil) { (notification) in
            self.detailPageShowing = true
        }
        
        NotificationCenter.default.addObserver(forName: .ZDLaunchAdDetailPageShowFinish, object: nil, queue: nil) { (notification) in
            self.detailPageShowing = false
        }
    }
    
    /// 设置广告类型
    ///
    /// - Parameter launchAdType: 图片或者是视频
    /// - Returns: 类别
    public static func setLaunchAdType(_ launchAdType: LaunchAdType) -> ZDLaunchAd.Type {
        ZDLaunchAd.share.launchAdType = launchAdType
        return type(of: ZDLaunchAd.share)
    }
    
    /// 设置启动图类型 默认是 image类型
    ///
    /// - Parameter sourceType: storyboard or image
    /// - Returns: 类别
    @discardableResult
    public static func setSourceType(_ sourceType: SourceType) -> ZDLaunchAd.Type {
        ZDLaunchAd.share.sourceType = sourceType
        return type(of: ZDLaunchAd.share)
    }
    
    /// 设置广告页停留时间 默认是 3秒,请最后设置这个参数
    ///
    /// - Parameter waitDataDuration: 停留时间
    /// - Returns: 类别
    @discardableResult
    public static func setWaitDataDuration(_ waitDataDuration: Int) -> ZDLaunchAd.Type {
        ZDLaunchAd.share.waitDataDuration = waitDataDuration
        return type(of: ZDLaunchAd.share)
    }
    
    /// 设置广告图配置
    ///
    /// - Parameter imageAdConfiguration: 配置
    /// - Returns: 类别
    @discardableResult
    public static func setImageAdConfiguration(_ imageAdConfiguration: ZDLaunchImageAdConfiguration, delegate: ZDLaunchAdDelegate? = nil) -> ZDLaunchAd.Type {
        ZDLaunchAd.share.imageAdConfiguration = imageAdConfiguration
        ZDLaunchAd.share.delegate = delegate
        return type(of: ZDLaunchAd.share)
    }
    
    /// 设置广告视频配置
    ///
    /// - Parameter videoAdConfiguration: 配置
    /// - Returns: 类别
    @discardableResult
    public static func setVideoAdConfiguration(_ videoAdConfiguration: ZDLaunchVideoAdConfiguration, delegate: ZDLaunchAdDelegate? = nil) -> ZDLaunchAd.Type {
        ZDLaunchAd.share.videoAdConfiguration = videoAdConfiguration
        ZDLaunchAd.share.delegate = delegate
        return type(of: ZDLaunchAd.share)
    }
    
    /// 设置代理
    ///
    /// - Parameter delegate: 代理
    /// - Returns: 类别
    @discardableResult
    public static func setDelegate(_ delegate: ZDLaunchAdDelegate) -> ZDLaunchAd.Type {
        ZDLaunchAd.share.delegate = delegate
        return type(of: ZDLaunchAd.share)
    }
    
    /// 下载并缓存图片
    ///
    /// - Parameters:
    ///   - urls: 地址
    ///   - completedCallback: 回调
    public static func downloadAllImageAndCache(urls: [URL], completedCallback: BatchDownLoadAndCacheCompletedCallback? = nil) {
        ZDLaunchAdDownloadManager.shared.downloadAllImageAndCache(urls: urls, completedCallback: completedCallback)
    }
    
    /// 下载并缓存视频
    ///
    /// - Parameters:
    ///   - urls: 地址
    ///   - completedCallback: 回调
    public static func downloadAllVideoAndCache(urls: [URL], completedCallback: BatchDownLoadAndCacheCompletedCallback? = nil) {
        ZDLaunchAdDownloadManager.shared.downloadAllVideoAndCache(urls: urls, completedCallback: completedCallback)
    }
    
    /// 检查图片是否有缓存
    ///
    /// - Parameter url: 地址
    /// - Returns: 结果
    public static func checkImageInCacheWithUrl(_ url: URL) -> Bool {
        return ZDLaunchAdCacheManager.checkImageInCacheWithUrl(url)
    }
    
    /// 检查视频是否有缓存
    ///
    /// - Parameter url: 地址
    /// - Returns: 结果
    public static func checkVideoInCacheWithUrl(_ url: URL) -> Bool {
        return ZDLaunchAdCacheManager.checkVideoInCacheWithUrl(url)
    }
    
    /// 清除缓存
    public static func clearDiskCache() {
        ZDLaunchAdCacheManager.clearDiskCache()
    }
    
    /// 清楚指定图片缓存
    ///
    /// - Parameter imageUrls: 地址数组
    public static func clearDiskCache(imageUrls: [URL]) {
        ZDLaunchAdCacheManager.clearDiskCache(imageUrls: imageUrls)
    }
    
    /// 清楚指定外图片缓存
    ///
    /// - Parameter imageUrls: 地址数组
    public static func clearDiskCacheExcept(imageUrls: [URL]) {
        ZDLaunchAdCacheManager.clearDiskCacheExcept(imageUrls: imageUrls)
    }
    
    /// 清除所有图片缓存
    public static func clearDiskAllImageCache() {
        ZDLaunchAdCacheManager.clearDiskAllImageCache()
    }
    
    /// 清除指定视频缓存
    ///
    /// - Parameter imageUrls: 地址数组
    public static func clearDiskCache(videoUrls: [URL]) {
        ZDLaunchAdCacheManager.clearDiskCache(videoUrls: videoUrls)
    }
    
    /// 清除指定外视频缓存
    ///
    /// - Parameter imageUrls: 地址数组
    public static func clearDiskCacheExcept(videoUrls: [URL]) {
        ZDLaunchAdCacheManager.clearDiskCacheExcept(videoUrls: videoUrls)
    }
    
    /// 清除所有的视频缓存
    public static func clearDiskAllVideoCache() {
        ZDLaunchAdCacheManager.clearDiskAllVideoCache()
    }
    
    /// 异步获取缓存大小
    ///
    /// - Parameter callback: 回调
    public static func asyncDiskCache(callback: @escaping (Double) -> Void) {
        ZDLaunchAdCacheManager.asyncDiskCache(callback: callback)
    }
    
    /// 缓存路径
    ///
    /// - Returns: 返回缓存路径
    public static func launchAdCachePath() -> String {
        return ZDLaunchAdCacheManager.launchAdCachePath
    }
    
    /// 获取图片缓存的url
    ///
    /// - Returns: url
    public static func getCacheImageUrl() -> String? {
        return ZDLaunchAdCacheManager.getCacheImageUrl()
    }
    
    /// 获取视频缓存的url
    ///
    /// - Returns: url
    public static func getCacheVideoUrl() -> String? {
        return ZDLaunchAdCacheManager.getCacheVideoUrl()
    }
    
    /// 清除广告页
    ///
    /// - Parameter animatde: 是否有动画效果
    public static func removeWithAnimated(animatde: Bool = true) {
        ZDLaunchAd.share.removeWithAnimated(animatde: animatde)
    }
    
    /// 析构函数
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension ZDLaunchAd {
    
    /// 获取配置
    ///
    /// - Returns: 配置
    private func commonConfiguration() -> ZDLaunchAdConfiguration {
        switch launchAdType {
        case .image:
            return imageAdConfiguration
        case .video:
            return videoAdConfiguration
        }
    }
    
    /// 搭建window与启动图页面
    private func setUpLaunchAdWindow() {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = ZDLaunchAdController()
        window.rootViewController?.view.backgroundColor = .clear
        window.rootViewController?.view.isUserInteractionEnabled = false
        window.windowLevel = UIWindow.Level.statusBar + 1
        window.isHidden = false
        window.alpha = 1.0
        window.addSubview(ZDLaunchImageView(sourceType: sourceType))
        
        self.window = window
    }
    
    /// App在前台 进行广告页搭建
    private func setUpLaunchAdUIApplicationWillEnterForeground() {
    
        switch launchAdType {
        case .image:
            if !imageAdConfiguration.showEnterForeground || detailPageShowing { return }
            setUpLaunchAdImage(configuration: imageAdConfiguration)
        case .video:
            if !videoAdConfiguration.showEnterForeground || detailPageShowing { return }
            setUpLaunchAdVideo(configuration: videoAdConfiguration)
        }
    }
    
    /// 广告图搭建
    ///
    /// - Parameter configuration: 配置
    private func setUpLaunchAdImage(configuration: ZDLaunchImageAdConfiguration) {
        
        //  判断是否有window
        if window == nil {
            setUpLaunchAdWindow()
        }
        
        //  移除除了启动页截图之外的子控件
        removeSubviewsExpectLaunchAdImageView()
        
        //  添加广告图层
        let adImageViewFrame = configuration.frame.width > 0 && configuration.frame.height > 0 ? configuration.frame : UIScreen.main.bounds
        let adImageView = ZDLaunchAdImageView(frame: adImageViewFrame)
        adImageView.contentMode = configuration.contentMode
        window.addSubview(adImageView)
        
        //  添加跳过按钮与倒计时启动
        addSkipButton(configuration: configuration)
        startSkipDispathTimer()
        
        //  添加配置项中的子控件
        if let subViews = configuration.subViews, subViews.count > 0 {
            addSubViews(subViews)
        }
        
        //  广告图的点击事件
        adImageView.tapCallback = { point, tap in
            self.click(point: point)
        }
        
        //  是图片url
        if !configuration.imageNameOrURLString.isEmpty && configuration.imageNameOrURLString.isUrl {
            ZDLaunchAdCacheManager.asyncSaveImageUrl(configuration.imageNameOrURLString)
            
            adImageView.expand.setImage(url: URL(string: configuration.imageNameOrURLString), placeholder: configuration.placeholderAdImage, gifImageCycleOnce: configuration.gifImageCycleOnce, options: configuration.imageOption, gifImageCycleFinish: {
                NotificationCenter.default.post(name: .ZDLaunchAdGIFImageCycleOnceFinish, object: nil, userInfo: ["imageNameOrURLString": configuration.imageNameOrURLString])
            }, progressCallback: { (total, current) in
                self.delegate?.launchAd(launchAd: self, downloadProgress: Double(current) / Double(total), total: total, current: current)
            }) { (image, data, url, error) in
                
                self.delegate?.launchAd(launchAd: self, imageDownoadFinish: image, imageData: data, url: url)
                
                if let realData = data, realData.imageFormat == .gif {
                    let gifImage = UIImage.gif(data: realData)
                    
                    adImageView.playGif(data: realData, repeatCount: configuration.gifImageCycleOnce ? 1 : 0) {
                        if configuration.gifImageCycleOnce {
                            self.delegate?.launchAd(launchAd: self, gifPlayFinish: gifImage)
                        }
                    }
                }else {
                    adImageView.image = image
                }
                
                self.delegate?.launchAd(launchAd: self, imageView: adImageView, url: url)
                
            }
        }else {
        //  本地
            if !imageAdConfiguration.imageNameOrURLString.isEmpty {
                guard let data = Data.getData(by: configuration.imageNameOrURLString) else {
                    
                    //  这个代理回调必须回到主线程执行才能成功 目前不知为啥
                    DispatchQueue.main.async {
                       self.delegate?.launchAd(launchAd: self, imageDownoadFinish: nil, imageData: nil, url: nil)
                    }
                    return
                }
                
                if data.imageFormat == .gif {
                    let gifImage = UIImage.gif(data: data)
                    adImageView.playGif(data: data, repeatCount: configuration.gifImageCycleOnce ? 1 : 0) {
                        if configuration.gifImageCycleOnce {
                            self.delegate?.launchAd(launchAd: self, gifPlayFinish: gifImage)
                        }
                    }
                }else {
                    adImageView.image = UIImage(data: data)
                }
                
                DispatchQueue.main.async {
                    self.delegate?.launchAd(launchAd: self, imageDownoadFinish: UIImage(data: data), imageData: data, url: nil)
                }
                
            }else {
                print("未设置广告图")
            }
        }
    }
    
    /// 广告视频搭建
    ///
    /// - Parameter configuration: 配置
    private func setUpLaunchAdVideo(configuration: ZDLaunchVideoAdConfiguration) {
        //  判断是否有window
        if window == nil {
            setUpLaunchAdWindow()
        }
        
        //  移除除了启动页截图之外的子控件
        removeSubviewsExpectLaunchAdImageView()
        
        //  添加广告图层
        let adVideoViewFrame = configuration.frame.width > 0 && configuration.frame.height > 0 ? configuration.frame : UIScreen.main.bounds
        if adVideoView == nil {
            adVideoView = ZDLaunchAdVideoView(frame: adVideoViewFrame)
        }
        adVideoView.videoGravity = configuration.videoGravity
        adVideoView.isVideoCycleOnce = configuration.isVideoCycleOnce
        window.addSubview(adVideoView)
        
        //  添加跳过与倒计时
        addSkipButton(configuration: configuration)
        startSkipDispathTimer()
        
        //  添加配置中的子控件
        if let subViews = configuration.subViews, subViews.count > 0 {
            addSubViews(subViews)
        }
        
        //  广告视频的点击事件
        adVideoView.tapCallback = { [weak self] point, tap in
            self?.click(point: point)
        }
        
        //  判断是否是循环播放
        if configuration.isVideoCycleOnce {
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { (notification) in
                print("video不循环播放,播放完毕")
                NotificationCenter.default.post(name: .ZDLaunchAdVideoCycleOnceFinish, object: nil, userInfo: ["videoNameOrURLString": configuration.videoNameOrURLString])
            }
        }
        
        //  网络视频
        if !configuration.videoNameOrURLString.isEmpty && configuration.videoNameOrURLString.isUrl {
            ZDLaunchAdCacheManager.asyncSaveVideoUrl(configuration.videoNameOrURLString)
            
            guard let url = URL(string: configuration.videoNameOrURLString) else {
                return
            }
            
            // 判断是否有本地缓存
            if ZDLaunchAdCacheManager.checkVideoInCacheWithUrl(url) {
                guard let pathUrl = ZDLaunchAdCacheManager.getCacheVideoFileUrlWithUrl(url) else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.delegate?.launchAd(launchAd: self, videoDownloadFinish: pathUrl)
                }
                
                adVideoView.contentUrl = pathUrl
                adVideoView.isMuted = configuration.isMuted
                adVideoView.videoGravity = configuration.videoGravity
                adVideoView.player?.play()
                
            }else {
                
                DispatchQueue.main.async {
                    self.delegate?.launchAdShowDefaultAdImage(launchAd: self)
                }
                
                ZDLaunchAdDownloadManager.shared.downloadVideo(url: url, progressCallback: { (total, current) in
                    self.delegate?.launchAd(launchAd: self, downloadProgress: Double(current) / Double(total), total: total, current: current)
                }) { (location, error) in
                    self.delegate?.launchAd(launchAd: self, videoDownloadFinish: location)
                }

                adVideoView.image = configuration.placeholderAdImage
                
                DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(configuration.duration)) {
                    self.removeOnly()
                }
            }
            
            
            
        }else {
        //  本地视频
            if !configuration.videoNameOrURLString.isEmpty {
                let pathUrl: URL!
                guard let path = ZDLaunchAdCacheManager.videoPathWithFileName(configuration.videoNameOrURLString) else {
                    return
                }
                let cachePathURL = URL(fileURLWithPath: path)
                
                if !ZDLaunchAdCacheManager.checkVideoInCacheWithFileName(configuration.videoNameOrURLString) {
                    guard let bundleUrl = Bundle.main.url(forResource: configuration.videoNameOrURLString, withExtension: nil) else {
                        return
                    }
                    
                    DispatchQueue.global().async {
                        try? FileManager.default.copyItem(at: bundleUrl, to: cachePathURL)
                    }
                    pathUrl = bundleUrl
                }else {
                    pathUrl = cachePathURL
                }
                
                delegate?.launchAd(launchAd: self, videoDownloadFinish: pathUrl)
                
                adVideoView.contentUrl = pathUrl
                adVideoView.videoGravity = configuration.videoGravity
                adVideoView.isMuted = configuration.isMuted
                adVideoView.player?.play()
                
            }else {
                print("未设置广告视频")
            }
        }
    }
    
    /// 搭建跳过按钮
    ///
    /// - Parameter configuration: 配置
    private func addSkipButton(configuration: ZDLaunchAdConfiguration) {
        if let customSkipView = configuration.customSkipView {
            window.addSubview(customSkipView)
        }else {
            if skipButton == nil {
                skipButton = ZDLaunchAdButton(skipType: configuration.skipButtonType)
                skipButton.isHidden = false
                skipButton.addTarget(self, action: #selector(skipButtonAction(_:)), for: .touchUpInside)
            }
            
            window.addSubview(skipButton)
            skipButton.setTitle(skipType: configuration.skipButtonType, duration: configuration.duration)
        }
    }
}

extension ZDLaunchAd {
    
    /// 跳过倒计时的配置
    private func startSkipDispathTimer() {
        let configuration = commonConfiguration()
        waitDataTimer?.cancel()
        waitDataTimer = nil
        
        var duration = configuration.duration
        
        if configuration.skipButtonType == .roundProgressTime || configuration.skipButtonType == .roundProgressText {
            skipButton?.startRoundDispathTimer(duration: CGFloat(duration))
        }
        
        let period = 1.0
        let skipTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global())
        skipTimer.schedule(wallDeadline: .now(), repeating: period)
        self.skipTimer = skipTimer
        skipTimer.setEventHandler {
            DispatchQueue.main.async {
                self.delegate?.launchAd(launchAd: self, customSkipView: configuration.customSkipView, duration: duration)
                
                if configuration.customSkipView == nil {
                    self.skipButton.setTitle(skipType: configuration.skipButtonType, duration: duration)
                }
                
                if duration == 0 {
                    self.skipTimer?.cancel()
                    self.skipTimer = nil
                    
                    self.removeByAnimated()
                }
                
                duration = duration - 1
            }
        }
        skipTimer.resume()
    }
    
    /// 等待网络请求数据倒计时配置
    private func startWaitDataDispathTimer() {
        var duration = waitDataDuration == nil ? 3 : waitDataDuration!
        
        let period = 1.0
        let waitDataTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global())
        waitDataTimer.schedule(wallDeadline: .now(), repeating: period)
        self.waitDataTimer = waitDataTimer
        waitDataTimer.setEventHandler {
            if duration == 0 {
                self.waitDataTimer?.cancel()
                self.waitDataTimer = nil
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .ZDLaunchAdWaitDataDurationArrive, object: nil, userInfo: nil)
                    self.remove()
                    return
                }
            }
            duration = duration - 1
        }
        waitDataTimer.resume()
    }
}

extension ZDLaunchAd {
    
    /// 跳过按钮的点击事件
    ///
    /// - Parameter button: 按钮
    @objc private func skipButtonAction(_ button: ZDLaunchAdButton) {
        removeWithAnimated()
    }
    
    /// 启动页的点击事件
    ///
    /// - Parameter point: 点击的位置
    private func click(point: CGPoint) {
        clickPoint = point
        let configuration = commonConfiguration()
        delegate?.launchAd(launchAd: self, click: configuration.openModel, clickPoint: point)
    }
}

extension ZDLaunchAd {
    
    /// 添加子控件集
    ///
    /// - Parameter subViews: 子控件集
    private func addSubViews(_ subViews: [UIView]) {
        for subView in subViews {
            window.addSubview(subView)
        }
    }
    
    /// 清除广告页 并 代理回调
    private func remove() {
        removeOnly()
        delegate?.launchAdShowFinish(launchAd: self)
    }
    
    /// 清除
    private func removeOnly() {
        
        waitDataTimer?.cancel()
        waitDataTimer = nil
        skipTimer?.cancel()
        skipTimer = nil
        skipButton = nil
        detailPageShowing = false
        
        if launchAdType == .video {
            adVideoView?.stopVideoPlayer()
            adVideoView?.removeFromSuperview()
            adVideoView = nil
        }
        
        if window != nil {
            for subView in window.subviews {
                subView.removeFromSuperview()
            }
            window.isHidden = true
            window = nil
        }
    }
    
    /// 动画效果清除
    private func removeByAnimated() {
        let configutation = commonConfiguration()
        var options: UIView.AnimationOptions!
        switch configutation.showFinishAnimate {
        case .none:
            remove()
            return
        case .fadein:
            options = UIView.AnimationOptions.showHideTransitionViews
        case .lite:
            options = UIView.AnimationOptions.curveEaseOut
        case .flipFromLeft:
            options = UIView.AnimationOptions.transitionFlipFromLeft
        case .flipFromBottom:
            options = UIView.AnimationOptions.transitionFlipFromBottom
        case .curUp:
            options = UIView.AnimationOptions.transitionCurlUp
        }
        
        UIView.transition(with: window, duration: TimeInterval(configutation.showFinishAnimateTime), options: options, animations: {
            self.window.alpha = 0
        }) { (finish) in
            self.remove()
        }
    }

    /// 清除除了启动页之外的子控件
    private func removeSubviewsExpectLaunchAdImageView() {
        guard let realWindow = window else { return }
        for subview in realWindow.subviews where !(subview is ZDLaunchImageView) {
            subview.removeFromSuperview()
        }
    }
    
    /// 清除 是否有动画效果
    ///
    /// - Parameter animatde: 是否有动画效果
    private func removeWithAnimated(animatde: Bool = true) {
        if animatde {
            removeByAnimated()
        }else {
            remove()
        }
    }
}
