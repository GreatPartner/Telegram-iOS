import UIKit
import AsyncDisplayKit

public enum ContainedViewLayoutTransitionCurve {
    case easeInOut
    case spring
}

public extension ContainedViewLayoutTransitionCurve {
    var timingFunction: String {
        switch self {
            case .easeInOut:
                return kCAMediaTimingFunctionEaseInEaseOut
            case .spring:
                return kCAMediaTimingFunctionSpring
        }
    }
    
    var viewAnimationOptions: UIViewAnimationOptions {
        switch self {
            case .easeInOut:
                return [.curveEaseInOut]
            case .spring:
                return UIViewAnimationOptions(rawValue: 7 << 16)
        }
    }
}

public enum ContainedViewLayoutTransition {
    case immediate
    case animated(duration: Double, curve: ContainedViewLayoutTransitionCurve)
    
    public var isAnimated: Bool {
        if case .immediate = self {
            return false
        } else {
            return true
        }
    }
}

public extension ContainedViewLayoutTransition {
    func updateFrame(node: ASDisplayNode, frame: CGRect, force: Bool = false, completion: ((Bool) -> Void)? = nil) {
        if node.frame.equalTo(frame) && !force {
            completion?(true)
        } else {
            switch self {
                case .immediate:
                    node.frame = frame
                    if let completion = completion {
                        completion(true)
                    }
                case let .animated(duration, curve):
                    let previousFrame = node.frame
                    node.frame = frame
                    node.layer.animateFrame(from: previousFrame, to: frame, duration: duration, timingFunction: curve.timingFunction, force: force, completion: { result in
                        if let completion = completion {
                            completion(result)
                        }
                    })
            }
        }
    }
    
    func updateBounds(node: ASDisplayNode, bounds: CGRect, completion: ((Bool) -> Void)? = nil) {
        if node.bounds.equalTo(bounds) {
            completion?(true)
        } else {
            switch self {
                case .immediate:
                    node.bounds = bounds
                    if let completion = completion {
                        completion(true)
                    }
                case let .animated(duration, curve):
                    let previousBounds = node.bounds
                    node.bounds = bounds
                    node.layer.animateBounds(from: previousBounds, to: bounds, duration: duration, timingFunction: curve.timingFunction, completion: { result in
                        if let completion = completion {
                            completion(result)
                        }
                    })
                }
        }
    }
    
    func updatePosition(node: ASDisplayNode, position: CGPoint, completion: ((Bool) -> Void)? = nil) {
        if node.position.equalTo(position) {
            completion?(true)
        } else {
            switch self {
                case .immediate:
                    node.position = position
                    if let completion = completion {
                        completion(true)
                    }
                case let .animated(duration, curve):
                    let previousPosition = node.position
                    node.position = position
                    node.layer.animatePosition(from: previousPosition, to: position, duration: duration, timingFunction: curve.timingFunction, completion: { result in
                        if let completion = completion {
                            completion(result)
                        }
                    })
            }
        }
    }
    
    func animatePosition(node: ASDisplayNode, from position: CGPoint, completion: ((Bool) -> Void)? = nil) {
        switch self {
            case .immediate:
                if let completion = completion {
                    completion(true)
                }
            case let .animated(duration, curve):
                node.layer.animatePosition(from: position, to: node.position, duration: duration, timingFunction: curve.timingFunction, completion: { result in
                    if let completion = completion {
                        completion(result)
                    }
                })
        }
    }
    
    func animatePosition(node: ASDisplayNode, to position: CGPoint, removeOnCompletion: Bool = true, completion: ((Bool) -> Void)? = nil) {
        if node.position.equalTo(position) {
            completion?(true)
        } else {
            switch self {
                case .immediate:
                    if let completion = completion {
                        completion(true)
                    }
                case let .animated(duration, curve):
                    node.layer.animatePosition(from: node.position, to: position, duration: duration, timingFunction: curve.timingFunction, removeOnCompletion: removeOnCompletion, completion: { result in
                        if let completion = completion {
                            completion(result)
                        }
                    })
            }
        }
    }
    
    func animateBounds(layer: CALayer, from bounds: CGRect, removeOnCompletion: Bool = true, completion: ((Bool) -> Void)? = nil) {
            switch self {
                case .immediate:
                    if let completion = completion {
                        completion(true)
                    }
                case let .animated(duration, curve):
                    layer.animateBounds(from: bounds, to: layer.bounds, duration: duration, timingFunction: curve.timingFunction, removeOnCompletion: removeOnCompletion, completion: { result in
                        if let completion = completion {
                            completion(result)
                        }
                    })
            }
    }
    
    func animateOffsetAdditive(node: ASDisplayNode, offset: CGFloat) {
        switch self {
            case .immediate:
                break
            case let .animated(duration, curve):
                let timingFunction: String
                switch curve {
                    case .easeInOut:
                        timingFunction = kCAMediaTimingFunctionEaseInEaseOut
                    case .spring:
                        timingFunction = kCAMediaTimingFunctionSpring
                }
                node.layer.animateBoundsOriginYAdditive(from: offset, to: 0.0, duration: duration, timingFunction: timingFunction)
        }
    }
    
    func animateOffsetAdditive(layer: CALayer, offset: CGFloat) {
        switch self {
            case .immediate:
                break
            case let .animated(duration, curve):
                let timingFunction: String
                switch curve {
                    case .easeInOut:
                        timingFunction = kCAMediaTimingFunctionEaseInEaseOut
                    case .spring:
                        timingFunction = kCAMediaTimingFunctionSpring
                }
                layer.animateBoundsOriginYAdditive(from: offset, to: 0.0, duration: duration, timingFunction: timingFunction)
        }
    }
    
    func animatePositionAdditive(node: ASDisplayNode, offset: CGFloat) {
        switch self {
            case .immediate:
                break
            case let .animated(duration, curve):
                let timingFunction: String
                switch curve {
                    case .easeInOut:
                        timingFunction = kCAMediaTimingFunctionEaseInEaseOut
                    case .spring:
                        timingFunction = kCAMediaTimingFunctionSpring
                }
                node.layer.animatePosition(from: CGPoint(x: 0.0, y: offset), to: CGPoint(), duration: duration, timingFunction: timingFunction, additive: true)
        }
    }
    
    func updateFrame(layer: CALayer, frame: CGRect, completion: ((Bool) -> Void)? = nil) {
        if layer.frame.equalTo(frame) {
            completion?(true)
        } else {
            switch self {
                case .immediate:
                    layer.frame = frame
                    if let completion = completion {
                        completion(true)
                    }
                case let .animated(duration, curve):
                    let previousFrame = layer.frame
                    layer.frame = frame
                    layer.animateFrame(from: previousFrame, to: frame, duration: duration, timingFunction: curve.timingFunction, completion: { result in
                        if let completion = completion {
                            completion(result)
                        }
                    })
            }
        }
    }
    
    func updateAlpha(node: ASDisplayNode, alpha: CGFloat, completion: ((Bool) -> Void)? = nil) {
        if node.alpha.isEqual(to: alpha) {
            if let completion = completion {
                completion(true)
            }
            return
        }
        
        switch self {
            case .immediate:
                node.alpha = alpha
                if let completion = completion {
                    completion(true)
                }
            case let .animated(duration, curve):
                let previousAlpha = node.alpha
                node.alpha = alpha
                node.layer.animateAlpha(from: previousAlpha, to: alpha, duration: duration, timingFunction: curve.timingFunction, completion: { result in
                    if let completion = completion {
                        completion(result)
                    }
                })
        }
    }
    
    func updateAlpha(layer: CALayer, alpha: CGFloat, completion: ((Bool) -> Void)? = nil) {
        if layer.opacity.isEqual(to: Float(alpha)) {
            if let completion = completion {
                completion(true)
            }
            return
        }
        
        switch self {
            case .immediate:
                layer.opacity = Float(alpha)
                if let completion = completion {
                    completion(true)
                }
            case let .animated(duration, curve):
                let previousAlpha = layer.opacity
                layer.opacity = Float(alpha)
                layer.animateAlpha(from: CGFloat(previousAlpha), to: alpha, duration: duration, timingFunction: curve.timingFunction, completion: { result in
                    if let completion = completion {
                        completion(result)
                    }
                })
        }
    }
    
    func updateBackgroundColor(node: ASDisplayNode, color: UIColor, completion: ((Bool) -> Void)? = nil) {
        if let nodeColor = node.backgroundColor, nodeColor.isEqual(color) {
            if let completion = completion {
                completion(true)
            }
            return
        }
        
        switch self {
            case .immediate:
                node.backgroundColor = color
                if let completion = completion {
                    completion(true)
                }
            case let .animated(duration, curve):
                if let nodeColor = node.backgroundColor {
                    node.backgroundColor = color
                    node.layer.animate(from: nodeColor.cgColor, to: color.cgColor, keyPath: "backgroundColor", timingFunction: curve.timingFunction, duration: duration, completion: { result in
                        if let completion = completion {
                            completion(result)
                        }
                    })
                } else {
                    node.backgroundColor = color
                    if let completion = completion {
                        completion(true)
                    }
                }
        }
    }
    
    func updateTransformScale(node: ASDisplayNode, scale: CGFloat, completion: ((Bool) -> Void)? = nil) {
        let t = node.layer.transform
        let currentScale = sqrt((t.m11 * t.m11) + (t.m12 * t.m12) + (t.m13 * t.m13))
        if currentScale.isEqual(to: scale) {
            if let completion = completion {
                completion(true)
            }
            return
        }
        
        switch self {
            case .immediate:
                node.layer.transform = CATransform3DMakeScale(scale, scale, 1.0)
                if let completion = completion {
                    completion(true)
                }
            case let .animated(duration, curve):
                node.layer.transform = CATransform3DMakeScale(scale, scale, 1.0)
                node.layer.animateScale(from: currentScale, to: scale, duration: duration, timingFunction: curve.timingFunction, completion: { result in
                    if let completion = completion {
                        completion(result)
                    }
                })
        }
    }
}

public extension ContainedViewLayoutTransition {
    public func animateView(_ f: @escaping () -> Void) {
        switch self {
            case .immediate:
                f()
            case let .animated(duration, curve):
                UIView.animate(withDuration: duration, delay: 0.0, options: curve.viewAnimationOptions, animations: {
                    f()
                }, completion: nil)
        }
    }
}

public protocol ContainableController: class {
    var view: UIView! { get }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition)
}
