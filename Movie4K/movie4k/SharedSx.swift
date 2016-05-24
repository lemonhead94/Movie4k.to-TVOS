import Foundation
import Alamofire
import HTMLReader
import PromiseKit

class SharedSx {
    
    enum SharedSxError: ErrorType {
        case SharedSxFileHasBeenDeleted
        case VideoLinkOnSharedSxNotFound
    }
    
    static func getSharedSxVideo(url: String) -> Promise<(hash: String, expires: String, timestamp: String)> {
        return Promise { fulfill, reject in
            Alamofire.request(.GET, url).responseData { response in
                switch response.result {
                case .Success(let data):
                    let document = HTMLDocument(data: data, contentTypeHeader: "text/html; charset=utf-8")
                    let html = document.nodesMatchingSelector("div > div > form > input")
                    
                    var hash, expires, timestamp : String!
                    
                    for element in html {
                        if let input = element.attributes["name"] {
                            switch input {
                            case "hash":
                                hash = element.attributes["value"]
                            case "expires":
                                expires = element.attributes["value"]
                            case "timestamp":
                                timestamp = element.attributes["value"]
                            default:
                                print("wat?")
                            }
                        }
                    }
                    if hash != nil {
                        fulfill((hash: hash, expires: expires, timestamp: timestamp))
                    } else {
                        reject(SharedSxError.SharedSxFileHasBeenDeleted)
                    }
                    
                case .Failure(let error):
                    reject(error)
                }
            }
        }
    }
    
    static func postRequestSharedSx(url:String, hash: String, expires: String, timestamp: String) -> Promise<String?> {
        
        return Promise { fulfill, reject in
            Alamofire.request(.POST, url, parameters: ["hash": hash, "expires" : expires, "timestamp" : timestamp]).responseData { response in
                switch response.result {
                    case .Success(let data):
                        let document = HTMLDocument(data: data, contentTypeHeader: "text/html; charset=utf-8")
                        let html = document.nodesMatchingSelector("div.stream-content")
                        fulfill(html.first?.attributes["data-url"])
                    case .Failure(let error):
                        reject(error)
                }
            }
        }
    }
    
}