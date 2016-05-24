import UIKit

class TextPresentationViewController:UIViewController {
    let label = UITextView()
    let blurStyle = UIBlurEffectStyle.Dark
    
    override func viewDidLoad() {
        
        let blurEffect = UIBlurEffect(style: blurStyle)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        view.addSubview(blurEffectView)
        
        let vibrancyEffect = UIVibrancyEffect(forBlurEffect: blurEffect)
        let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
        view.addSubview(vibrancyEffectView)
        
        label.frame = view.bounds
        label.scrollEnabled = true
        label.selectable = true
        label.userInteractionEnabled = true
        label.panGestureRecognizer.allowedTouchTypes = [UITouchType.Indirect.rawValue]
        label.allowsEditingTextAttributes = false
        label.bounces = false
        label.translatesAutoresizingMaskIntoConstraints = false
        vibrancyEffectView.addSubview(label)
        
        label.textContainerInset = UIEdgeInsets(top: 100, left: 400, bottom: 100, right: 400)
    }
}

class FocusTextView: UITextView {
    
    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        selectable = true
        scrollEnabled = false
        clipsToBounds = false
        textContainer.lineBreakMode = .ByTruncatingTail
        textContainerInset = UIEdgeInsetsZero
        
        blurEffectView.backgroundColor = UIColor.clearColor()
        blurEffectView.frame = CGRectInset(bounds, -10, -10)
        blurEffectView.alpha = 0
        blurEffectView.layer.cornerRadius = 10
        blurEffectView.clipsToBounds = true
        
        insertSubview(blurEffectView, atIndex: 0)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapped(_:)))
        tap.allowedPressTypes = [NSNumber(integer: UIPressType.Select.rawValue)]
        addGestureRecognizer(tap)
    }
    
    
    func tapped(gesture: UITapGestureRecognizer) {
        
        if let vc = delegate as? UIViewController {
            let modal = TextPresentationViewController()
            modal.label.text = attributedText.string
            modal.label.textColor = .whiteColor()
            modal.modalPresentationStyle = .OverFullScreen
            vc.presentViewController(modal, animated: true, completion: nil)
        }
    }
    
    override func canBecomeFocused() -> Bool {
        return true
    }
    
    override func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        
        if context.nextFocusedView == self {
            blurEffectView.alpha = 1

        } else if context.previouslyFocusedView == self {
            blurEffectView.alpha = 0
        }
    }
    
}