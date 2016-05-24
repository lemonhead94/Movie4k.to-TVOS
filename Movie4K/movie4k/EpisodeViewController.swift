import UIKit
import Alamofire
import PromiseKit

class EpisodeViewController: UICollectionViewController {
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    let season = ServiceRegistry.loadApplicationStateService().selectedSeason
    
    weak var episodePreviewViewControllerDelegate: EpisodePreviewViewController?
    var lastSelectedEpisodeCellIndexPath: NSIndexPath?
    
    override func viewWillAppear(animated: Bool) {
        
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
        visualEffectView.frame = view.frame
        visualEffectView.bounds = view.bounds
        visualEffectView.alpha = 0.2
        view.insertSubview(visualEffectView, atIndex: 0)
    
        flowLayout.sectionHeadersPinToVisibleBounds = true
        flowLayout.sectionInset = UIEdgeInsets(top: 50, left: -120, bottom: 0, right: 50)
        self.collectionView?.remembersLastFocusedIndexPath = true
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "Header", forIndexPath: indexPath)
        
        return headerView
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if season?.episodes != nil {
            // inital selection position
            lastSelectedEpisodeCellIndexPath = NSIndexPath(forRow: 0, inSection: 0)
            return season!.episodes!.count
        } else {
            return 0
        }
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // Dequeue a cell from the collection view.
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("EpisodePoster", forIndexPath: indexPath) as! EpisodePoster
        cell.userInteractionEnabled = false
        cell.alpha = 0.3
        cell.imageView.image = nil
        
        loadPoster(season!.episodes![indexPath.row].stillPath).then { image in
            cell.imageView.image = image
            }.error { error in
                print(error)
        }
        cell.episodeName.type = .LeftRight
        cell.episodeName.speed = .Rate(40)
        cell.episodeName.text = "\(indexPath.row + 1). " + season!.episodes![indexPath.row].name
        let seasonNumber = String(format: "%02d", season!.seasonNumber)
        let episodeNumber = String(format: "%02d", season!.episodes![indexPath.row].episodeNumber)
        cell.currentSeasonAnEpisode.text = "S" + seasonNumber + " • E" + episodeNumber
        
        for m4kSeason in ServiceRegistry.loadApplicationStateService().serieM4kLinks! where m4kSeason.seasonNumber == season!.seasonNumber {
            for m4kEpisode in m4kSeason.episodes where m4kEpisode.episodeNumber == season!.episodes![indexPath.row].episodeNumber {
                cell.userInteractionEnabled = true
                cell.alpha = 1
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
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        episodePreviewViewControllerDelegate?.performSegueWithIdentifier("showStreamChooserViewController", sender: episodePreviewViewControllerDelegate)
    }
    
    override func shouldUpdateFocusInContext(context: UIFocusUpdateContext) -> Bool {
        
        if let cell = context.nextFocusedView as? EpisodePoster {
            let indexPath = collectionView!.indexPathForCell(cell)
            
            episodePreviewViewControllerDelegate?.updateUIForEpisode(indexPath!.row)
            ServiceRegistry.loadApplicationStateService().selectedEpisode = season?.episodes![indexPath!.row]
        }
        
        return true
    }
    
    override func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        
        if let prev = context.previouslyFocusedView as? EpisodePoster {
            UIView.animateWithDuration(0.1, animations: { () -> Void in
                
                prev.episodeName.frame.origin.y -= 10
                prev.episodeName.frame.origin.x += 18
                prev.episodeName.frame.size.width -= 17
                prev.currentSeasonAnEpisode.frame.origin.y -= 10
                prev.currentSeasonAnEpisode.frame.origin.x += 18
                prev.currentSeasonAnEpisode.frame.size.width -= 36
                prev.imageView.frame = CGRect(x: 0, y: 0, width: 356, height: 200)
                
                prev.layer.shadowColor = UIColor.clearColor().CGColor
            })
        }
        
        if let next = context.nextFocusedView as? EpisodePoster {
            UIView.animateWithDuration(0.1, animations: { () -> Void in
                
                next.episodeName.frame.origin.y += 10
                next.episodeName.frame.origin.x -= 18
                next.episodeName.frame.size.width += 17
                next.currentSeasonAnEpisode.frame.origin.y += 10
                next.currentSeasonAnEpisode.frame.origin.x -= 18
                next.currentSeasonAnEpisode.frame.size.width += 36
                next.imageView.frame = CGRect(x: -18, y: -10, width: 392, height: 220)
                
                next.layer.shadowColor = UIColor.blackColor().CGColor
                next.layer.shadowOpacity = 1
                next.layer.shadowOffset = CGSizeZero
                next.layer.shadowRadius = 40
            })
        }
    }
}