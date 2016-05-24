import UIKit
import Alamofire
import SwiftyJSON
import SVProgressHUD
import PromiseKit

class SearchResultsViewController: UICollectionViewController, UISearchResultsUpdating {
    
    static let storyboardIdentifier = "SearchResultsViewController"
    var currentSearchPromise: SearchPromise?
    
    var searchResultsCollection = [Search]()
    var searchCriteria: String = ""
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchResultsCollection.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Poster", forIndexPath: indexPath) as! Poster
        cell.imageView.image = nil
        if self.searchResultsCollection.count >= indexPath.row {
            if self.searchResultsCollection[indexPath.row].posterPath == nil {
                cell.imageView.image = nil
            } else {
                loadPosterImage(self.searchResultsCollection[indexPath.row].posterPath!).then { image -> Void in
                    cell.imageView.image = image
                }.error { error in
                    print(error)
                }
            }
        }
        
        cell.label.type = .LeftRight
        cell.label.speed = .Rate(40)
        cell.label.text = searchResultsCollection[indexPath.row].m4kTitle
        
        return cell
    }
    
    private func loadPosterImage(posterPath: String) -> Promise<UIImage> {
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
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        SVProgressHUD.show()
        firstly {
            return ServiceRegistry.loadMovie4KScraperService().isM4kURLMovie(searchResultsCollection[indexPath.row].url)
        }.then { result -> Promise<Void> in
            if result.isMovie {
                return self.loadMovie(indexPath.row, quality: result.quality)
            } else {
                return self.loadSerie(indexPath.row)
            }
        }.error { error -> Void in
            SVProgressHUD.dismiss()
            print(error)
        }
    }
    
    override func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        if let prev = context.previouslyFocusedView as? Poster {
            UIView.animateWithDuration(0.1, animations: { () -> Void in
                prev.label.frame.origin.y -= 27
                prev.label.frame.origin.x += 18
                prev.label.frame.size.width -= 36
                prev.imageView.frame = CGRect(x: 0, y: 0, width: 300, height: 450)
                
                prev.layer.shadowColor = UIColor.clearColor().CGColor
            })
        }
        
        if let next = context.nextFocusedView as? Poster {
            UIView.animateWithDuration(0.1, animations: { () -> Void in
                next.label.frame.origin.y += 27
                next.label.frame.origin.x -= 18
                next.label.frame.size.width += 36
                next.imageView.frame = CGRect(x: -18, y: -27, width: 336, height: 504)
                
                next.layer.shadowColor = UIColor.blackColor().CGColor
                next.layer.shadowOpacity = 1
                next.layer.shadowOffset = CGSizeZero
                next.layer.shadowRadius = 20
            })
        }
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            if searchCriteria != searchText {
                dispatch_promise(on: dispatch_get_main_queue()){
                    self.searchResultsCollection.removeAll()
                    self.collectionView!.reloadData()
                    if self.currentSearchPromise?.promise.pending == true {
                        self.currentSearchPromise?.reject(Movie4kScraperServiceError.CancelRequestFromMovie4k)
                    }
                    }.then { _ -> Void in
                        if searchText != "" {
                            SVProgressHUD.show()
                            self.currentSearchPromise = ServiceRegistry.loadMovie4KScraperService().search(searchText)
                            self.currentSearchPromise!.promise.then { searchResults -> Void in
                                self.searchCriteria = searchText
                                self.searchResultsCollection.removeAll()
                                when(self.loadPoster(searchResults)).then { _ -> Void in
                                    self.collectionView!.reloadData()
                                }
                                }.always {
                                    SVProgressHUD.dismiss()
                                }.error { error -> Void in
                                    print(error)
                            }
                        }
                }
            }
        }
        
    }
    
    private func loadMovie(index: Int, quality: String) -> Promise<Void> {
        let searchText = prepareForSearchOnMovieDBOrg(searchResultsCollection[index].m4kTitle)
        return firstly {
            return ServiceRegistry.loadTheMovieDBorgService().search(searchText)
        }.then { result -> Promise<Void> in
            var movie = Movie.fromJSONDictionary(result)
            movie.m4kQuality = quality
            movie.m4kStartUrl = self.searchResultsCollection[index].url
            return self.loadAllMovieInfo(movie)
        }
    }
    
    private func loadSerie(index: Int) -> Promise<Void> {
        let searchText = prepareForSearchOnMovieDBOrg(searchResultsCollection[index].m4kTitle)
        return firstly {
            return ServiceRegistry.loadTheMovieDBorgService().search(searchText)
        }.then { json -> Promise<JSON> in
            let id = json["id"].intValue
            return ServiceRegistry.loadTheMovieDBorgService().loadSeasonDetailsForTvShowId(id)
        }.then { (json: JSON) -> Promise<Void> in
            var serie = TvShow.fromJSONDictionary(json)
            serie.m4kStartUrl = self.searchResultsCollection[index].url
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
        }
    }
    
    private func loadAllMovieInfo(mov: Movie!) -> Promise<Void> {
        var movie = mov
        
        let movieDetailsPromise = ServiceRegistry.loadTheMovieDBorgService().loadMovieDetails("\(movie.id)")
        let movieCreditsPromise = ServiceRegistry.loadTheMovieDBorgService().loadMovieCredits("\(movie.id)")

        return when(movieDetailsPromise, movieCreditsPromise).then { movieDetails, creditsPromise -> Void in
            
            movie.runtime     = movieDetails.runtimeMin
            movie.genres      = movieDetails.genres
            movie.releaseYear = movieDetails.releaseYear
            movie.cast        = creditsPromise.cast
            movie.director    = creditsPromise.directors
            movie.writer      = creditsPromise.writers
            
            ServiceRegistry.loadApplicationStateService().selectedMovie = movie
            self.performSegueWithIdentifier("showMovieDetails", sender:self)
        }
    }
    
    
    private func loadPoster(searchResults: [(name: String, url: String)]) -> [Promise<Void>] {
        
        var posterPromises = [Promise<Void>]()
        for result in searchResults {
            let text = prepareForSearchOnMovieDBOrg(result.name)
            var search: Search!
            let promise = ServiceRegistry.loadTheMovieDBorgService().search(result.name, m4Kurl: result.url, searchText: text).then { response -> Void in
                if response.data != nil {
                    search = Search.fromJSONDictionary(response.originalM4Ktitle, url: response.m4Kurl, json: response.data!)
                } else {
                    search = Search(m4kTitle: response.originalM4Ktitle, posterPath: nil, url: response.m4Kurl, mediaType: nil)
                }
               self.searchResultsCollection.append(search)
            }
            posterPromises.append(promise)
        }
        return posterPromises
    }
    
    private func prepareForSearchOnMovieDBOrg(text: String) -> String {
        var result = text
        
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