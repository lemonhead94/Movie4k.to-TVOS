import Foundation
import UIKit

class FocusProviderView: UIView {
    
    override func canBecomeFocused() -> Bool {
        return true
    }
    
    override func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        
        if context.previouslyFocusedView == self {
            layer.shadowColor = UIColor.clearColor().CGColor
            
        } else if context.nextFocusedView == self {
            layer.shadowColor = UIColor.blackColor().CGColor
            layer.shadowOpacity = 1
            layer.shadowOffset = CGSizeZero
            layer.shadowRadius = 20
        }
    }
    
}