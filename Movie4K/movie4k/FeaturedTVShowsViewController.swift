import UIKit
import SwiftyJSON
import Alamofire
import SVProgressHUD
import PromiseKit

class FeaturedTVShowsViewController: UIViewController {

    var tvShows = [TvShow]()
    @IBOutlet var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadFeaturedTVShows()
    }
    
    @IBAction func refresh(sender: AnyObject) {
        tvShows.removeAll()
        collectionView.reloadData()
        loadFeaturedTVShows()
    }
    
    private func loadFeaturedTVShows() {
        SVProgressHUD.show()
        ServiceRegistry.loadMovie4KScraperService().getFeaturedTVShows().then { response -> Void in
            
            var searchPromises = [Promise<Void>]()
            for show in response {
                let searchText = self.prepareForSearchOnMovieDBOrg(show.name)
                let promise = self.searchOnTheMovieDBorg(searchText, show: show)
                searchPromises.append(promise)
            }
            
            when(searchPromises).always {
                SVProgressHUD.dismiss()
            }.error { error -> Void in
                print(error)
            }
            
        }.error { error -> Void in
            SVProgressHUD.dismiss()
            print(error)
        }
    }
    
    private func searchOnTheMovieDBorg(searchText: String, show: (name: String, url: String)) -> Promise<Void> {
        return ServiceRegistry.loadTheMovieDBorgService().search(searchText).then { json -> Void in
            var tv = TvShow.fromJSONDictionary(json)
            tv.m4kName = show.name
            tv.m4kStartUrl = show.url
            self.tvShows.append(tv)
            
            let indexPath = NSIndexPath(forRow: self.collectionView.numberOfItemsInSection(0), inSection: 0)
            self.collectionView.insertItemsAtIndexPaths([indexPath])
        }
    }
}

extension FeaturedTVShowsViewController: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "Header", forIndexPath: indexPath)
        
        return headerView
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Poster", forIndexPath: indexPath) as! Poster
        cell.imageView.image = nil
        
        if self.tvShows.count > 0 {
            let show = self.tvShows[indexPath.row]
            
            if cell.gestureRecognizers?.count == nil {
                let tap = UITapGestureRecognizer(target: self, action: #selector(FeaturedTVShowsViewController.posterTap(_:)))
                tap.allowedPressTypes = [NSNumber(integer: UIPressType.Select.rawValue)]
                cell.addGestureRecognizer(tap)
            }
            
            loadPoster(show.posterPath).then { image in
                cell.imageView.image = image
            }.error { error in
                print(error)
            }
            
            cell.label.type = .LeftRight
            cell.label.speed = .Rate(40)
            if show.name != "" {
                cell.label.text = show.name
            } else {
                cell.label.text = show.m4kName
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
            let indexPath = collectionView.indexPathForCell(cell)
            let show = self.tvShows[indexPath!.row]
            
            SVProgressHUD.show()
            firstly {
                return ServiceRegistry.loadTheMovieDBorgService().search(show.name)
            }.then { json -> Promise<JSON> in
                let id = json["id"].intValue
                return ServiceRegistry.loadTheMovieDBorgService().loadSeasonDetailsForTvShowId(id)
            }.then { (json: JSON) -> Promise<Void> in
                
                var serie = TvShow.fromJSONDictionary(json)
                serie.m4kStartUrl = show.m4kStartUrl
                var seasons = [Season]()
                for season in json["seasons"].arrayValue {
                    if season["season_number"].intValue != 0 {
                        seasons.append(Season.fromJSONDictionary(season))
                    }
                }
                serie.seasons = seasons
                
                var episodePromises = [Promise<Void>]()
                for (index, _) in seasons.enumerate() {
                    let promise = ServiceRegistry.loadTheMovieDBorgService().loadEpisodeDetailsForTvShowId(serie.id, seasonNumber: index + 1).then { json -> Void in
                        var episodes = [Episode]()
                        for episode in json["episodes"].arrayValue {
                            episodes.append(Episode.fromJSONDictionary(episode))
                        }
                        serie.seasons![index].episodes = episodes
                    }
                    episodePromises.append(promise)
                }
                return when(episodePromises).then { _ -> Promise<Void> in
                    ServiceRegistry.loadApplicationStateService().selectedSerie = serie
                    return ServiceRegistry.loadMovie4KScraperService().getSerieLinks(serie.m4kStartUrl!).then { result -> Void in
                        ServiceRegistry.loadApplicationStateService().serieM4kLinks = result
                        self.performSegueWithIdentifier("showTVShowDetails", sender:self)
                    }
                }
            }.error { error -> Void in
                SVProgressHUD.dismiss()
                print(error)
            }
        }
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tvShows.count
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
    
    private func prepareForSearchOnMovieDBOrg(text: String) -> String {
        var result = text
        
        // TODO: if * start and * end --> remove everything in between
        //       if ( start and ) end --> remove everything in between
        
        if result.lowercaseString.containsString("(serie)") {
            result = result.stringByReplacingOccurrencesOfString("(Serie)", withString: "")
            result = result.stringByReplacingOccurrencesOfString("(serie)", withString: "")
        }
        if result.lowercaseString.containsString("(tvshow)") {
            result = result.stringByReplacingOccurrencesOfString("(TVshow)", withString: "")
            result = result.stringByReplacingOccurrencesOfString("(tvshow)", withString: "")
        }
        if result.lowercaseString.containsString("*untertitelt*") {
            result = result.stringByReplacingOccurrencesOfString("*untertitelt*", withString: "")
            result = result.stringByReplacingOccurrencesOfString("*Untertitelt*", withString: "")
        }
        if result.lowercaseString.containsString("*untertitlelt*") {
            result = result.stringByReplacingOccurrencesOfString("*untertitlelt*", withString: "")
            result = result.stringByReplacingOccurrencesOfString("*Untertitlelt*", withString: "")
        }
        if result.lowercaseString.containsString("*subtitled*") {
            result = result.stringByReplacingOccurrencesOfString("*subtitled*", withString: "")
            result = result.stringByReplacingOccurrencesOfString("*Subtitled*", withString: "")
        }
        if result.lowercaseString.containsString("*unrated*") {
            result = result.stringByReplacingOccurrencesOfString("*unrated*", withString: "")
            result = result.stringByReplacingOccurrencesOfString("*Unrated*", withString: "")
        }
        if result.lowercaseString.containsString("*german subbed*") {
            result = result.stringByReplacingOccurrencesOfString("*german subbed*", withString: "")
            result = result.stringByReplacingOccurrencesOfString("*german Subbed*", withString: "")
        }
        if result.lowercaseString.containsString("*english subbed*") {
            result = result.stringByReplacingOccurrencesOfString("*english subbed*", withString: "")
            result = result.stringByReplacingOccurrencesOfString("*english Subbed*", withString: "")
        }
        return result
    }
    
}
