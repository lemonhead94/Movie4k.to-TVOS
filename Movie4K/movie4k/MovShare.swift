import Foundation
import Alamofire
import HTMLReader
import PromiseKit

class Movshare {
    static func getMovshareVideo(url: String) -> Promise<String?> {
        let baseUrl = "http://www.movshare.net/mobile/video.php?id=" + url.componentsSeparatedByString("/").last!
        
        return Promise { fulfill, reject in
            Alamofire.request(.GET, baseUrl).responseData { response in
                switch response.result {
                case .Success(let data):
                    let document = HTMLDocument(data: data, contentTypeHeader: "text/html; charset=utf-8")
                    let html = document.nodesMatchingSelector("video#player > source:nth-child(1)")
                    fulfill(html.first?.attributes["src"])
                case .Failure(let error):
                    reject(error)
                }
            }
        }
    }
    
}

