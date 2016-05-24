import Foundation
import UIKit

class ProviderAndStreamViewController: UIViewController {
    
    @IBOutlet weak var streamcloudView: FocusProviderView!
    @IBOutlet weak var nowvideoView: FocusProviderView!
    @IBOutlet weak var movshareView: FocusProviderView!
    @IBOutlet weak var cloudtimeView: FocusProviderView!
    @IBOutlet weak var sharedsxView: FocusProviderView!
    
    override func viewDidLoad() {
        let streamcloudTap = UITapGestureRecognizer(target: self, action: #selector(self.tapped(_:)))
        streamcloudTap.allowedPressTypes = [NSNumber(integer: UIPressType.Select.rawValue)]

        let nowvideoTap = UITapGestureRecognizer(target: self, action: #selector(self.tapped(_:)))
        nowvideoTap.allowedPressTypes = [NSNumber(integer: UIPressType.Select.rawValue)]
        
        let moveshareTap = UITapGestureRecognizer(target: self, action: #selector(self.tapped(_:)))
        moveshareTap.allowedPressTypes = [NSNumber(integer: UIPressType.Select.rawValue)]
        
        let cloudtimeTap = UITapGestureRecognizer(target: self, action: #selector(self.tapped(_:)))
        cloudtimeTap.allowedPressTypes = [NSNumber(integer: UIPressType.Select.rawValue)]
        
        let sharedsxTap = UITapGestureRecognizer(target: self, action: #selector(self.tapped(_:)))
        sharedsxTap.allowedPressTypes = [NSNumber(integer: UIPressType.Select.rawValue)]
        
        streamcloudView.addGestureRecognizer(streamcloudTap)
        nowvideoView.addGestureRecognizer(nowvideoTap)
        movshareView.addGestureRecognizer(moveshareTap)
        cloudtimeView.addGestureRecognizer(cloudtimeTap)
        sharedsxView.addGestureRecognizer(sharedsxTap)
    }
    
    func tapped(gesture: UIGestureRecognizer) {
        switch gesture.view! {
            case streamcloudView:
                ServiceRegistry.loadApplicationStateService().selectedProvider = .StreamCloud
            case nowvideoView:
                ServiceRegistry.loadApplicationStateService().selectedProvider = .NowVideo
            case movshareView:
                ServiceRegistry.loadApplicationStateService().selectedProvider = .MovShare
            case cloudtimeView:
                ServiceRegistry.loadApplicationStateService().selectedProvider = .CloudTime
            case sharedsxView:
                ServiceRegistry.loadApplicationStateService().selectedProvider = .ShareSx
            default:
                print("wat?")
        }
    }
    
}