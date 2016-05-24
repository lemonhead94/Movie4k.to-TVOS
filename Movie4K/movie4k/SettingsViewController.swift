import Foundation
import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var englishFlag: FocusProviderView!
    @IBOutlet weak var germanFlag: FocusProviderView!
    
    private let focusGuide = UIFocusGuide()
    
    override func viewDidLoad() {
        let englishFlagTap = UITapGestureRecognizer(target: self, action: #selector(self.tapped(_:)))
        englishFlagTap.allowedPressTypes = [NSNumber(integer: UIPressType.Select.rawValue)]
        
        let germanFlagTap = UITapGestureRecognizer(target: self, action: #selector(self.tapped(_:)))
        germanFlagTap.allowedPressTypes = [NSNumber(integer: UIPressType.Select.rawValue)]
        
        englishFlag.addGestureRecognizer(englishFlagTap)
        germanFlag.addGestureRecognizer(germanFlagTap)
        
        setUpFocusGuide()
    }
    
    private func setUpFocusGuide() {
        view.addLayoutGuide(focusGuide)
        
        focusGuide.topAnchor.constraintEqualToAnchor(self.englishFlag.topAnchor).active = true
        focusGuide.bottomAnchor.constraintEqualToAnchor(self.englishFlag.bottomAnchor).active = true
        focusGuide.leadingAnchor.constraintEqualToAnchor(self.view.leadingAnchor).active = true
        focusGuide.widthAnchor.constraintEqualToAnchor(self.view.widthAnchor).active = true
    }
    
    override func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        guard let nextFocusedView = context.nextFocusedView else { return }
        
        switch nextFocusedView {
            case englishFlag:
                focusGuide.preferredFocusedView = germanFlag
            case germanFlag:
                focusGuide.preferredFocusedView = englishFlag
            default:
                focusGuide.preferredFocusedView = englishFlag
        }
    }
    
    func tapped(gesture: UIGestureRecognizer) {
        switch gesture.view! {
            case englishFlag:
                ServiceRegistry.loadMovie4KScraperService().currentLanguage = Language.English
                ServiceRegistry.loadTheMovieDBorgService().currentLanguage = Language.English
                NSUserDefaults.standardUserDefaults().setObject("en", forKey: "language")
                showAlert("LANGUAGE_ALERT_TITLE".localized, title: "LANGUAGE_ALERT_TEXT_ENGLISH".localized)
            case germanFlag:
                ServiceRegistry.loadMovie4KScraperService().currentLanguage = Language.German
                ServiceRegistry.loadTheMovieDBorgService().currentLanguage = Language.German
                NSUserDefaults.standardUserDefaults().setObject("de", forKey: "language")
                showAlert("LANGUAGE_ALERT_TITLE".localized, title: "LANGUAGE_ALERT_TEXT_GERMAN".localized)
            default:
                print("wat?")
        }
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    private func showAlert(status: String, title:String) {
        let alertController = UIAlertController(title: status, message: title, preferredStyle: .Alert)
        
        let ok = UIAlertAction(title: "OK", style: .Default) { (action) in }
        alertController.addAction(ok)
        
        self.presentViewController(alertController, animated: true) { }
    }
}