import UIKit
import Cosmos
import SVProgressHUD
import Alamofire
import PromiseKit

class TVShowStreamChooserViewController: UITableViewController {
    
    let model = StreamChooserViewModel()
    
    override func viewDidLoad() {
        ServiceRegistry.loadApplicationStateService().delegate = self
        ServiceRegistry.loadApplicationStateService().selectedProvider = .StreamCloud
        let url = ServiceRegistry.loadApplicationStateService().selectedVideoUrl
        loadAllProviderUrls(url!)
    }
    
    private func loadAllProviderUrls(url: String) {
        SVProgressHUD.show()
        firstly {
            return ServiceRegistry.loadMovie4KScraperService().getTVShowProviderLinkForUrlAndProviders(url, providers: ["Streamclou", "Nowvideo", "Movshare", "CloudTime", "Shared.sx"])
        }.then { providerAndLinks -> Void in
            
            self.model.addLinksForProvider(.StreamCloud, links: self.quickDirtyHack(providerAndLinks["Streamclou"]!))
            self.model.addLinksForProvider(.NowVideo, links: self.quickDirtyHack(providerAndLinks["Nowvideo"]!))
            self.model.addLinksForProvider(.MovShare, links: self.quickDirtyHack(providerAndLinks["Movshare"]!))
            self.model.addLinksForProvider(.CloudTime, links: self.quickDirtyHack(providerAndLinks["CloudTime"]!))
            self.model.addLinksForProvider(.ShareSx, links: self.quickDirtyHack(providerAndLinks["Shared.sx"]!))
            self.tableView.reloadData()
        }.always {
            SVProgressHUD.dismiss()
        }
        
    }
    
    // TODO: write custom model for tvShows
    private func quickDirtyHack(links: [String]) -> [(url: String, uploadDate: String, quality: String)] {
        
        var newFormat = [(url: String, uploadDate: String, quality: String)]()
        for link in links {
            newFormat.append((url: link, uploadDate: "", quality: ""))
        }
        return newFormat
    }
    
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("StreamCell", forIndexPath: indexPath) as! Stream
        switch ServiceRegistry.loadApplicationStateService().selectedProvider {
            case .StreamCloud:
                cell.streamUrl.text = model.urlForProviderAtIndex(.StreamCloud, index: indexPath.row)
                
                if model.streamcloudLinks[indexPath.row].isLoading == false {
                    if model.streamcloudLinks[indexPath.row].resolvedUrl == true {
                        cell.backgroundColor = UIColor(red: 0.32, green: 0.73, blue: 0.32, alpha: 1.0)
                    } else {
                        cell.backgroundColor = UIColor(red: 0.89, green: 0.42, blue: 0.42, alpha: 1.0)
                    }
                }
            case .NowVideo:
                cell.streamUrl.text = model.urlForProviderAtIndex(.NowVideo, index: indexPath.row)
                
                if model.nowvideoLinks[indexPath.row].isLoading == false {
                    if model.nowvideoLinks[indexPath.row].resolvedUrl == true {
                        cell.backgroundColor = UIColor(red: 0.32, green: 0.73, blue: 0.32, alpha: 1.0)
                    } else {
                        cell.backgroundColor = UIColor(red: 0.89, green: 0.42, blue: 0.42, alpha: 1.0)
                    }
                }
            case .MovShare:
                cell.streamUrl.text = model.urlForProviderAtIndex(.MovShare, index: indexPath.row)
                
                if model.movshareLinks[indexPath.row].isLoading == false {
                    if model.movshareLinks[indexPath.row].resolvedUrl == true {
                        cell.backgroundColor = UIColor(red: 0.32, green: 0.73, blue: 0.32, alpha: 1.0)
                    } else {
                        cell.backgroundColor = UIColor(red: 0.89, green: 0.42, blue: 0.42, alpha: 1.0)
                    }
                }
            case .CloudTime:
                cell.streamUrl.text = model.urlForProviderAtIndex(.CloudTime, index: indexPath.row)
                
                if model.cloudtimeLinks[indexPath.row].isLoading == false {
                    if model.cloudtimeLinks[indexPath.row].resolvedUrl == true {
                        cell.backgroundColor = UIColor(red: 0.32, green: 0.73, blue: 0.32, alpha: 1.0)
                    } else {
                        cell.backgroundColor = UIColor(red: 0.89, green: 0.42, blue: 0.42, alpha: 1.0)
                    }
                }
            case .ShareSx:
                cell.streamUrl.text = model.urlForProviderAtIndex(.ShareSx, index: indexPath.row)
                
                if model.sharedsxLinks[indexPath.row].isLoading == false {
                    if model.sharedsxLinks[indexPath.row].resolvedUrl == true {
                        cell.backgroundColor = UIColor(red: 0.32, green: 0.73, blue: 0.32, alpha: 1.0)
                    } else {
                        cell.backgroundColor = UIColor(red: 0.89, green: 0.42, blue: 0.42, alpha: 1.0)
                    }
                }
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch ServiceRegistry.loadApplicationStateService().selectedProvider {
        case .StreamCloud:
            return model.streamCloudLinksCount
        case .NowVideo:
            return model.nowVideoLinksCount
        case .MovShare:
            return model.movShareLinksCount
        case .CloudTime:
            return model.cloudTimeLinksCount
        case .ShareSx:
            return model.sharedSxLinksCount
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch ServiceRegistry.loadApplicationStateService().selectedProvider {
        case .StreamCloud:
            return "StreamCloud"
        case .NowVideo:
            return "NowVideo"
        case .MovShare:
            return "MovShare"
        case .CloudTime:
            return "CloudTime"
        case .ShareSx:
            return "Shared.sx"
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if model.isUrlResolvedForProviderAtIndex(ServiceRegistry.loadApplicationStateService().selectedProvider, index: indexPath.row) {
            ServiceRegistry.loadApplicationStateService().selectedVideoUrl = model.urlForProviderAtIndex(ServiceRegistry.loadApplicationStateService().selectedProvider, index: indexPath.row)
        }
        
        if ServiceRegistry.loadApplicationStateService().selectedVideoUrl != nil {
            SVProgressHUD.show()
            dispatch_promise {
                return PlayerViewController()
                }.thenInBackground { playerViewController -> Void in
                    self.presentViewController(playerViewController, animated: true) {
                        playerViewController.player!.play()
                        ServiceRegistry.loadApplicationStateService().selectedVideoUrl = nil
                    }
                }.always {
                    SVProgressHUD.dismiss()
            }
        }
    }
}

extension TVShowStreamChooserViewController: ProviderChooserDelegate {
    func reloadTableView() {
        self.tableView.reloadData()
    }
}