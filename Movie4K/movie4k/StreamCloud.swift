import Foundation
import Alamofire
import HTMLReader
import PromiseKit

class StreamCloud {
    
    enum StreamCloudError: ErrorType {
        case StreamCloudFileHasBeenDeleted
        case VideoLinkOnStreamCloudNotFound
    }
    
    static func getStreamCloudVideo(url: String) -> Promise<(op: String, usr_login: String, id: String, fname: String, referer: String, hash: String, imhuman: String)> {
        return Promise { fulfill, reject in
            Alamofire.request(.GET, url).responseData { response in
                switch response.result {
                case .Success(let data):
                    let document = HTMLDocument(data: data, contentTypeHeader: "text/html; charset=utf-8")
                    let html = document.nodesMatchingSelector("div > form > input")
                    var op, usr_login, id, fname, referer, hash, imhuman : String!
                    
                    for element in html {
                        if let input = element.attributes["name"] {
                            switch input {
                            case "op":
                                op = element.attributes["value"]
                            case "usr_login":
                                usr_login = element.attributes["value"]
                            case "id":
                                id = element.attributes["value"]
                            case "fname":
                                fname = element.attributes["value"]
                            case "referer":
                                referer = element.attributes["value"]
                            case "hash":
                                hash = element.attributes["value"]
                            case "imhuman":
                                imhuman = element.attributes["value"]
                            default:
                                print("wat?")
                            }
                        }
                    }
                    if id != nil {
                        fulfill((op: op, usr_login: usr_login, id: id, fname: fname, referer: referer, hash: hash, imhuman: imhuman))
                    } else {
                        reject(StreamCloudError.StreamCloudFileHasBeenDeleted)
                    }
                    
                case .Failure(let error):
                    reject(error)
                }
            }
        }
    }
    
    static func postRequestStreamCloud(url:String, op: String, usr_login: String, id: String, fname: String, referer: String, hash: String, imhuman: String) -> Promise<(text:String, urlPatternFilter: String)> {
        
        return Promise { fulfill, reject in
            Alamofire.request(.POST, url, parameters: ["op": op, "usr_login" : usr_login, "id" : id, "fname" : fname, "referer" : referer, "hash" : hash, "imhuman" : imhuman]).responseData { response in
                switch response.result {
                    case .Success(let data):
                        let document = HTMLDocument(data: data, contentTypeHeader: "text/html; charset=utf-8")
                        let html = document.nodesMatchingSelector("div#player_code > script:nth-child(4)")
                        if let text = html.first {
                            fulfill((text: text.textContent, urlPatternFilter: "http://(?:www.)?(.+?)/([0-9A-Za-z]+)/video.mp4"))
                        } else {
                            reject(StreamCloudError.VideoLinkOnStreamCloudNotFound)
                        }
                    case .Failure(let error):
                        reject(error)
                }
            }
        }
    }
}