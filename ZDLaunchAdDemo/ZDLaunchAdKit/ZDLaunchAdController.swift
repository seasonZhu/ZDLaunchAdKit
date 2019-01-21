//
//  ZDLaunchAdController.swift
//  ZDLaunchAdDemo
//
//  Created by season on 2018/7/26.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

let ZDLaunchAdPrefersHomeIndicatorAutoHidden = false

class ZDLaunchAdController: UIViewController {

    func shouldAutorotate() -> Bool {
        return false
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return ZDLaunchAdPrefersHomeIndicatorAutoHidden
    }

}
