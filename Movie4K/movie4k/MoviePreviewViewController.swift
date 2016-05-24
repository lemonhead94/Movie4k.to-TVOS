import Foundation
import UIKit
import Cosmos
import Alamofire
import MarqueeLabel
import SVProgressHUD
import PromiseKit

class MoviePreviewViewController: UIViewController {
    
    @IBOutlet weak var movieTitle: MarqueeLabel!
    @IBOutlet weak var rating: CosmosView!
    @IBOutlet weak var movieLengthGenreAndYear: UILabel!
    @IBOutlet weak var movieDescription: UITextView!
    @IBOutlet weak var directorsView: UITextView!
    @IBOutlet weak var castView: UITextView!
    @IBOutlet weak var writerView: UITextView!
    @IBOutlet weak var movieQuality: CosmosView!
    @IBOutlet weak var poster: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    
    let movie = ServiceRegistry.loadApplicationStateService().selectedMovie
    
    override func viewDidLoad() {
        loadBackgroundImage(movie!.backdropPath).then { image -> Void in
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
    }
    
    override func viewWillAppear(animated: Bool) {
        poster.hidden = true
        ServiceRegistry.loadApplicationStateService().selectedVideoUrl = movie?.m4kStartUrl
        
        if movie?.name != "" {
            movieTitle.text = movie?.name
        } else {
            movieTitle.text = movie?.m4kName
        }
        
        movieTitle.type = .LeftRight
        if movie!.rating != "" {
            rating.rating = Double(movie!.rating)! / 2
        } else {
            rating.rating = 0.0
        }
        movieDescription.text = movie?.overview
        setCrewAndDetails(movie!)
        setMovieQuality(movie!)
        
        loadPoster(movie!.posterPath).then { image -> Void in
            self.poster.image = image
            self.poster.hidden = false
        }.error { error in
                print(error)
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
    
    override var preferredFocusedView: UIView? {
        get {
            return self.playButton
        }
    }
    
    private func setCrewAndDetails(movie: Movie) {
        movieLengthGenreAndYear.text =  movie.runtime! + " min "
        for genre in movie.genres! {
            movieLengthGenreAndYear.text = movieLengthGenreAndYear.text! + genre
            if genre != movie.genres!.last {
                movieLengthGenreAndYear.text = movieLengthGenreAndYear.text! + ", "
            } else {
                movieLengthGenreAndYear.text = movieLengthGenreAndYear.text! + " " + movie.releaseYear!
            }
        }
        for director in movie.director! {
            directorsView.text = directorsView.text + director + "\n"
        }
        for writer in movie.writer! {
            writerView.text = writerView.text + writer + "\n"
        }
        for cast in movie.cast! {
            castView.text = castView.text + cast + "\n"
        }
    }
    
    private func setMovieQuality(movie: Movie) {
        switch movie.m4kQuality! {
            case "/img/smileys/5.gif":
                movieQuality.rating = 5.0
            case "/img/smileys/4.gif":
                movieQuality.rating = 4.0
            case "/img/smileys/3.gif":
                movieQuality.rating = 3.0
            case "/img/smileys/2.gif":
                movieQuality.rating = 2.0
            case "/img/smileys/1.gif":
                movieQuality.rating = 1.0
            case "/img/smileys/0.gif":
                movieQuality.rating = 0.0
            default:
                print("Movie Quality Error")
        }
    }
}