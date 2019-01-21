//
//  UserDefine.swift
//  ZDLaunchAdDemo
//
//  Created by season on 2018/7/26.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

//  屏宽
let kScreenWidth: CGFloat = UIScreen.main.bounds.size.width

//  屏高
let kScreenHeight: CGFloat = UIScreen.main.bounds.size.height

//  是否是iPhoneX
let isiPhoneX: Bool = {
    if #available(iOS 11, *) {
        guard let w = UIApplication.shared.delegate?.window, let unwrapedWindow = w else {
            return false
        }
        
        if unwrapedWindow.safeAreaInsets.left > 0 || unwrapedWindow.safeAreaInsets.bottom > 0 {
            return true
        }
    }
    return false
}()

//  UserDefault的存储的key
let ZDCacheImageUrlStringKey = "ZDCacheImageUrlStringKey";
let ZDCacheVideoUrlStringKey = "ZDCacheVideoUrlStringKey";


