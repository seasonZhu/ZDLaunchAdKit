//
//  ZDLaunchAdButton.swift
//  ZDLaunchAdDemo
//
//  Created by season on 2018/7/26.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

public enum SkipType {
    case none,
         squareTime,
         squareText,
         squareTimeText,
         roundTime,
         roundText,
         roundProgressTime,
         roundProgressText
}

/// 跳过按钮
class ZDLaunchAdButton: UIButton {
    
    //MARK:- 常量
    private let roundProgressColor = UIColor.white
    
    private let bgColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
    
    private let fontColor = UIColor.white
    
    private let skipTitle = "跳过"
    
    private let s = "s"
    
    //MARK:- 属性设置
    private var skipType: SkipType = .none
    
    private var leftRightSpace: CGFloat = 0 {
        willSet {
            var newFrame = timeLabel.frame
            let width = newFrame.width
            if newValue <= 0 || newValue * 2 > width {
                return
            }
            newFrame = CGRect(x: newValue, y: newFrame.origin.y, width: width - 2 * newValue, height: newFrame.height)
            timeLabel.frame = newFrame
            cornerRadiusWithView(timeLabel)
        }
    }
    
    private var topBottomSpace: CGFloat = 0 {
        willSet {
            var newFrame = timeLabel.frame
            let height = newFrame.height
            if newValue <= 0 || newValue * 2 > height {
                return
            }
            newFrame = CGRect(x: frame.origin.x, y: newValue, width: newFrame.width, height: height - 2 * newValue)
            timeLabel.frame = newFrame
            cornerRadiusWithView(timeLabel)
        }
    }
    
    private lazy var timeLabel: UILabel = {
        let label = UILabel(frame: bounds)
        label.textColor = fontColor
        label.backgroundColor = bgColor
        label.layer.masksToBounds = true
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 13.5)
        cornerRadiusWithView(label)
        return label
    }()
    
    private lazy var roundLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = bgColor.cgColor
        layer.strokeColor = roundProgressColor.cgColor
        layer.lineCap = CAShapeLayerLineCap.round
        layer.lineJoin = CAShapeLayerLineJoin.round
        layer.lineWidth = 2
        layer.frame = bounds
        layer.path = UIBezierPath.init(arcCenter: CGPoint(x: timeLabel.bounds.width / 2, y: timeLabel.bounds.width / 2), radius: timeLabel.bounds.width / 2 - 1, startAngle: -0.5 * CGFloat(Double.pi), endAngle: 1.5 * CGFloat(Double.pi), clockwise: true).cgPath
        layer.strokeStart = 0
        return layer
    }()
    
    private var roundTimer: DispatchSourceTimer?
    
    convenience init(skipType: SkipType) {
        self.init()
        self.skipType = skipType
        
        let y: CGFloat = isiPhoneX ? 44 : 20
        
        if skipType == .roundText || skipType == .roundTime || skipType == .roundProgressText || skipType == .roundProgressTime {
            frame = CGRect(x: kScreenWidth - 55, y: y, width: 42, height: 42)
        }else {
            frame = CGRect(x: kScreenWidth - 80, y: y, width: 70, height: 35)
        }
        
        switch skipType {
        case .none:
            isHidden = true
        case .squareTime, .squareText, .squareTimeText:
            leftRightSpace = 5
            topBottomSpace = 2.5
        case .roundProgressText, .roundProgressTime:
            timeLabel.layer.addSublayer(roundLayer)
        default:
            break
        }
        
        addSubview(timeLabel)
    }
    
}

extension ZDLaunchAdButton {
    func setTitle(skipType: SkipType, duration: Int) {
        switch skipType {
        case .none:
            isHidden = true
        case .squareTime, .roundTime, .roundProgressTime:
            timeLabel.text = "\(duration)" + s
        case .squareText, .roundText, .roundProgressText:
            timeLabel.text = skipTitle
        case .squareTimeText:
            timeLabel.text = "\(duration)" + skipTitle
        }
    }
    
    func startRoundDispathTimer(duration: CGFloat) {
        let period: TimeInterval = 0.05
        let queue = DispatchQueue.global()
        var roundDuration = duration
        let roundTimer = DispatchSource.makeTimerSource(flags: [], queue: queue)
        self.roundTimer = roundTimer
        roundTimer.schedule(wallDeadline: .now(), repeating: period)
        roundTimer.setEventHandler(handler: {
            DispatchQueue.main.async {
                if roundDuration <= 0 {
                    self.roundLayer.strokeStart = 1
                    
                    self.roundTimer?.cancel()
                    self.roundTimer = nil
                }
                self.roundLayer.strokeStart += 1 / (duration / CGFloat(period))
                roundDuration -= CGFloat(period)
            }
        })
        roundTimer.resume()
    }
}

extension ZDLaunchAdButton {
    private func cornerRadiusWithView(_ view: UIView) {
        let min = view.frame.height > view.frame.width ? view.frame.width : view.frame.height
        view.layer.cornerRadius = min / 2.0
        view.layer.masksToBounds = true
    }
}
