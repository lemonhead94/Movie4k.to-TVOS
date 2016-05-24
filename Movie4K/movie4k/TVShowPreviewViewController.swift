import UIKit
import Cosmos
import MarqueeLabel
import Alamofire
import SVProgressHUD
import PromiseKit

class TVShowPreviewViewController: UIViewController {
    
    @IBOutlet weak var rating: CosmosView!
    @IBOutlet weak var tvshowTitle: MarqueeLabel!
    @IBOutlet weak var overview: FocusTextView!
    @IBOutlet weak var poster: UIImageView!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var totalSeasons: UILabel!
    @IBOutlet weak var totalEpisodes: UILabel!
    @IBOutlet weak var genres: UITextView!
    @IBOutlet weak var directors: UITextView!
    @IBOutlet weak var transparentView: UIView!
    
    private let tvShow = ServiceRegistry.loadApplicationStateService().selectedSerie
    private let focusGuide = UIFocusGuide()
    
    
    override func viewDidLoad() {
        loadBackgroundImage(tvShow!.backdropPath).then { image -> Void in
            self.view.backgroundColor = UIColor(patternImage: image)
            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.frame = self.view.bounds
            blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            blurEffectView.alpha = 0.8
            self.view.insertSubview(blurEffectView, atIndex: 0)
        }.always {
            SVProgressHUD.dismiss()
        }.error { error in
            print(error)
        }
        setUpFocusGuide()
    }
    
    override func viewWillAppear(animated: Bool) {
        poster.hidden = true
        loadPoster(tvShow!.posterPath).then { image -> Void in
            self.poster.image = image
            self.poster.hidden = false
        }.error { error in
                print(error)
        }
        
        if tvShow!.rating != "" {
            rating.rating = Double(tvShow!.rating)! / 2
        } else {
            rating.rating = 0.0
        }
        tvshowTitle.type = .LeftRight
        tvshowTitle.text = tvShow!.name
        overview.text = tvShow!.overview
        status.text = tvShow!.status
        totalSeasons.text = "\(tvShow!.totalNumberOfSeasons)"
        totalEpisodes.text = "\(tvShow!.totalNumberOfEpisodes)"
        
        for genre in tvShow!.genres {
            genres.text = genres.text + genre + "\n"
        }
        
        for director in tvShow!.directors {
            directors.text = directors.text + director + "\n"
        }
    }
    
    private func loadBackgroundImage(backdropPath: String) -> Promise<UIImage> {
        return Promise { fulfill, reject in
            Alamofire.request(.GET, backdropPath).responseData { response in
                switch response.result {
                case .Success(let data):
                    if let image = UIImage(data: data) {
                        fulfill(image)
                    } else {
                        reject(TheMovieDBorgServiceError.NothingFoundOnTheMovieDBorg)
                    }
                case .Failure(let error):
                    reject(error)
                }
            }
        }
    }
    
    private func loadPoster(posterPath: String) -> Promise<UIImage> {
        return Promise { fulfill, reject in
            Alamofire.request(.GET, posterPath).responseData { response in
                switch response.result {
                case .Success(let data):
                    if let image = UIImage(data: data) {
                        fulfill(image)
                    } else {
                        reject(TheMovieDBorgServiceError.NothingFoundOnTheMovieDBorg)
                    }
                case .Failure(let error):
                    reject(error)
                }
            }
        }
    }
    
    private func setUpFocusGuide() {
        focusGuide.preferredFocusedView = self.overview
        view.addLayoutGuide(focusGuide)
        
        focusGuide.topAnchor.constraintEqualToAnchor(self.overview.topAnchor).active = true
        focusGuide.bottomAnchor.constraintEqualToAnchor(self.transparentView.bottomAnchor).active = true
        focusGuide.leadingAnchor.constraintEqualToAnchor(self.transparentView.leadingAnchor).active = true
        focusGuide.widthAnchor.constraintEqualToAnchor(self.transparentView.widthAnchor).active = true
    }
    
}