//
//  NSError+MB.swift
//  MegaBus
//
//  Created by Javier Fuchs on 9/21/16.
//  Copyright © 2016 Fuchs. All rights reserved.
//

import Foundation

extension NSError
{
    struct Constants {
        enum ErrorCode: Int {
            case ErrorCodeNone = 100
            case ErrorCodeContent
            case ErrorCodeOffline
            case ErrorCodePath
            case ErrorCodeRequest
            case ErrorCodeResponse
            case ErrorCodeFetch
        }
        
        struct error {
            static let content  = error(domain: MBServiceManager.appName, code: ErrorCode.ErrorCodeContent.rawValue,
                                        info: [NSLocalizedDescriptionKey:"Error in content"])
            static let fetch    = error(domain: MBServiceManager.appName, code: ErrorCode.ErrorCodeFetch.rawValue,
                                        info: [NSLocalizedDescriptionKey:"Error in Core Data Fetch"])
            static let offline  = error(domain: MBServiceManager.appName, code: ErrorCode.ErrorCodeOffline.rawValue,
                                        info: [NSLocalizedDescriptionKey:"The device is currently offline"])
            static let path     = error(domain: MBServiceManager.appName, code: ErrorCode.ErrorCodePath.rawValue,
                                        info: [NSLocalizedDescriptionKey:"Cannot create path"])
            static let request  = error(domain: MBServiceManager.appName, code: ErrorCode.ErrorCodeRequest.rawValue,
                                        info: [NSLocalizedDescriptionKey:"Cannot create request"])
            static let response = error(domain: MBServiceManager.appName, code: ErrorCode.ErrorCodeResponse.rawValue,
                                        info: [NSLocalizedDescriptionKey:"Error in response"])
            let domain: String
            let code: Int
            let info: [String:String]
        }
    }
    
    /// create a offline NSError
    public class func offlineError() -> NSError {
        let error = Constants.error.offline
        return NSError.init(domain: error.domain, code: error.code, userInfo: error.info)
    }
    
    /// create a request NSError
    public class func requestError() -> NSError {
        let error = Constants.error.request
        return NSError.init(domain: error.domain, code: error.code, userInfo: error.info)
    }
    
    /// create a path NSError
    public class func pathError() -> NSError {
        let error = Constants.error.path
        return NSError.init(domain: error.domain, code: error.code, userInfo: error.info)
    }
    
    /// create a content NSError
    public class func contentError() -> NSError {
        let error = Constants.error.content
        return NSError.init(domain: error.domain, code: error.code, userInfo: error.info)
    }
    
    /// create a response NSError
    public class func responseError(code: Int?) -> NSError {
        let error = Constants.error.response
        if let errorCode = code {
            return NSError.init(domain: error.domain, code: errorCode, userInfo: error.info)
        }
        else {
            return NSError.init(domain: error.domain, code: error.code, userInfo: error.info)
        }
    }
    
    /// create a fetch error
    public class func fetchError() -> NSError {
        let error = Constants.error.content
        return NSError.init(domain: error.domain, code: error.code, userInfo: error.info)
    }
    
}
    