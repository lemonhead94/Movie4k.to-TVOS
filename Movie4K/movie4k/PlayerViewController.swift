import Foundation
import AVFoundation
import AVKit

class PlayerViewController: AVPlayerViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    func setup() {
        if let path = ServiceRegistry.loadApplicationStateService().selectedVideoUrl {
            self.player = AVPlayer(URL: NSURL(string: path)!)
        } else {
            print("Oops, could not find resource Video.mp4")
        }
    }
}