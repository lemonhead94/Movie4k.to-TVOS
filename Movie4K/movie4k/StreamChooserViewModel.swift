import Foundation
import PromiseKit

class StreamChooserViewModel {
    
    private (set) var streamcloudLinks: [(url: String, uploadDate: NSDate, quality: Double, isLoading: Bool, resolvedUrl: Bool)]!
    private (set) var nowvideoLinks: [(url: String, uploadDate: NSDate, quality: Double, isLoading: Bool, resolvedUrl: Bool)]!
    private (set) var movshareLinks: [(url: String, uploadDate: NSDate, quality: Double, isLoading: Bool, resolvedUrl: Bool)]!
    private (set) var cloudtimeLinks: [(url: String, uploadDate: NSDate, quality: Double, isLoading: Bool, resolvedUrl: Bool)]!
    private (set) var sharedsxLinks: [(url: String, uploadDate: NSDate, quality: Double, isLoading: Bool, resolvedUrl: Bool)]!
    
    var streamCloudLinksCount: Int {
        return streamcloudLinks != nil ? streamcloudLinks.count : 0
    }
    
    var nowVideoLinksCount: Int {
        return nowvideoLinks != nil ? nowvideoLinks.count : 0
    }
    
    var movShareLinksCount: Int {
        return movshareLinks != nil ? movshareLinks.count : 0
    }
    
    var cloudTimeLinksCount: Int {
        return cloudtimeLinks != nil ? cloudtimeLinks.count : 0
    }
    
    var sharedSxLinksCount: Int {
        return sharedsxLinks != nil ? sharedsxLinks.count : 0
    }
    
    func urlForProviderAtIndex(provider: Provider, index: Int) -> String {
        switch provider {
            case .StreamCloud:
                return streamcloudLinks[index].url
            case .NowVideo:
                return nowvideoLinks[index].url
            case .MovShare:
                return movshareLinks[index].url
            case .CloudTime:
                return cloudtimeLinks[index].url
            case .ShareSx:
                return sharedsxLinks[index].url
        }
    }
    
    func dateForProviderAtIndex(provider: Provider, index: Int) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone(name: "GMT")
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        switch provider {
            case .StreamCloud:
                return dateFormatter.stringFromDate(streamcloudLinks[index].uploadDate)
            case .NowVideo:
                return dateFormatter.stringFromDate(nowvideoLinks[index].uploadDate)
            case .MovShare:
                return dateFormatter.stringFromDate(movshareLinks[index].uploadDate)
            case .CloudTime:
                return dateFormatter.stringFromDate(cloudtimeLinks[index].uploadDate)
            case .ShareSx:
                return dateFormatter.stringFromDate(sharedsxLinks[index].uploadDate)
        }
    }
    
    func isUrlResolvedForProviderAtIndex(provider: Provider, index: Int) -> Bool {
        switch provider {
        case .StreamCloud:
            return streamcloudLinks[index].resolvedUrl
        case .NowVideo:
            return nowvideoLinks[index].resolvedUrl
        case .MovShare:
            return movshareLinks[index].resolvedUrl
        case .CloudTime:
            return cloudtimeLinks[index].resolvedUrl
        case .ShareSx:
            return sharedsxLinks[index].resolvedUrl
        }
    }
    
    func qualityForProviderAtIndex(provider: Provider, index: Int) -> Double {
        switch provider {
        case .StreamCloud:
            return streamcloudLinks[index].quality
        case .NowVideo:
            return nowvideoLinks[index].quality
        case .MovShare:
            return movshareLinks[index].quality
        case .CloudTime:
            return cloudtimeLinks[index].quality
        case .ShareSx:
            return sharedsxLinks[index].quality
        }
    }
    
    func addLinksForProvider(provider: Provider, links: [(url: String, uploadDate: String, quality: String)]){
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone(name: "GMT")
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        var result = [(url: String, uploadDate: NSDate, quality: Double)]()
        
        for link in links {
            var date = dateFormatter.dateFromString(link.uploadDate)
            if date == nil {
                date = NSDate(timeIntervalSince1970: 0)
            }
            let quality = getQuality(link.quality)
            result.append((url: link.url, uploadDate: date!, quality: quality))
        }
        
        switch provider {
            case .StreamCloud:
                streamcloudLinks = sortByQualityAndDate(result)
                for (index, streamcloudLink) in streamcloudLinks.enumerate() {
                    startFetchingVideoURL(index, fetchUrl: streamcloudLink.url, provider: .StreamCloud)
                }
            case .NowVideo:
                nowvideoLinks = sortByQualityAndDate(result)
                for (index, nowvideoLink) in nowvideoLinks.enumerate() {
                    startFetchingVideoURL(index, fetchUrl: nowvideoLink.url, provider: .NowVideo)
                }
            case .MovShare:
                movshareLinks = sortByQualityAndDate(result)
                for (index, movshareLink) in movshareLinks.enumerate() {
                    startFetchingVideoURL(index, fetchUrl: movshareLink.url, provider: .MovShare)
                }
            case .CloudTime:
                cloudtimeLinks = sortByQualityAndDate(result)
                for (index, cloudtimeLink) in cloudtimeLinks.enumerate() {
                    startFetchingVideoURL(index, fetchUrl: cloudtimeLink.url, provider: .CloudTime)
                }
            case .ShareSx:
                sharedsxLinks = sortByQualityAndDate(result)
                for (index, sharedsxLink) in sharedsxLinks.enumerate() {
                    startFetchingVideoURL(index, fetchUrl: sharedsxLink.url, provider: .ShareSx)
                }
        }
    }
    
    private func startFetchingVideoURL(index: Int, fetchUrl: String, provider: Provider) {
        
        switch provider {
            case .StreamCloud:
                streamcloudLinks[index].isLoading = true
                ServiceRegistry.loadMovie4KScraperService().getStreamCloudVideo(fetchUrl).then { videoUrl -> Void in
                    if videoUrl != nil {
                        self.streamcloudLinks[index].resolvedUrl = true
                        self.streamcloudLinks[index].url = videoUrl!
                    } else {
                        self.streamcloudLinks[index].resolvedUrl = false
                    }
                }.always {
                    self.streamcloudLinks[index].isLoading = false
                    if ServiceRegistry.loadApplicationStateService().delegate != nil {
                        ServiceRegistry.loadApplicationStateService().delegate.reloadTableView()
                    }
                }.error { error -> Void in
                    self.streamcloudLinks[index].resolvedUrl = false
                    print(error)
                }
            case .NowVideo:
                nowvideoLinks[index].isLoading = true
                ServiceRegistry.loadMovie4KScraperService().getNowvideoVideo(fetchUrl).then { videoUrl -> Void in
                    if videoUrl != nil {
                        self.nowvideoLinks[index].resolvedUrl = true
                        self.nowvideoLinks[index].url = videoUrl!
                    } else {
                        self.nowvideoLinks[index].resolvedUrl = false
                    }
                }.always {
                    self.nowvideoLinks[index].isLoading = false
                    if ServiceRegistry.loadApplicationStateService().delegate != nil {
                        ServiceRegistry.loadApplicationStateService().delegate.reloadTableView()
                    }
                }.error { error -> Void in
                    self.nowvideoLinks[index].resolvedUrl = false
                    print(error)
                }
            
            case .MovShare:
                movshareLinks[index].isLoading = true
                ServiceRegistry.loadMovie4KScraperService().getMovShareVideo(fetchUrl).then { videoUrl -> Void in
                    if videoUrl != nil {
                        self.movshareLinks[index].resolvedUrl = true
                        self.movshareLinks[index].url = videoUrl!
                    } else {
                        self.movshareLinks[index].resolvedUrl = false
                    }
                }.always {
                    self.movshareLinks[index].isLoading = false
                    if ServiceRegistry.loadApplicationStateService().delegate != nil {
                        ServiceRegistry.loadApplicationStateService().delegate.reloadTableView()
                    }
                }.error { error -> Void in
                    self.movshareLinks[index].resolvedUrl = false
                    print(error)
                }
            case .CloudTime:
                cloudtimeLinks[index].isLoading = true
                ServiceRegistry.loadMovie4KScraperService().getCloudTimeVideo(fetchUrl).then { videoUrl -> Void in
                    if videoUrl != nil {
                        self.cloudtimeLinks[index].resolvedUrl = true
                        self.cloudtimeLinks[index].url = videoUrl!
                    } else {
                        self.cloudtimeLinks[index].resolvedUrl = false
                    }
                }.always {
                    self.cloudtimeLinks[index].isLoading = false
                    if ServiceRegistry.loadApplicationStateService().delegate != nil {
                        ServiceRegistry.loadApplicationStateService().delegate.reloadTableView()
                    }
                }.error { error -> Void in
                    self.cloudtimeLinks[index].resolvedUrl = false
                    print(error)
                }
            case .ShareSx:
                sharedsxLinks[index].isLoading = true
                ServiceRegistry.loadMovie4KScraperService().getSharedSxVideo(fetchUrl).then { videoUrl -> Void in
                    if videoUrl != nil {
                        self.sharedsxLinks[index].resolvedUrl = true
                        self.sharedsxLinks[index].url = videoUrl!
                    } else {
                        self.sharedsxLinks[index].resolvedUrl = false
                    }
                }.always {
                    self.sharedsxLinks[index].isLoading = false
                    if ServiceRegistry.loadApplicationStateService().delegate != nil {
                        ServiceRegistry.loadApplicationStateService().delegate.reloadTableView()
                    }
                }.error { error -> Void in
                    self.sharedsxLinks[index].resolvedUrl = false
                    print(error)
                }
        }
    }
    
    private func getQuality(quality: String) -> Double {
        switch quality {
        case "/img/smileys/5.gif":
            return 5.0
        case "/img/smileys/4.gif":
            return 4.0
        case "/img/smileys/3.gif":
            return 3.0
        case "/img/smileys/2.gif":
            return 2.0
        case "/img/smileys/1.gif":
            return 1.0
        case "/img/smileys/0.gif":
            return 0.0
        default:
            return 0.0
        }
    }
    
    private func sortByQualityAndDate(links: [(url: String, uploadDate: NSDate, quality: Double)]) -> [(url: String, uploadDate: NSDate, quality: Double, isLoading: Bool, resolvedUrl: Bool)] {
        let sorted = links.sort({
            if $0.quality > $1.quality {
                return true
            } else if $0.quality == $1.quality {
                return $0.uploadDate.compare($1.uploadDate) == NSComparisonResult.OrderedDescending
            } else {
                return false
            }
        })
        var result = [(url: String, uploadDate: NSDate, quality: Double, isLoading: Bool, resolvedUrl: Bool)]()
        for link in sorted {
            result.append((url: link.url, uploadDate: link.uploadDate, quality: link.quality, isLoading: false, resolvedUrl: false))
        }
        return result
    }
}