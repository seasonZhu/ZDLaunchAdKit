//
//  Gif.swift
//  SwiftGif
//
//  Created by Arne Bahlo on 07.06.14.
//  Copyright (c) 2014 Arne Bahlo. All rights reserved.
//

import UIKit
import ImageIO

// MARK: - 这个是第三方
extension UIImageView {

    public func loadGif(name: String) {
        DispatchQueue.global().async {
            let image = UIImage.gif(name: name)
            DispatchQueue.main.async {
                self.image = image
            }
        }
    }

}

extension UIImage {

    public class func gif(data: Data) -> UIImage? {
        // Create source from data
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("SwiftGif: Source for the image does not exist")
            return nil
        }

        return UIImage.animatedImageWithSource(source)
    }

    public class func gif(url: String) -> UIImage? {
        // Validate URL
        guard let bundleURL = URL(string: url) else {
            print("SwiftGif: This image named \"\(url)\" does not exist")
            return nil
        }

        // Validate data
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            print("SwiftGif: Cannot turn image named \"\(url)\" into NSData")
            return nil
        }

        return gif(data: imageData)
    }

    public class func gif(name: String) -> UIImage? {
        // Check for existance of gif
        guard let bundleURL = Bundle.main
          .url(forResource: name, withExtension: "gif") else {
            print("SwiftGif: This image named \"\(name)\" does not exist")
            return nil
        }

        // Validate data
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            print("SwiftGif: Cannot turn image named \"\(name)\" into NSData")
            return nil
        }

        return gif(data: imageData)
    }

    internal class func delayForImageAtIndex(_ index: Int, source: CGImageSource!) -> Double {
        var delay = 0.1

        // Get dictionaries
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifPropertiesPointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 0)
        if CFDictionaryGetValueIfPresent(cfProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque(), gifPropertiesPointer) == false {
            return delay
        }

        let gifProperties:CFDictionary = unsafeBitCast(gifPropertiesPointer.pointee, to: CFDictionary.self)

        // Get delay time
        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(gifProperties,
                Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
            to: AnyObject.self)
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties,
                Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }

        delay = delayObject as? Double ?? 0

        if delay < 0.1 {
            delay = 0.1 // Make sure they're not too fast
        }

        return delay
    }

    internal class func gcdForPair(_ a: Int?, _ b: Int?) -> Int {
        var a = a
        var b = b
        // Check if one of them is nil
        if b == nil || a == nil {
            if b != nil {
                return b!
            } else if a != nil {
                return a!
            } else {
                return 0
            }
        }

        // Swap for modulo
        if a! < b! {
            let c = a
            a = b
            b = c
        }

        // Get greatest common divisor
        var rest: Int
        while true {
            rest = a! % b!

            if rest == 0 {
                return b! // Found it
            } else {
                a = b
                b = rest
            }
        }
    }

    internal class func gcdForArray(_ array: Array<Int>) -> Int {
        if array.isEmpty {
            return 1
        }

        var gcd = array[0]

        for val in array {
            gcd = UIImage.gcdForPair(val, gcd)
        }

        return gcd
    }

    internal class func animatedImageWithSource(_ source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        var images = [CGImage]()
        var delays = [Int]()

        // Fill arrays
        for i in 0..<count {
            // Add image
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(image)
            }

            // At it's delay in cs
            let delaySeconds = UIImage.delayForImageAtIndex(Int(i),
                source: source)
            delays.append(Int(delaySeconds * 1000.0)) // Seconds to ms
        }

        // Calculate full duration
        let duration: Int = {
            var sum = 0

            for val: Int in delays {
                sum += val
            }

            return sum
            }()

        // Get frames
        let gcd = gcdForArray(delays)
        var frames = [UIImage]()

        var frame: UIImage
        var frameCount: Int
        for i in 0..<count {
            frame = UIImage(cgImage: images[Int(i)])
            frameCount = Int(delays[Int(i)] / gcd)

            for _ in 0..<frameCount {
                frames.append(frame)
            }
        }

        // Heyhey
        let animation = UIImage.animatedImage(with: frames,
            duration: Double(duration) / 1000.0)

        return animation
    }

}

/*---------------------这是我写的---------------------*/

// MARK: - 获取gif的配置信息
extension UIImage {
    
    typealias GifInfoCallback = (_ images: [UIImage]?, _ duration: TimeInterval, _ times: [TimeInterval]) -> ()
    
    /// 通过data获取gif的图片数组以及gif的播放时间
    ///
    /// - Parameter data: 数据
    /// - Returns: 元组 图片数组 与gif的播放时间
    class func getGifImageInfo(data: Data) -> (images: [UIImage]?, duration: TimeInterval, times: [TimeInterval]) {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            return (nil, 0, [])
        }
        
        let frameCount = CGImageSourceGetCount(imageSource)
        
        var duration : TimeInterval = 0
        var images = [UIImage]()
        var times = [TimeInterval]()
        
        for i in 0..<frameCount {
            //  1.获取图片
            guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, i, nil) else { continue }
            //  2.获取时长
            guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil),
                let gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary,
                let frameDuration = (gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber) else { continue }
            print("gifInfo: \(gifInfo)")
            duration += frameDuration.doubleValue
            
            times.append(frameDuration.doubleValue)
            
            let image = UIImage(cgImage: cgImage)
            images.append(image)
        }
        
        return (images, duration, times)
    }
    
    class func getGifImageInfo(frome url: URL) -> (images: [UIImage]?, duration: TimeInterval, times: [TimeInterval]) {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return (nil, 0, [])
        }
        
        let frameCount = CGImageSourceGetCount(imageSource)
        
        var duration : TimeInterval = 0
        var images = [UIImage]()
        var times = [TimeInterval]()
        
        for i in 0..<frameCount {
            //  1.获取图片
            guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, i, nil) else { continue }
            //  2.获取时长
            guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil),
                let gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary,
                let frameDuration = (gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber) else { continue }
            print("properties: \(properties)")
            duration += frameDuration.doubleValue
            
            times.append(frameDuration.doubleValue)
            
            let image = UIImage(cgImage: cgImage)
            images.append(image)
        }
        return (images, duration, times)
    }
    
    class func asyncGetGifImagInfo(data: Data, gifInfoCallback: @escaping GifInfoCallback) {
        DispatchQueue.global().async {
            let gifInfo = getGifImageInfo(data: data)
            DispatchQueue.main.async {
                gifInfoCallback(gifInfo.images, gifInfo.duration, gifInfo.times)
            }
        }
    }
    
    class func asyncGetGifImagInfo(frome url: URL, gifInfoCallback: @escaping GifInfoCallback) {
        DispatchQueue.global().async {
            let gifInfo = getGifImageInfo(frome: url)
            DispatchQueue.main.async {
                gifInfoCallback(gifInfo.images, gifInfo.duration, gifInfo.times)
            }
        }
    }
}

// MARK: - 播发GIF并且监听播发完成
extension UIImageView {
    
    /// 播发GIF并且监听播发完成
    ///
    /// - Parameters:
    ///   - data: 数据
    ///   - repeatCount: 播发重复次数 为0的时候为循环播发
    ///   - runable: 播放完成的回调 注意repeatCount > 0 的时候才会执行
    func playGif(data: Data, repeatCount: Int = 0, runable: (() -> ())? = nil) {
        UIImage.asyncGetGifImagInfo(data: data) { (images, duration, _) in
            self.animationImages = images
            self.animationDuration = duration
            self.animationRepeatCount = repeatCount
            let delayTime = self.animationDuration * TimeInterval(self.animationRepeatCount)
            print("gif start before isAnimating: \(self.isAnimating)")
            self.startAnimating()
            print("gif start after isAnimating: \(self.isAnimating)")
            
            //  如果repeatCount大于0,说明可以观察gif是否结束,并且在结束的时候做回调
            if repeatCount > 0 {
                self.image = images?.first
                DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
                    self.stopAnimating()
                    print("GIF播放玩了")
                    print("gif complete isAnimating: \(self.isAnimating)")
                    runable?()
                }
            }
        }
    }
    
    func playGif(frome url: URL, repeatCount: Int = 0, runable: (() -> ())? = nil) {
        UIImage.asyncGetGifImagInfo(frome: url) { (images, duration, _) in
            self.animationImages = images
            self.animationDuration = duration
            self.animationRepeatCount = repeatCount
            let delayTime = self.animationDuration * TimeInterval(self.animationRepeatCount)
            print("gif start before isAnimating: \(self.isAnimating)")
            self.startAnimating()
            print("gif start after isAnimating: \(self.isAnimating)")
            
            //  如果repeatCount大于0,说明可以观察gif是否结束,并且在结束的时候做回调
            if repeatCount > 0 {
                self.image = images?.first
                DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
                    self.stopAnimating()
                    print("GIF播放玩了")
                    print("gif complete isAnimating: \(self.isAnimating)")
                    runable?()
                }
            }
        }
    }
}

