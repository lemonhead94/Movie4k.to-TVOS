import Foundation
import Alamofire
import HTMLReader
import PromiseKit

//Pretty unstable Server wouldn't recommend using it...
class RapidVideoWs {
    
    enum RapidVideoWsError: ErrorType {
        case RapidVideoWsFileHasBeenDeleted
        case VideoLinkOnRapidVideoWsNotFound
    }
    
    static func getRapidVideoWsVideo(url: String) -> Promise<(op: String, usr_login: String, id: String, fname: String, referer: String, hash: String, imhuman: String)> {
        return Promise { fulfill, reject in
            Alamofire.request(.GET, url).responseData { response in
                switch response.result {
                case .Success(let data):
                    let document = HTMLDocument(data: data, contentTypeHeader: "text/html; charset=utf-8")
                    let html = document.nodesMatchingSelector("center > form > input")
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
                        reject(RapidVideoWsError.RapidVideoWsFileHasBeenDeleted)
                    }
                case .Failure(let error):
                    reject(error)
                }
            }
        }
    }
    
    static func postRequestRapidVideo_ws(url:String, op: String, usr_login: String, id: String, fname: String, referer: String, hash: String, imhuman: String) -> Promise<(ipAddress: String?, obfusication: String, urlPatternFilter: String)> {
        
        return Promise { fulfill, reject in
            Alamofire.request(.POST, url, parameters: ["op": op, "usr_login" : usr_login, "id" : id, "fname" : fname, "referer" : referer, "hash" : hash, "imhuman" : imhuman]).responseData { response in
                switch response.result {
                case .Success(let data):
                    let document = HTMLDocument(data: data, contentTypeHeader: "text/html; charset=utf-8")
                    let html = document.nodesMatchingSelector("span#vplayer > img")
                    let htmlPage: String = String(data: data, encoding: NSUTF8StringEncoding)!
                    
                    var ipAddress: String?
                    if let src = html.first?.attributes["src"] {
                        ipAddress = "http://" + src.componentsSeparatedByString("/")[2] + "/"
                    }
                    
                    fulfill((ipAddress: ipAddress, obfusication: htmlPage, urlPatternFilter: "(?<=\\|mp4\\|).*?(?=\\|file\\|)"))
                case .Failure(let error):
                    reject(error)
                }
            }
        }
    }
}