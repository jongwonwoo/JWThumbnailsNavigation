//
//  JWScrollStateMachine.swift
//  JWThumbnailsNavigation
//
//  Created by Jongwon Woo on 26/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit

enum JWScrollEvent: Int {
    case beginDragging
    case didScroll
    case willEndDragging
    case didEndDraggingAndNotDecelerating
    case didEndDraggingAndDecelerating
    case willBeginDecelerating
    case didEndDecelerating
    case didEndScrollingAnimation
}

@objc enum JWScrollState: Int {
    case beginDragging
    case dragging
    case beginDecelerating
    case decelerating
    case stop
}

@objc protocol JWScrollStateMachineDelegate {
    
    func scrollStateMachine(_ stateMachine: JWScrollStateMachine, didChangeState state: JWScrollState)
    
}

class JWScrollStateMachine: NSObject {
    
    weak var delegate: JWScrollStateMachineDelegate?
    
    private var state: JWScrollState = .stop {
        didSet {
            switch state {
            case .dragging, .decelerating, .stop:
                self.delegate?.scrollStateMachine(self, didChangeState: self.state)
            default:
                break
            }
        }
    }
    
    func scrolling(_ event: JWScrollEvent) {
        switch event {
        case .beginDragging:
            state = .beginDragging
        case .didScroll:
            if state == .beginDragging || state == .dragging {
                state = .dragging
            } else if state == .beginDecelerating || state == .decelerating {
                state = .decelerating
            }
        case .didEndDraggingAndNotDecelerating:
            state = .stop
        case .willBeginDecelerating:
            state = .beginDecelerating
        case .didEndDecelerating:
            if state != .stop {
                state = .stop
            }
        default:
            break
        }
    }
}
