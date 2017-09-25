import UIKit

@objc private class CALayerAnimationDelegate: NSObject, CAAnimationDelegate {
    var completion: ((Bool) -> Void)?
    
    init(completion: ((Bool) -> Void)?) {
        self.completion = completion
        
        super.init()
    }
    
    @objc func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if let completion = self.completion {
            completion(flag)
        }
    }
}

private let completionKey = "CAAnimationUtils_completion"

public let kCAMediaTimingFunctionSpring = "CAAnimationUtilsSpringCurve"

public extension CAAnimation {
    public var completion: ((Bool) -> Void)? {
        get {
            if let delegate = self.delegate as? CALayerAnimationDelegate {
                return delegate.completion
            } else {
                return nil
            }
        } set(value) {
            if let delegate = self.delegate as? CALayerAnimationDelegate {
                delegate.completion = value
            } else {
                self.delegate = CALayerAnimationDelegate(completion: value)
            }
        }
    }
}

public extension CALayer {
    public func makeAnimation(from: AnyObject, to: AnyObject, keyPath: String, timingFunction: String, duration: Double, mediaTimingFunction: CAMediaTimingFunction? = nil, removeOnCompletion: Bool = true, additive: Bool = false, completion: ((Bool) -> Void)? = nil) -> CAAnimation {
        if timingFunction == kCAMediaTimingFunctionSpring {
            let animation = makeSpringAnimation(keyPath)
            animation.fromValue = from
            animation.toValue = to
            animation.isRemovedOnCompletion = removeOnCompletion
            animation.fillMode = kCAFillModeForwards
            if let completion = completion {
                animation.delegate = CALayerAnimationDelegate(completion: completion)
            }
            
            let k = Float(UIView.animationDurationFactor())
            var speed: Float = 1.0
            if k != 0 && k != 1 {
                speed = Float(1.0) / k
            }
            
            animation.speed = speed * Float(animation.duration / duration)
            animation.isAdditive = additive
            
            return animation
        } else {
            let k = Float(UIView.animationDurationFactor())
            var speed: Float = 1.0
            if k != 0 && k != 1 {
                speed = Float(1.0) / k
            }
            
            let animation = CABasicAnimation(keyPath: keyPath)
            animation.fromValue = from
            animation.toValue = to
            animation.duration = duration
            if let mediaTimingFunction = mediaTimingFunction {
                animation.timingFunction = mediaTimingFunction
            } else {
                animation.timingFunction = CAMediaTimingFunction(name: timingFunction)
            }
            animation.isRemovedOnCompletion = removeOnCompletion
            animation.fillMode = kCAFillModeForwards
            animation.speed = speed
            animation.isAdditive = additive
            if let completion = completion {
                animation.delegate = CALayerAnimationDelegate(completion: completion)
            }
            
            return animation
        }
    }
    
    public func animate(from: AnyObject, to: AnyObject, keyPath: String, timingFunction: String, duration: Double, mediaTimingFunction: CAMediaTimingFunction? = nil, removeOnCompletion: Bool = true, additive: Bool = false, completion: ((Bool) -> Void)? = nil) {
        let animation = self.makeAnimation(from: from, to: to, keyPath: keyPath, timingFunction: timingFunction, duration: duration, mediaTimingFunction: mediaTimingFunction, removeOnCompletion: removeOnCompletion, additive: additive, completion: completion)
        self.add(animation, forKey: additive ? nil : keyPath)
    }
    
    public func animateGroup(_ animations: [CAAnimation], key: String) {
        let animationGroup = CAAnimationGroup()
        var timeOffset = 0.0
        for animation in animations {
            animation.beginTime = animation.beginTime + timeOffset
            timeOffset += animation.duration / Double(animation.speed)
        }
        animationGroup.animations = animations
        animationGroup.duration = timeOffset
        self.add(animationGroup, forKey: key)
    }
    
    public func animateKeyframes(values: [AnyObject], duration: Double, keyPath: String, removeOnCompletion: Bool = true, completion: ((Bool) -> Void)? = nil) {
        let k = Float(UIView.animationDurationFactor())
        var speed: Float = 1.0
        if k != 0 && k != 1 {
            speed = Float(1.0) / k
        }
        
        let animation = CAKeyframeAnimation(keyPath: keyPath)
        animation.values = values
        var keyTimes: [NSNumber] = []
        for i in 0 ..< values.count {
            if i == 0 {
                keyTimes.append(0.0)
            } else if i == values.count - 1 {
                keyTimes.append(1.0)
            } else {
                keyTimes.append((Double(i) / Double(values.count - 1)) as NSNumber)
            }
        }
        animation.keyTimes = keyTimes
        animation.speed = speed
        animation.duration = duration
        if let completion = completion {
            animation.delegate = CALayerAnimationDelegate(completion: completion)
        }
        
        self.add(animation, forKey: keyPath)
    }

    public func animateSpring(from: AnyObject, to: AnyObject, keyPath: String, duration: Double, initialVelocity: CGFloat = 0.0, damping: CGFloat = 88.0, removeOnCompletion: Bool = true, additive: Bool = false, completion: ((Bool) -> Void)? = nil) {
        let animation: CABasicAnimation
        if #available(iOS 9.0, *) {
            animation = makeSpringBounceAnimation(keyPath, initialVelocity, damping)
        } else {
            animation = makeSpringAnimation(keyPath)
        }
        animation.fromValue = from
        animation.toValue = to
        animation.isRemovedOnCompletion = removeOnCompletion
        animation.fillMode = kCAFillModeForwards
        if let completion = completion {
            animation.delegate = CALayerAnimationDelegate(completion: completion)
        }
        
        let k = Float(UIView.animationDurationFactor())
        var speed: Float = 1.0
        if k != 0 && k != 1 {
            speed = Float(1.0) / k
        }
        
        animation.speed = speed * Float(animation.duration / duration)
        animation.isAdditive = additive
        
        self.add(animation, forKey: keyPath)
    }
    
    public func animateAdditive(from: NSValue, to: NSValue, keyPath: String, key: String, timingFunction: String, duration: Double, removeOnCompletion: Bool = true, completion: ((Bool) -> Void)? = nil) {
        let k = Float(UIView.animationDurationFactor())
        var speed: Float = 1.0
        if k != 0 && k != 1 {
            speed = Float(1.0) / k
        }
        
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = from
        animation.toValue = to
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: timingFunction)
        animation.isRemovedOnCompletion = removeOnCompletion
        animation.fillMode = kCAFillModeForwards
        animation.speed = speed
        animation.isAdditive = true
        if let completion = completion {
            animation.delegate = CALayerAnimationDelegate(completion: completion)
        }
        
        self.add(animation, forKey: key)
    }
    
    public func animateAlpha(from: CGFloat, to: CGFloat, duration: Double, timingFunction: String = kCAMediaTimingFunctionEaseInEaseOut, removeOnCompletion: Bool = true, completion: ((Bool) -> ())? = nil) {
        self.animate(from: NSNumber(value: Float(from)), to: NSNumber(value: Float(to)), keyPath: "opacity", timingFunction: timingFunction, duration: duration, removeOnCompletion: removeOnCompletion, completion: completion)
    }
    
    public func animateScale(from: CGFloat, to: CGFloat, duration: Double, timingFunction: String = kCAMediaTimingFunctionEaseInEaseOut, removeOnCompletion: Bool = true, completion: ((Bool) -> Void)? = nil) {
        self.animate(from: NSNumber(value: Float(from)), to: NSNumber(value: Float(to)), keyPath: "transform.scale", timingFunction: timingFunction, duration: duration, removeOnCompletion: removeOnCompletion, completion: completion)
    }
    
    func animatePosition(from: CGPoint, to: CGPoint, duration: Double, timingFunction: String = kCAMediaTimingFunctionEaseInEaseOut, removeOnCompletion: Bool = true, additive: Bool = false, force: Bool = false, completion: ((Bool) -> Void)? = nil) {
        if from == to && !force {
            if let completion = completion {
                completion(true)
            }
            return
        }
        self.animate(from: NSValue(cgPoint: from), to: NSValue(cgPoint: to), keyPath: "position", timingFunction: timingFunction, duration: duration, removeOnCompletion: removeOnCompletion, additive: additive, completion: completion)
    }
    
    func animateBounds(from: CGRect, to: CGRect, duration: Double, timingFunction: String, removeOnCompletion: Bool = true, additive: Bool = false, force: Bool = false, completion: ((Bool) -> Void)? = nil) {
        if from == to && !force {
            if let completion = completion {
                completion(true)
            }
            return
        }
        self.animate(from: NSValue(cgRect: from), to: NSValue(cgRect: to), keyPath: "bounds", timingFunction: timingFunction, duration: duration, removeOnCompletion: removeOnCompletion, additive: additive, completion: completion)
    }
    
    public func animateBoundsOriginYAdditive(from: CGFloat, to: CGFloat, duration: Double, timingFunction: String = kCAMediaTimingFunctionEaseInEaseOut, removeOnCompletion: Bool = true, completion: ((Bool) -> Void)? = nil) {
        self.animate(from: from as NSNumber, to: to as NSNumber, keyPath: "bounds.origin.y", timingFunction: timingFunction, duration: duration, removeOnCompletion: removeOnCompletion, additive: true, completion: completion)
    }
    
    public func animateBoundsOriginYAdditive(from: CGFloat, to: CGFloat, duration: Double, mediaTimingFunction: CAMediaTimingFunction) {
        self.animate(from: from as NSNumber, to: to as NSNumber, keyPath: "bounds.origin.y", timingFunction: kCAMediaTimingFunctionEaseInEaseOut, duration: duration, mediaTimingFunction: mediaTimingFunction, additive: true)
    }
    
    public func animatePositionKeyframes(values: [CGPoint], duration: Double, removeOnCompletion: Bool = true, completion: ((Bool) -> Void)? = nil) {
        self.animateKeyframes(values: values.map { NSValue(cgPoint: $0) }, duration: duration, keyPath: "position")
    }
    
    public func animateFrame(from: CGRect, to: CGRect, duration: Double, timingFunction: String, removeOnCompletion: Bool = true, additive: Bool = false, force: Bool = false, completion: ((Bool) -> Void)? = nil) {
        if from == to && !force {
            if let completion = completion {
                completion(true)
            }
            return
        }
        var interrupted = false
        var completedPosition = false
        var completedBounds = false
        let partialCompletion: () -> Void = {
            if interrupted || (completedPosition && completedBounds) {
                if let completion = completion {
                    completion(!interrupted)
                }
            }
        }
        self.animatePosition(from: CGPoint(x: from.midX, y: from.midY), to: CGPoint(x: to.midX, y: to.midY), duration: duration, timingFunction: timingFunction, removeOnCompletion: removeOnCompletion, additive: additive, force: force, completion: { value in
            if !value {
                interrupted = true
            }
            completedPosition = true
            partialCompletion()
        })
        self.animateBounds(from: CGRect(origin: self.bounds.origin, size: from.size), to: CGRect(origin: self.bounds.origin, size: to.size), duration: duration, timingFunction: timingFunction, removeOnCompletion: removeOnCompletion, additive: additive, force: force, completion: { value in
            if !value {
                interrupted = true
            }
            completedBounds = true
            partialCompletion()
        })
    }
    
    public func cancelAnimationsRecursive(key: String) {
        self.removeAnimation(forKey: key)
        if let sublayers = self.sublayers {
            for layer in sublayers {
                layer.cancelAnimationsRecursive(key: key)
            }
        }
    }
}
