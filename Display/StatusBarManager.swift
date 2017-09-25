import Foundation
import AsyncDisplayKit

private struct MappedStatusBar {
    let style: StatusBarStyle
    let frame: CGRect
    let statusBar: StatusBar?
}

private struct MappedStatusBarSurface {
    let statusBars: [MappedStatusBar]
    let surface: StatusBarSurface
}

private func mapStatusBar(_ statusBar: StatusBar, forceInCall: Bool) -> MappedStatusBar {
    let frame = CGRect(origin: statusBar.view.convert(CGPoint(), to: nil), size: statusBar.frame.size)
    let resolvedStyle: StatusBarStyle
    switch statusBar.statusBarStyle {
        case .Black, .White:
            if forceInCall {
                resolvedStyle = .White
            } else {
                resolvedStyle = statusBar.statusBarStyle
            }
        default:
            resolvedStyle = statusBar.statusBarStyle
    }
    return MappedStatusBar(style: resolvedStyle, frame: frame, statusBar: statusBar)
}

private func mappedSurface(_ surface: StatusBarSurface, forceInCall: Bool) -> MappedStatusBarSurface {
    var statusBars: [MappedStatusBar] = []
    for statusBar in surface.statusBars {
        if statusBar.statusBarStyle != .Ignore {
            statusBars.append(mapStatusBar(statusBar, forceInCall: forceInCall))
        }
    }
    return MappedStatusBarSurface(statusBars: statusBars, surface: surface)
}

private func optimizeMappedSurface(statusBarSize: CGSize, surface: MappedStatusBarSurface, forceInCall: Bool) -> MappedStatusBarSurface {
    if surface.statusBars.count > 1 {
        for i in 1 ..< surface.statusBars.count {
            if (!forceInCall && surface.statusBars[i].style != surface.statusBars[i - 1].style) || abs(surface.statusBars[i].frame.origin.y - surface.statusBars[i - 1].frame.origin.y) > CGFloat.ulpOfOne {
                return surface
            }
            if let lhsStatusBar = surface.statusBars[i - 1].statusBar, let rhsStatusBar = surface.statusBars[i].statusBar , !lhsStatusBar.alpha.isEqual(to: rhsStatusBar.alpha) {
                return surface
            }
        }
        let size = statusBarSize
        return MappedStatusBarSurface(statusBars: [MappedStatusBar(style: forceInCall ? .White : surface.statusBars[0].style, frame: CGRect(origin: CGPoint(x: 0.0, y: surface.statusBars[0].frame.origin.y), size: size), statusBar: nil)], surface: surface.surface)
    } else {
        return surface
    }
}

private func displayHiddenAnimation() -> CAAnimation {
    let animation = CABasicAnimation(keyPath: "transform.translation.y")
    animation.fromValue = NSNumber(value: Float(-40.0))
    animation.toValue = NSNumber(value: Float(-40.0))
    animation.fillMode = kCAFillModeBoth
    animation.duration = 1.0
    animation.speed = 0.0
    animation.isAdditive = true
    animation.isRemovedOnCompletion = false
    
    return animation
}

class StatusBarManager {
    private var host: StatusBarHost
    
    private var surfaces: [StatusBarSurface] = []
    
    var inCallNavigate: (() -> Void)?
    
    init(host: StatusBarHost) {
        self.host = host
    }
    
    func updateState(surfaces: [StatusBarSurface], forceInCallStatusBarText: String?, animated: Bool) {
        let previousSurfaces = self.surfaces
        self.surfaces = surfaces
        self.updateSurfaces(previousSurfaces, forceInCallStatusBarText: forceInCallStatusBarText, animated: animated)
    }
    
    private func updateSurfaces(_ previousSurfaces: [StatusBarSurface], forceInCallStatusBarText: String?, animated: Bool) {
        let statusBarFrame = self.host.statusBarFrame
        guard let statusBarView = self.host.statusBarView else {
            return
        }
        
        if self.host.statusBarWindow?.isUserInteractionEnabled != (forceInCallStatusBarText == nil) {
            self.host.statusBarWindow?.isUserInteractionEnabled = (forceInCallStatusBarText == nil)
        }
        
        var mappedSurfaces: [MappedStatusBarSurface] = []
        var mapIndex = 0
        var doNotOptimize = false
        for surface in self.surfaces {
            inner: for statusBar in surface.statusBars {
                if statusBar.statusBarStyle == .Hide {
                    doNotOptimize = true
                    break inner
                }
            }
            
            let mapped = mappedSurface(surface, forceInCall: forceInCallStatusBarText != nil)
            
            if doNotOptimize {
                mappedSurfaces.append(mapped)
            } else {
                mappedSurfaces.append(optimizeMappedSurface(statusBarSize: statusBarFrame.size, surface: mapped, forceInCall: forceInCallStatusBarText != nil))
            }
            mapIndex += 1
        }
        
        var reduceSurfaces = true
        var reduceSurfacesStatusBarStyleAndAlpha: (StatusBarStyle, CGFloat)?
        var reduceIndex = 0
        outer: for surface in mappedSurfaces {
            for mappedStatusBar in surface.statusBars {
                if reduceIndex == 0 && mappedStatusBar.style == .Hide {
                    reduceSurfaces = false
                    break outer
                }
                if mappedStatusBar.frame.origin.equalTo(CGPoint()) {
                    let statusBarAlpha = mappedStatusBar.statusBar?.alpha ?? 1.0
                    if let reduceSurfacesStatusBarStyleAndAlpha = reduceSurfacesStatusBarStyleAndAlpha {
                        if mappedStatusBar.style != reduceSurfacesStatusBarStyleAndAlpha.0 {
                            reduceSurfaces = false
                            break outer
                        }
                        if !statusBarAlpha.isEqual(to: reduceSurfacesStatusBarStyleAndAlpha.1) {
                            reduceSurfaces = false
                            break outer
                        }
                    } else {
                        reduceSurfacesStatusBarStyleAndAlpha = (mappedStatusBar.style, statusBarAlpha)
                    }
                }
            }
            reduceIndex += 1
        }
        
        if reduceSurfaces {
            outer: for surface in mappedSurfaces {
                for mappedStatusBar in surface.statusBars {
                    if mappedStatusBar.frame.origin.equalTo(CGPoint()) {
                        if let statusBar = mappedStatusBar.statusBar , !statusBar.layer.hasPositionOrOpacityAnimations() {
                            mappedSurfaces = [MappedStatusBarSurface(statusBars: [mappedStatusBar], surface: surface.surface)]
                            break outer
                        }
                    }
                }
            }
        }
        
        var visibleStatusBars: [StatusBar] = []
        
        var globalStatusBar: (StatusBarStyle, CGFloat, CGFloat)?
        
        var coveredIdentity = false
        var statusBarIndex = 0
        for i in 0 ..< mappedSurfaces.count {
            for mappedStatusBar in mappedSurfaces[i].statusBars {
                if let statusBar = mappedStatusBar.statusBar {
                    if mappedStatusBar.frame.origin.equalTo(CGPoint()) && !statusBar.layer.hasPositionOrOpacityAnimations() && !statusBar.offsetNode.layer.hasPositionAnimations() {
                        if !coveredIdentity {
                            if statusBar.statusBarStyle != .Hide {
                                if statusBar.offsetNode.frame.origin.equalTo(CGPoint()) {
                                    coveredIdentity = CGFloat(1.0).isLessThanOrEqualTo(statusBar.alpha)
                                }
                                if statusBarIndex == 0 && globalStatusBar == nil {
                                    globalStatusBar = (mappedStatusBar.style, statusBar.alpha, statusBar.offsetNode.frame.origin.y)
                                } else {
                                    visibleStatusBars.append(statusBar)
                                }
                            }
                        }
                    } else {
                        visibleStatusBars.append(statusBar)
                    }
                } else {
                    if !coveredIdentity {
                        coveredIdentity = true
                        if statusBarIndex == 0 && globalStatusBar == nil {
                            globalStatusBar = (mappedStatusBar.style, 1.0, 0.0)
                        }
                    }
                }
                statusBarIndex += 1
            }
        }
        
        for surface in previousSurfaces {
            for statusBar in surface.statusBars {
                if !visibleStatusBars.contains(where: {$0 === statusBar}) {
                    statusBar.updateState(statusBar: nil, inCallText: forceInCallStatusBarText, animated: animated)
                }
            }
        }
        
        for surface in self.surfaces {
            for statusBar in surface.statusBars {
                statusBar.inCallNavigate = self.inCallNavigate
                if !visibleStatusBars.contains(where: {$0 === statusBar}) {
                    statusBar.updateState(statusBar: nil, inCallText: forceInCallStatusBarText, animated: animated)
                }
            }
        }
        
        for statusBar in visibleStatusBars {
            statusBar.updateState(statusBar: statusBarView, inCallText: forceInCallStatusBarText, animated: animated)
        }
        
        if let globalStatusBar = globalStatusBar {
            let statusBarStyle: UIStatusBarStyle
            if forceInCallStatusBarText != nil {
                statusBarStyle = .lightContent
            } else {
                statusBarStyle = globalStatusBar.0 == .Black ? .default : .lightContent
            }
            if self.host.statusBarStyle != statusBarStyle {
                self.host.statusBarStyle = statusBarStyle
            }
            if let statusBarWindow = self.host.statusBarWindow {
                statusBarWindow.alpha = globalStatusBar.1
                var statusBarBounds = statusBarWindow.bounds
                if !statusBarBounds.origin.y.isEqual(to: globalStatusBar.2) {
                    statusBarBounds.origin.y = globalStatusBar.2
                    statusBarWindow.bounds = statusBarBounds
                }
            }
        } else if let statusBarWindow = self.host.statusBarWindow {
            statusBarWindow.alpha = 0.0
        }
    }
}
