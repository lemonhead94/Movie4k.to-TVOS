import UIKit
import Alamofire
import SVProgressHUD
import PromiseKit

class SeasonViewController: UICollectionViewController {
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    private let tvShow = ServiceRegistry.loadApplicationStateService().selectedSerie
    
    override func viewWillAppear(animated: Bool) {
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
        visualEffectView.frame = view.frame
        visualEffectView.bounds = view.bounds
        visualEffectView.alpha = 0.2
        view.insertSubview(visualEffectView, atIndex: 0)
        
        flowLayout.sectionHeadersPinToVisibleBounds = true
        flowLayout.sectionInset = UIEdgeInsets(top: 40, left: -90, bottom: 0, right: 50)
        self.collectionView?.remembersLastFocusedIndexPath = true
    }
    
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "Header", forIndexPath: indexPath)
        
        return headerView
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if tvShow?.seasons != nil {
            return tvShow!.seasons!.count
        } else {
            return 0
        }
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // Dequeue a cell from the collection view.
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("SeasonPoster", forIndexPath: indexPath) as! SeasonPoster
        cell.userInteractionEnabled = false
        cell.alpha = 0.3
        loadPoster(tvShow!.seasons![indexPath.row].posterPath).then { image in
            cell.imageView.image = image
        }.error { error in
            print(error)
        }
        cell.label.text = "SEASON".localized + " \(self.tvShow!.seasons![indexPath.row].seasonNumber)"
        
        for season in ServiceRegistry.loadApplicationStateService().serieM4kLinks! where season.seasonNumber == self.tvShow!.seasons![indexPath.row].seasonNumber {
            cell.userInteractionEnabled = true
            cell.alpha = 1
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
        ServiceRegistry.loadApplicationStateService().selectedSeason = tvShow!.seasons![indexPath.row]
        ServiceRegistry.loadApplicationStateService().selectedEpisode = tvShow!.seasons![indexPath.row].episodes!.first
        self.parentViewController!.performSegueWithIdentifier("showEpisodesDetails", sender:self)
    }

    override func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        if let prev = context.previouslyFocusedView as? SeasonPoster {
            UIView.animateWithDuration(0.1, animations: { () -> Void in
                
                prev.label.frame.origin.y -= 13
                prev.label.frame.origin.x += 9
                prev.label.frame.size.width -= 17
                prev.imageView.frame = CGRect(x: 0, y: 0, width: 173, height: 260)
                
                prev.layer.shadowColor = UIColor.clearColor().CGColor
            })
        }
        
        if let next = context.nextFocusedView as? SeasonPoster {
            UIView.animateWithDuration(0.1, animations: { () -> Void in
                
                next.label.frame.origin.y += 13
                next.label.frame.origin.x -= 9
                next.label.frame.size.width += 17
                next.imageView.frame = CGRect(x: -9, y: -13, width: 190, height: 286)
                
                next.layer.shadowColor = UIColor.blackColor().CGColor
                next.layer.shadowOpacity = 1
                next.layer.shadowOffset = CGSizeZero
                next.layer.shadowRadius = 20
            })
        }
    }
}