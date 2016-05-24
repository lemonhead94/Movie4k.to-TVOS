import Foundation
import Alamofire
import HTMLReader
import PromiseKit

// is flash so need something to convert to mp4
class Promtfile {
    
    enum PromtfileError: ErrorType {
        case PromtfileFileHasBeenDeleted
    }
    
    static func getPromtfileVideo(url: String) -> Promise<String> {
        return Promise { fulfill, reject in
            Alamofire.request(.GET, url).responseData { response in
                switch response.result {
                case .Success(let data):
                    let document = HTMLDocument(data: data, contentTypeHeader: "text/html; charset=utf-8")
                    let html = document.nodesMatchingSelector("div#confirmbox > form > input")
                    var chash = ""
                    for element in html {
                        chash = element.attributes["value"] ?? ""
                    }
                    if (chash != "") {
                        fulfill(chash)
                    } else {
                        reject(PromtfileError.PromtfileFileHasBeenDeleted)
                    }
                    
                case .Failure(let error):
                    reject(error)
                }
            }
        }
    }
    
    static func postRequestPromtfile(url:String, chash: String) -> Promise<(text:String, urlPatternFilter: String)> {
        
        return Promise { fulfill, reject in
            Alamofire.request(.POST, url, parameters: ["chash": chash]).responseData { response in
                switch response.result {
                case .Success(let data):
                    let document = HTMLDocument(data: data, contentTypeHeader: "text/html; charset=utf-8")
                    let html = document.nodesMatchingSelector("script")
                    fulfill((text: html[18].textContent, urlPatternFilter: "url\\s*:\\s*\'(.+?)\'"))
                case .Failure(let error):
                    reject(error)
                }
            }
        }
    }

}