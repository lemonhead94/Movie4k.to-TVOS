import UIKit
import SwiftyJSON
import Alamofire
import SVProgressHUD
import PromiseKit


class CinemaMoviesViewController: UIViewController {
    
    private var model: CinemaMoviesViewModel!
    @IBOutlet var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        model = CinemaMoviesViewModel()
        loadCinemaMovies()
    }
    
    @IBAction func refresh(sender: AnyObject) {
        model.removeAll()
        collectionView.reloadData()
        loadCinemaMovies()
    }
    
    private func loadCinemaMovies() {
        SVProgressHUD.show()
        ServiceRegistry.loadMovie4KScraperService().getCinemaMovies().then { movie4kResponse -> Promise<Void> in
            var cinemaMovieSearchPromises = [Promise<Void>]()
            for cinemaMovie in movie4kResponse {
                let promise = self.searchForMovieOnTheMovieDBorg(cinemaMovie)
                cinemaMovieSearchPromises.append(promise)
            }
            return when(cinemaMovieSearchPromises)
            
        }.always {
            SVProgressHUD.dismiss()
        }.error { error -> Void in
            print(error)
        }
    }
    
    private func searchForMovieOnTheMovieDBorg(cinemaMovie: (name: String, url: String, quality: String)) -> Promise<Void> {
        return ServiceRegistry.loadTheMovieDBorgService().search(cinemaMovie.name).then { json -> Void in
            var movie = Movie.fromJSONDictionary(json)
            movie.m4kName = cinemaMovie.name
            movie.m4kQuality = cinemaMovie.quality
            movie.m4kStartUrl = cinemaMovie.url
            self.model.addCinemaMovie(movie)
            
            let indexPath = NSIndexPath(forRow: self.collectionView.numberOfItemsInSection(0), inSection: 0)
            self.collectionView.insertItemsAtIndexPaths([indexPath])
        }
    }
}

extension CinemaMoviesViewController: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "Header", forIndexPath: indexPath) 
        
        return headerView
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Poster", forIndexPath: indexPath) as! Poster
        cell.imageView.image = nil
        
        if model.cinemaMovies.count > 0 {
            let movie = model.cinemaMovies[indexPath.row]
            
            if cell.gestureRecognizers?.count == nil {
                let tap = UITapGestureRecognizer(target: self, action: #selector(CinemaMoviesViewController.posterTap(_:)))
                tap.allowedPressTypes = [NSNumber(integer: UIPressType.Select.rawValue)]
                cell.addGestureRecognizer(tap)
            }
            
            loadPoster(movie.posterPath).then { image in
                cell.imageView.image = image
            }.error { error in
                print(error)
            }
            
            cell.label.type = .LeftRight
            cell.label.speed = .Rate(40)
            if movie.name != "" {
                cell.label.text = movie.name
            } else {
                cell.label.text = movie.m4kName
            }
            
        }
        return cell
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
    
    func posterTap(gesture: UIGestureRecognizer) {
        if let cell = gesture.view as? Poster {
            // load the next view controller and pass in the movie
            let indexPath = collectionView.indexPathForCell(cell)
            var movie = model.cinemaMovies[indexPath!.row]

            let movieDetailsPromise = ServiceRegistry.loadTheMovieDBorgService().loadMovieDetails("\(movie.id)")
            let movieCreditsPromise = ServiceRegistry.loadTheMovieDBorgService().loadMovieCredits("\(movie.id)")
            
            SVProgressHUD.show()
            when(movieDetailsPromise, movieCreditsPromise).then { movieDetails, creditsPromise -> Void in
                
                movie.runtime     = movieDetails.runtimeMin
                movie.genres      = movieDetails.genres
                movie.releaseYear = movieDetails.releaseYear
                movie.cast        = creditsPromise.cast
                movie.director    = creditsPromise.directors
                movie.writer      = creditsPromise.writers
                
                ServiceRegistry.loadApplicationStateService().selectedMovie = movie
                self.performSegueWithIdentifier("showMovieDetails", sender:self)
                
            }.always {
                SVProgressHUD.dismiss()
            }.error { error -> Void in
                print(error)
            }
        }
        
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.cinemaMovies.count
    }
    
    override func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        if let prev = context.previouslyFocusedView as? Poster {
            UIView.animateWithDuration(0.1, animations: { () -> Void in
                prev.imageView.frame = CGRect(x: 0, y: 0, width: 250, height: 375)
                prev.label.hidden = true

                prev.layer.shadowColor = UIColor.clearColor().CGColor
            })
        }
        
        if let next = context.nextFocusedView as? Poster {
            UIView.animateWithDuration(0.1, animations: { () -> Void in
                next.imageView.frame = CGRect(x: -15, y: -22.5, width: 280, height: 420)
                next.label.hidden = false
                
                next.layer.shadowColor = UIColor.blackColor().CGColor
                next.layer.shadowOpacity = 1
                next.layer.shadowOffset = CGSizeZero
                next.layer.shadowRadius = 20
            })
        }
    }
    
}

