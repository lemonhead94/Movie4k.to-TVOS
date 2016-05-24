import Foundation
import HTMLReader
import Alamofire
import PromiseKit

typealias SearchPromise = (promise: Promise<[(name: String, url: String)]>, fulfill: ([(name: String, url: String)]) -> Void, reject: (ErrorType) -> Void)
typealias TypeAheadPromise = (promise: Promise<[String]>, fulfill: ([String]) -> Void, reject: (ErrorType) -> Void)

enum Movie4kScraperServiceError: ErrorType {
    case NothingFoundOnMovie4k
    case CancelRequestFromMovie4k
}

enum Language: String {
    case German = "de"
    case English = "en"
}

class Movie4KScraperService {
    
    private let mainsite = "http://movie4k.to/"
    private let cinemaUrl = "index.php"
    private let featuredTVShows = "featuredtvshows.html"
    private let searchUrl = "movies.php?list=search&search="
    private let typeahead = "searchAutoCompleteNew.php?search="
    private var languageQuery = "?lang=en"
    private var alamoFireManager: Alamofire.Manager?
    
    var currentLanguage: Language = .English {
        didSet {
            switch currentLanguage {
                case .English:
                    self.languageQuery = "?lang=en"
                case .German:
                    self.languageQuery = "?lang=de"
            }
        }
    }
    
    init(manager: Alamofire.Manager, language: Language) {
        self.alamoFireManager = manager
        self.currentLanguage = language
        switch language {
            case .English:
                self.languageQuery = "?lang=en"
            case .German:
                self.languageQuery = "?lang=de"
        }
    }
    
    func search(searchText: String) -> SearchPromise {
        let baseURL: String = (mainsite + searchUrl + searchText).stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        
        let mutableUrlRequest = NSMutableURLRequest(URL: NSURL(string: baseURL)!)
        mutableUrlRequest.HTTPMethod = "GET"
        switch currentLanguage {
            case .German:
                mutableUrlRequest.setValue("onlylanguage=de", forHTTPHeaderField: "Cookie")
            case .English:
                mutableUrlRequest.setValue("onlylanguage=en", forHTTPHeaderField: "Cookie")
        }
        
        let searchPromise = Promise<[(name: String, url: String)]>.pendingPromise()
        alamoFireManager!.request(mutableUrlRequest).responseData { response in
            switch response.result {
                case .Success(let data):
                    var search = [(name: String, url: String)]()
                    let document = HTMLDocument(data: data, contentTypeHeader: "text/html; charset=utf-8")
                    let html = document.nodesMatchingSelector("div > table > tbody > tr > td > a")
                    for element in html {
                        // item matching searchText and url
                        if let link: String = element.attributes["href"] {
                            if !link.containsString("thepiratebay") {
                                search.append((name: element.textContent, url: self.mainsite + link))
                            }
                        }
                    }
                    if !searchPromise.promise.resolved {
                        if search.count > 0 {
                            searchPromise.fulfill(search)
                        } else {
                            searchPromise.reject(Movie4kScraperServiceError.NothingFoundOnMovie4k)
                        }
                    }
                case .Failure(let error):
                    searchPromise.reject(error)
            }
        }
        
        return searchPromise
    }
    
    func searchTypeahead(searchText: String) -> TypeAheadPromise {
        let baseURL: String = (mainsite + typeahead + searchText).stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        let typeAheadPromise = Promise<[String]>.pendingPromise()
        alamoFireManager!.request(.GET, baseURL).responseData { response in
            switch response.result {
            case .Success(let data):
                let document = HTMLDocument(data: data, contentTypeHeader: "text/html; charset=utf-8")
                let html = document.nodesMatchingSelector("table > tbody > tr > td > a")
                var search = [String]()
                for element in html {
                    search.append(element.textContent)
                }
                typeAheadPromise.fulfill(search)
            case .Failure(let error):
                typeAheadPromise.reject(error)
            }
        }
        return typeAheadPromise
    }
    
    
    
    func isM4kURLMovie(url: String) -> Promise<(isMovie: Bool, quality: String)> {
        return Promise { fulfill, reject in
            alamoFireManager!.request(.GET, url).responseData { response in
                switch response.result {
                case .Success(let data):
                    let document = HTMLDocument(data: data, contentTypeHeader: "text/html; charset=utf-8")
                    let checkForForm = document.nodesMatchingSelector("div#menu > table > tbody > tr > td > form")
                    let query = document.nodesMatchingSelector("div#content > div#maincontent5 > div > div > span > span > img")
                    if checkForForm.count > 0 {
                        fulfill((isMovie: false, quality: ""))
                    } else {
                        let quality = query.first?.attributes["src"] ?? ""
                        fulfill((isMovie: true, quality: quality))
                    }
                    
                case .Failure(let error):
                    reject(error)
                }
            }
        }
    }
    
    func getCinemaMovies() -> Promise<[(name: String, url: String, quality: String)]> {
        
        let baseUrl: String = mainsite + cinemaUrl + languageQuery
        
        return Promise { fulfill, reject in
            
            alamoFireManager!.request(.GET, baseUrl).responseData { response in
                switch response.result {
                    case .Success(let data):
                        var cinemaMovies = [(name: String, url: String, quality: String)]()
                        let document = HTMLDocument(data: data, contentTypeHeader: "text/html; charset=utf-8")
                        let html = document.nodesMatchingSelector("div > div:nth-child(3) > h2:nth-child(1) > a:nth-child(1) > font:nth-child(1)")
                        for element in html {
                            let container = element.parentElement?.parentElement?.parentElement
                            let queries = container?.nodesMatchingSelector("div > table#tablemoviesindex > tbody > tr > td:nth-child(2) > span > img")
                            
                            let title = element.childAtIndex(0).textContent
                            if let url = element.parentElement!.attributes["href"] {
                                let quality = queries!.first!.attributes["src"]!
                                cinemaMovies.append((title, self.mainsite + url, quality))
                            }
                        }
                        if cinemaMovies.count > 0 {
                           fulfill(cinemaMovies)
                        } else {
                            reject(Movie4kScraperServiceError.NothingFoundOnMovie4k)
                        }
                    case .Failure(let error):
                        reject(error)
                }
            }
        }
    }
    
    func getFeaturedTVShows() -> Promise<[(name: String, url: String)]> {
        
        let baseUrl: String = mainsite + featuredTVShows + languageQuery
        return Promise { fulfill, reject in
            alamoFireManager!.request(.GET, baseUrl).responseData { response in
                switch response.result {
                    case .Success(let data):
                        var featuredTVShows = [(name: String, url: String)]()
                        let document = HTMLDocument(data: data, contentTypeHeader: "text/html; charset=utf-8")
                        let html = document.nodesMatchingSelector("div#maincontenttvshow > div > h2:nth-child(1) > a:nth-child(1) > font:nth-child(1)")
                        for element in html {
                            let title = element.textContent
                            if let url = element.parentElement!.attributes["href"] {
                                featuredTVShows.append((title, self.mainsite + url))
                            }
                        }
                        if featuredTVShows.count > 0 {
                            fulfill(featuredTVShows)
                        } else {
                            reject(Movie4kScraperServiceError.NothingFoundOnMovie4k)
                        }
                    case .Failure(let error):
                        reject(error)
                }
            }
        }
    }
    
    func getSerieLinks(url: String) -> Promise<[(seasonNumber: Int, episodes: [(episodeNumber: Int, url: String)])]> {
        return Promise { fulfill, reject in
            alamoFireManager!.request(.GET, url).responseData { response in
                switch response.result {
                    case .Success(let data):
                        var seasonAndLinks = [(seasonNumber: Int, episodes: [(episodeNumber: Int, url: String)])]()
                        let document = HTMLDocument(data: data, contentTypeHeader: "text/html; charset=utf-8")
                        let seasons = document.nodesMatchingSelector("div#menu > table > tbody > tr > td > form > select > option")
                        for (_, season) in seasons.enumerate() {
                            var seasonIndex: Int!
                            switch self.currentLanguage {
                                case .German:
                                    seasonIndex = Int(season.textContent.stringByReplacingOccurrencesOfString("Staffel ", withString: ""))
                                case .English:
                                    seasonIndex = Int(season.textContent.stringByReplacingOccurrencesOfString("Season ", withString: ""))
                            }
                            let episodes = document.nodesMatchingSelector("div#episodediv\(seasonIndex) > form > select > option")
                            var episodeLinks = [(episodeNumber: Int, url: String)]()
                            for episode in episodes {
                                if let link = episode.attributes["value"] {
                                    if let episodeNumber = Int(episode.textContent.stringByReplacingOccurrencesOfString("Episode ", withString: "")) {
                                        episodeLinks.append((episodeNumber, self.mainsite + link))
                                    }
                                }
                            }
                            seasonAndLinks.append((seasonNumber: seasonIndex, episodes: episodeLinks))
                        }
                        if seasonAndLinks.count > 0 {
                            fulfill(seasonAndLinks)
                        } else {
                            reject(Movie4kScraperServiceError.NothingFoundOnMovie4k)
                        }
                    case .Failure(let error):
                        reject(error)
                }
            }
        }
    }
    
    func getTVShowProviderLinkForUrlAndProviders(url: String, providers: [String]) -> Promise<[String : [String]]> {
        return Promise { fulfill, reject in
            alamoFireManager!.request(.GET, url).responseData { response in
                switch response.result {
                case .Success(let data):
                    var providerAndLinks = [String : [String]]()
                    let document = HTMLDocument(data: data, contentTypeHeader: "text/html; charset=utf-8")
                    let allJavascriptBasedLinks = document.nodesMatchingSelector("div#menu > table > tbody > script")
                    let allHTMLBasedLinks = document.nodesMatchingSelector("tr#tablemoviesindex2 > td:nth-child(2) > a:nth-child(1)")
                    let currentSelectedLink = document.nodesMatchingSelector("div#content > div#maincontent5 > div > a")
                    var providerPromises = [Promise<Void>]()
                    
                    for provider in providers {
                        providerAndLinks[provider] = [String]()
                        for element in allJavascriptBasedLinks where element.textContent.rangeOfString(provider) != nil {
                            let urls = self.matchesForRegexInText(element.textContent, pattern: "href=\\\\\\\"([^\"]*)\\\\\\\">")
                            for (_, someUrl) in urls.enumerate() {
                                let link = someUrl.componentsSeparatedByString("\"")[1].componentsSeparatedByString("\\")[0]
                                let promise = self.getVideoLinkFromSite(link).then { providerUrl -> Void in
                                    var providerLinks: [String] = providerAndLinks[provider]!
                                    providerLinks.append(providerUrl)
                                    providerAndLinks[provider] = providerLinks
                                }
                                providerPromises.append(promise)
                            }
                        }
                        for link in currentSelectedLink {
                            var providerLinks: [String] = providerAndLinks[provider]!
                            if self.matchProviderUrl(provider, url: link.attributes["href"]!) {
                                providerLinks.append((link.attributes["href"]!))
                                providerAndLinks[provider] = providerLinks
                            }
                        }
                        
                        for element in allHTMLBasedLinks where element.parentElement?.parentElement?.textContent.rangeOfString(provider) != nil {
                            if let link = element.attributes["href"] {
                                let promise = self.getVideoLinkFromSite(link).then { providerUrl -> Void in
                                    var providerLinks: [String] = providerAndLinks[provider]!
                                    providerLinks.append(providerUrl)
                                    providerAndLinks[provider] = providerLinks
                                }
                                providerPromises.append(promise)
                            }
                        }
                    }
                    when(providerPromises).then { _ -> Void in
                        fulfill(providerAndLinks)
                    }.error { error -> Void in
                        reject(error)
                    }
                case .Failure(let error):
                    reject(error)
                }
            }
        }
    }
    
    func getProviderLinksForUrlAndProviders(url: String, providers: [String]) -> Promise<[String : [(url: String, uploadDate: String, quality: String)]]> {
        return Promise { fulfill, reject in
            alamoFireManager!.request(.GET, url).responseData { response in
                switch response.result {
                    case .Success(let data):
                        var providerAndLinks = [String : [(url: String, uploadDate: String, quality: String)]]()
                        let document = HTMLDocument(data: data, contentTypeHeader: "text/html; charset=utf-8")
                        let allJavascriptBasedLinks = document.nodesMatchingSelector("div#menu > table > tbody > script")
                        let allHTMLBasedLinks = document.nodesMatchingSelector("tr#tablemoviesindex2 > td:nth-child(2) > a:nth-child(1)")
                        let currentSelectedLink = document.nodesMatchingSelector("div#content > div#maincontent5 > div > a")
                        var providerPromises = [Promise<Void>]()
                        
                        for provider in providers {
                            providerAndLinks[provider] = [(url: String, uploadDate: String, quality: String)]()
                            for element in allJavascriptBasedLinks where element.textContent.rangeOfString(provider) != nil {
                                let urls = self.matchesForRegexInText(element.textContent, pattern: "href=\\\\\\\"([^\"]*)\\\\\\\">[0-9]{2}.[0-9]{2}.[0-9]{4}")
                                let qualities = self.matchesForRegexInText(element.textContent, pattern: "<img style=\\\\\"vertical-align: top;\\\\\" src=\\\\\"([^\"]*)")
                                for (index, someUrl) in urls.enumerate() {
                                    let link = someUrl.componentsSeparatedByString("\"")[1].componentsSeparatedByString("\\")[0]
                                    let uploadDate = someUrl.componentsSeparatedByString("\">").last ?? ""
                                    let quality = qualities[index].componentsSeparatedByString("\"")[3].componentsSeparatedByString("\\")[0]

                                    let promise = self.getVideoLinkFromSite(link).then { providerUrl -> Void in
                                        var providerLinks: [(url: String, uploadDate: String, quality: String)] = providerAndLinks[provider]!
                                        providerLinks.append((providerUrl, uploadDate, quality))
                                        providerAndLinks[provider] = providerLinks
                                    }
                                    providerPromises.append(promise)
                                }
                            }
                            for link in currentSelectedLink {
                                var providerLinks: [(url: String, uploadDate: String, quality: String)] = providerAndLinks[provider]!
                                if self.matchProviderUrl(provider, url: link.attributes["href"]!) {
                                    providerLinks.append((link.attributes["href"]!, "", ""))
                                    providerAndLinks[provider] = providerLinks
                                }
                            }
                            
                            for element in allHTMLBasedLinks where element.parentElement?.parentElement?.textContent.rangeOfString(provider) != nil {
                                let uploadDate = element.parentElement?.parentElement?.nodesMatchingSelector("a").first?.textContent.componentsSeparatedByString(" ")[0] ?? ""
                                let quality = element.parentElement?.nodesMatchingSelector("img").first?.attributes["src"] ?? ""
                                if let link = element.attributes["href"] {
                                    let promise = self.getVideoLinkFromSite(link).then { providerUrl -> Void in
                                        var providerLinks: [(url: String, uploadDate: String, quality: String)] = providerAndLinks[provider]!
                                        providerLinks.append((providerUrl, uploadDate, quality))
                                        providerAndLinks[provider] = providerLinks
                                    }
                                    providerPromises.append(promise)
                                }
                            }
                        }
                        when(providerPromises).then { _ -> Void in
                            fulfill(providerAndLinks)
                        }.error { error -> Void in
                            reject(error)
                        }
                    case .Failure(let error):
                        reject(error)
                }
            }
        }
    }
    
    private func matchProviderUrl(provider: String, url: String) -> Bool {
        
        if provider.lowercaseString.containsString("streamclou") {
            return url.containsString("streamcloud")
        } else if provider.lowercaseString.containsString("nowvideo") {
            return url.containsString("nowvideo")
        } else if provider.lowercaseString.containsString("movshare") {
            return url.containsString("wholecloud") || url.containsString("movshare")
        } else if provider.lowercaseString.containsString("cloudtime") {
            return url.containsString("cloudtime")
        } else if provider.lowercaseString.containsString("shared") {
            return url.containsString("shared")
        }
        return false
    }
    
    private func getVideoLinkFromSite(path: String) -> Promise<String> {
        let baseUrl: String = mainsite + path
        return Promise { fulfill, reject in
            alamoFireManager!.request(.GET, baseUrl).responseData { response in
                switch response.result {
                case .Success(let data):
                    let document = HTMLDocument(data: data, contentTypeHeader: "text/html; charset=utf-8")
                    let html = document.nodesMatchingSelector("div > div > div > a:nth-child(8) > img:nth-child(1)")
                    for element in html {
                        if let url = element.parentElement?.attributes["href"] {
                            fulfill(url)
                        } else {
                            reject(Movie4kScraperServiceError.NothingFoundOnMovie4k)
                        }
                    }
                case .Failure(let error):
                    reject(error)
                }
            }
        }
    }
    
    func getStreamCloudVideo(url: String) -> Promise<String?> {
        return firstly {
            StreamCloud.getStreamCloudVideo(url)
        }.then { op, usr_login, id, fname, referer, hash, imhuman -> Promise<(text:String, urlPatternFilter: String)> in
            return after(11.0).then { _ -> Promise<(text:String, urlPatternFilter: String)> in
                return StreamCloud.postRequestStreamCloud(url, op: op, usr_login: usr_login, id: id, fname: fname, referer: referer, hash: hash, imhuman: imhuman)
            }
        }.then { text, urlPatternFilter -> String? in
            return self.matchesForRegexInText(text, pattern: urlPatternFilter).first
        }
    }

    func getNowvideoVideo(url: String) -> Promise<String?> {
        return Nowvideo.getNowVideoVideo(url)
    }
    
    func getMovShareVideo(url: String) -> Promise<String?> {
        return Movshare.getMovshareVideo(url)
    }
    
    func getCloudTimeVideo(url: String) -> Promise<String?> {
        return CloudTime.getCloudTimeVideo(url)
    }
    
    func getSharedSxVideo(url: String) -> Promise<String?> {
        return firstly {
            SharedSx.getSharedSxVideo(url)
        }.then { hash, expires, timestamp -> Promise<String?> in
            return after(11.0).then { _ -> Promise<String?> in
                return SharedSx.postRequestSharedSx(url, hash: hash, expires: expires, timestamp: timestamp)
            }
        }
    }
    
    func getRapidVideoWsVideo(url: String) -> Promise<String?> {
        return firstly {
            RapidVideoWs.getRapidVideoWsVideo(url)
        }.then { op, usr_login, id, fname, referer, hash, imhuman -> Promise<(ipAddress: String?, obfusication: String, urlPatternFilter: String)> in
            return after(11.0).then { _ -> Promise<(ipAddress: String?, obfusication: String, urlPatternFilter: String)> in
                return RapidVideoWs.postRequestRapidVideo_ws(url, op: op, usr_login: usr_login, id: id, fname: fname, referer: referer, hash: hash, imhuman: imhuman)
            }
        }.then { videoLink, text, urlPatternFilter -> String? in
            return "\(videoLink)\(self.matchesForRegexInText(text, pattern: urlPatternFilter).first)" + "/v.mp4"
        }
    }
    
    func getPromtfileVideo(url: String) -> Promise<String?> {
        return firstly {
            Promtfile.getPromtfileVideo(url)
        }.then { chash -> Promise<(text:String, urlPatternFilter: String)> in
            return Promtfile.postRequestPromtfile(url, chash: chash)
        }.then { text, urlPatternFilter -> String? in
            return self.matchesForRegexInText(text, pattern: urlPatternFilter).first
        }
    }
    
    private func matchesForRegexInText(text: String, pattern: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsString = text as NSString
            let results = regex.matchesInString(text, options: [], range: NSMakeRange(0, nsString.length))
            return results.map { nsString.substringWithRange($0.range)}
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}


