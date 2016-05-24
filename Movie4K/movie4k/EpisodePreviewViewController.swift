import UIKit
import Cosmos
import MarqueeLabel
import Alamofire
import SVProgressHUD
import PromiseKit

class EpisodePreviewViewController: UIViewController {
    
    @IBOutlet weak var rating: CosmosView!
    @IBOutlet weak var episodeTitle: MarqueeLabel!
    @IBOutlet weak var overview: FocusTextView!
    @IBOutlet weak var poster: UIImageView!
    @IBOutlet weak var airDate: UILabel!
    @IBOutlet weak var directors: UITextView!
    @IBOutlet weak var writers: UITextView!
    @IBOutlet weak var guestStars: UITextView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var transparentView: UIView!
    
    let tvShow = ServiceRegistry.loadApplicationStateService().selectedSerie
    let season = ServiceRegistry.loadApplicationStateService().selectedSeason
    let episode = ServiceRegistry.loadApplicationStateService().selectedEpisode
    
    override func viewDidLoad() {
        SVProgressHUD.show()
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
        
        loadPoster(tvShow!.posterPath).then { image -> Void in
            self.poster.image = image
            self.poster.hidden = false
            }.error { error in
                print(error)
        }
        rating.rating = episode!.rating / 2
        episodeTitle.text = episode!.name
        episodeTitle.type = .LeftRight
        overview.text = episode!.overview
        airDate.text = episode!.airDate
        
        for director in episode!.director {
            directors.text = directors.text + director + "\n"
        }
        
        for writer in episode!.writer {
            writers.text = writers.text + writer + "\n"
        }
        
        for guestStar in episode!.guestStars {
            guestStars.text = guestStars.text + guestStar + "\n"
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
        let focusGuide = UIFocusGuide()
        focusGuide.preferredFocusedView = self.overview
        view.addLayoutGuide(focusGuide)
        
        focusGuide.topAnchor.constraintEqualToAnchor(self.overview.topAnchor).active = true
        focusGuide.bottomAnchor.constraintEqualToAnchor(self.transparentView.bottomAnchor).active = true
        focusGuide.leadingAnchor.constraintEqualToAnchor(self.transparentView.leadingAnchor).active = true
        focusGuide.widthAnchor.constraintEqualToAnchor(self.transparentView.widthAnchor).active = true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if (segue.identifier == "episodePreviewEmbedSegue") {
            let vc = segue.destinationViewController as! EpisodeViewController
            vc.episodePreviewViewControllerDelegate = self
        }
        
        if (segue.identifier == "showStreamChooserViewController") {
            setVideoUrlForSelectedEpisode()
        }
    }
    
    override var preferredFocusedView: UIView? {
        get {
            return self.containerView
        }
    }
    
    private func setVideoUrlForSelectedEpisode() {
        let seasonNumber = ServiceRegistry.loadApplicationStateService().selectedSeason?.seasonNumber
        let episodeNumber = ServiceRegistry.loadApplicationStateService().selectedEpisode?.episodeNumber
        
        for m4kSeason in ServiceRegistry.loadApplicationStateService().serieM4kLinks! where m4kSeason.seasonNumber == seasonNumber {
            for m4kEpisode in m4kSeason.episodes where m4kEpisode.episodeNumber == episodeNumber {
                ServiceRegistry.loadApplicationStateService().selectedVideoUrl = m4kEpisode.url
            }
        }
    }
    
    func updateUIForEpisode(episodeIndex: Int) {
        
        let episode = ServiceRegistry.loadApplicationStateService().selectedSeason!.episodes![episodeIndex]
        
        rating.rating = episode.rating / 2
        episodeTitle.text = episode.name
        overview.text = episode.overview
        airDate.text = episode.airDate
        
        directors.text = ""
        for director in episode.director {
            directors.text = directors.text + director + "\n"
        }
        
        writers.text = ""
        for writer in episode.writer {
            writers.text = writers.text + writer + "\n"
        }
        
        guestStars.text = ""
        for guestStar in episode.guestStars {
            guestStars.text = guestStars.text + guestStar + "\n"
        }
    }
    
}
