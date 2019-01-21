//
//  ViewController.swift
//  ZDLaunchAdDemo
//
//  Created by season on 2018/7/26.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
    }
    
    private func setUpUI() {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: 30))
        label.numberOfLines = 0
        label.center = view.center
        label.text = "这家伙很懒,什么都没留下"
        label.textAlignment = .center
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapAction")) // 我是使用字面量初始化方法的
        label.isUserInteractionEnabled = true
        view.addSubview(label)
        
        let margin: CGFloat = 10
        let buttonCount: CGFloat = 4
        let buttonWidth = (kScreenWidth - (buttonCount + 1) * margin) / 4
        let buttonTitles = ["本地图片", "网络图片", "本地视频", "网络视频"]
        
        for (index, title) in buttonTitles.enumerated() {
            let button = UIButton(frame: CGRect(x: CGFloat(index + 1) * margin + CGFloat(index) * buttonWidth, y: view.center.y - 100, width: buttonWidth, height: 30))
            button.setTitle(title, for: .normal)
            button.setTitleColor(UIColor.white, for: .normal)
            button.tag = index + 1000
            button.backgroundColor = UIColor.lightGray
            button.addTarget(self, action: "buttonAction:", for: .touchUpInside)
            view.addSubview(button)
        }
    }
    
    //MARK:- label的点击事件
    @objc
    func tapAction() {
        exitApp()
    }
    
    //MARK:- 按钮的点击事件
    @objc
    func buttonAction(_ button: UIButton) {
        UserDefaults.standard.set(button.tag, forKey: "buttonTag")
        onlyUseDownloader()
    }
}

extension ViewController {
    //MARK:- 下载器的单独使用
    func onlyUseDownloader() {
        let url = URL.init(string: "https://dssp.dstsp.com/ow/static/manual/usermanual.pdf")
        ZDLaunchAdImageDownloader(url: url!, delegateQueue: OperationQueue.main, progressCallback: { (total, current) in
            print("total: \(total), current: \(current)")
        }) { (image, data, error) in
            print(data as Any)
            let filePath = ZDLaunchAd.launchAdCachePath() + "/" + "usermanual.pdf"
            let fileUrl = URL(fileURLWithPath: filePath)
            try? data?.write(to: fileUrl)
        }
    }
}

//MARK:- 退出App
func exitApp() {
    guard let app = UIApplication.shared.delegate, let window = app.window else { return }
    
    UIView.animate(withDuration: 1, animations: {
        window?.alpha = 0
    }) { (finish) in
        exit(0)
    }
}

/// 广告类型枚举
enum AdType: Int {
    case loacalImageAd = 1000,
         networkImageAd,
         loacalVideoAd,
         networkVideoAd
}
