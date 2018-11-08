//
//  HLSGestureHelper.swift
//  HLSAudioPlayer
//
//  Created by Rafael Nobre on 06/11/18.
//

import UIKit

private let minimumSwipeVelocity: CGFloat = 500

public class HLSGestureHelper: NSObject {
    public var isDraggingEnabled = true
    public var isSnappingEnabled = true
    
    private let targetView: UIView
    private let centerXConstraint: NSLayoutConstraint
    private let centerYConstraint: NSLayoutConstraint
    
    private lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        return UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
    }()
    
    public init(targetView: UIView, centerXConstraint: NSLayoutConstraint, centerYConstraint: NSLayoutConstraint) {
        self.targetView = targetView
        self.centerXConstraint = centerXConstraint
        self.centerYConstraint = centerYConstraint
        super.init()
        targetView.addGestureRecognizer(panGestureRecognizer)
    }
    
    deinit {
        targetView.removeGestureRecognizer(panGestureRecognizer)
    }
    
    @objc private func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .changed && isDraggingEnabled {
            let translation = recognizer.translation(in: targetView.superview)
            centerXConstraint.constant += translation.x
            centerYConstraint.constant += translation.y
        }
        else if recognizer.state == .ended && isSnappingEnabled {
            guard let superview = targetView.superview else { return }
            let pinnedX = superview.bounds.width / 2 - targetView.bounds.width / 2
            let pinnedY =  superview.bounds.height / 2 - targetView.bounds.height / 2
            let velocity = recognizer.velocity(in: targetView.superview)
            
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut], animations: {
                if velocity.x > minimumSwipeVelocity {
                    self.centerXConstraint.constant = pinnedX
                }
                else if velocity.x < -minimumSwipeVelocity {
                    self.centerXConstraint.constant = -pinnedX
                }
                if velocity.y > minimumSwipeVelocity {
                    self.centerYConstraint.constant = pinnedY
                }
                else if velocity.y < -minimumSwipeVelocity {
                    self.centerYConstraint.constant = -pinnedY
                }
                superview.layoutIfNeeded()
            })
        }
        recognizer.setTranslation(.zero, in: targetView.superview)
    }

}
