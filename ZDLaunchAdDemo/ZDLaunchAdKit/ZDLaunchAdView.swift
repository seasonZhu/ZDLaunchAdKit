//
//  ZDLaunchAdView.swift
//  ZDLaunchAdDemo
//
//  Created by season on 2018/7/30.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit
import AVKit

/// 广告图view
class ZDLaunchAdImageView: UIImageView {
    
    //MARK:- 属性设置
    
    //  手势回调
    var tapCallback: ((CGPoint, UITapGestureRecognizer) -> ())?
    
    //MARK:- 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        self.frame = frame
        layer.masksToBounds = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction(_ :)))
        addGestureRecognizer(tap)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- 手势的点击事件
    @objc private func tapAction(_ tap: UITapGestureRecognizer) {
        let point = tap.location(in: self)
        tapCallback?(point, tap)
    }
}

/// 广告视频view
class ZDLaunchAdVideoView: UIImageView {
    //MARK:- 属性设置
    
    //  字符串常量
    private let status = "status"
    
    //  点击回调
    var tapCallback: ((CGPoint, UITapGestureRecognizer) -> ())?
    
    //  视频的填满模式
    var videoGravity: AVLayerVideoGravity = AVLayerVideoGravity.resizeAspect {
        didSet {
            playerLayer?.videoGravity = videoGravity
        }
    }
    
    //  是否只播放一次 默认是只播放一次
    var isVideoCycleOnce = true
    
    //  是否静音
    var isMuted = false {
        didSet {
            player?.isMuted = isMuted
        }
    }
    
    //  视频的url
    var contentUrl: URL! {
        didSet {
            if contentUrl == nil {
                return
            }
            
            playerItem = AVPlayerItem(url: contentUrl)
            player = AVPlayer(playerItem: playerItem)
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.frame = bounds
            playerItem?.addObserver(self, forKeyPath: status, options: .new, context: nil)
            
            //  注册是否循环播放
            NotificationCenter.default.addObserver(self, selector: #selector(runLoopTheMovie(_ :)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
    
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try? AVAudioSession.sharedInstance().setActive(true)
            
            guard let avlayer = playerLayer else { return }
            layer.addSublayer(avlayer)
        }
    }
    
    //  playerItem
    private var playerItem: AVPlayerItem?
    
    //  playerLayer
    private var playerLayer: AVPlayerLayer?
    
    //  player
    var player: AVPlayer?
    
    //MARK:- 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        self.frame = frame
        self.backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction(_ :)))
        tap.delegate = self
        addGestureRecognizer(tap)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- 手势的点击事件
    @objc private func tapAction(_ tap: UITapGestureRecognizer) {
        let point = tap.location(in: self)
        tapCallback?(point, tap)
    }
    
    //MARK:- 反复播放
    @objc private func runLoopTheMovie(_ notification: Notification) {
        if !isVideoCycleOnce {
            guard let avPlayerItem = notification.object as? AVPlayerItem else {
                return
            }
            avPlayerItem.seek(to: CMTime.zero, completionHandler: nil)
            player?.play()
        }
    }
    
    //MARK:- 观察者模式
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let playerItem = object as? AVPlayerItem else { return }
        if keyPath == status {
            if playerItem.status == .failed {
                NotificationCenter.default.post(name: Notification.Name.ZDLaunchAdVideoPlayFailed, object: nil, userInfo: ["videoNameOrURLString": contentUrl.absoluteString])
            }
        }
    }
    
    //MARK:- 析构函数
    deinit {
        playerItem?.removeObserver(self, forKeyPath: status)
        playerItem = nil
        NotificationCenter.default.removeObserver(self)
    }
}

extension ZDLaunchAdVideoView {
    
    /// 停止播放
    func stopVideoPlayer() {
        if player == nil {
            return
        }

        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        
        player?.pause()
        player = nil
        
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ZDLaunchAdVideoView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
