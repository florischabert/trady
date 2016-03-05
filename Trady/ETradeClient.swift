//
//  ETradeClient.swift
//  Trady
//
//  Created by Floris Chabert on 2/5/16.
//  Copyright © 2016 Floris Chabert. All rights reserved.
//

import UIKit
import SafariServices

extension String {
    func stringByAddingPercentEncodingForURLQueryValue() -> String {
        let allowedCharacters = NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")

        return self.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters)!
    }

    func hmacsha1(key: String) -> String {
        let dataToDigest = self.dataUsingEncoding(NSUTF8StringEncoding)
        let secretKey = key.dataUsingEncoding(NSUTF8StringEncoding)

        let digestLength = Int(CC_SHA1_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLength)

        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), secretKey!.bytes, secretKey!.length, dataToDigest!.bytes, dataToDigest!.length, result)

        let data = NSData(bytes: result, length: digestLength)
        return data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
    }

    private func stringFromResult(result: UnsafeMutablePointer<CUnsignedChar>, length: Int) -> String {
        let hash = NSMutableString()
        for i in 0..<length {
            hash.appendFormat("%02x", result[i])
        }
        return String(hash)
    }

    func dictionaryFromHttpParameters() -> [String: String] {
        var parameterDictionary = [String: String]()

        let pairs = self.componentsSeparatedByString("&")
        if pairs.count > 0 {
            for pair: String in pairs {
                let keyValue = pair.characters.split("=", maxSplit: 1, allowEmptySlices: false)
                if keyValue.count > 0 {
                    parameterDictionary.updateValue(String(keyValue[1]), forKey: String(keyValue[0]))
                }
            }
        }
        return parameterDictionary
    }

}

extension Dictionary {
    func stringFromHttpParameters() -> String {
        let parameterArray = self.map { (key, value) -> String in
            return "\(key)=\(value)"
        }

        return parameterArray.sort().joinWithSeparator("&")
    }
}

class OAuth {
    let consumerKey: String
    let consumerSecret: String

    let requestTokenUrl: String
    let authorizeUrl: String
    let accessTokenUrl: String
    let renewAccessTokenUrl: String

    var token: String?
    var tokenSecret: String?

    var safari: SFSafariViewController?

    var authorizeCompletionHandler: ((Void) -> Void)?

    enum Method {
        case GET, POST
    }

    init(consumerKey: String, consumerSecret: String,
        requestTokenUrl: String, authorizeUrl: String, accessTokenUrl: String, renewAccessTokenUrl: String) {
            self.consumerKey = consumerKey
            self.consumerSecret = consumerSecret
            self.requestTokenUrl = requestTokenUrl
            self.authorizeUrl = authorizeUrl
            self.accessTokenUrl = accessTokenUrl
            self.renewAccessTokenUrl = renewAccessTokenUrl
    }

    private func openAuthorizeView() {
        let urlString = "\(self.authorizeUrl)?key=\(self.consumerKey)&token=\(self.token!)"

        safari = SFSafariViewController(URL: NSURL(string: urlString)!)
        (UIApplication.sharedApplication().delegate as! AppDelegate).window!.rootViewController!.presentViewController(safari!, animated: true, completion: nil)
    }

    private func authorize(completionHandler: (Void) -> Void) {

        self.token = nil
        self.tokenSecret = nil

        self.authorizeCompletionHandler = completionHandler

        let parameters: [String: String] = [
            "oauth_callback": "oob",
        ]

        request(requestTokenUrl, parameters: parameters, renewTokenOnError: false) {
            data, response, error in
            if let parametersString = NSString(data: data!, encoding:NSUTF8StringEncoding) {
                let responseParameters = (parametersString as String).dictionaryFromHttpParameters()
                if let token = responseParameters["oauth_token"], tokenSecret = responseParameters["oauth_token_secret"] {
                    self.token = token.stringByRemovingPercentEncoding
                    self.tokenSecret = tokenSecret.stringByRemovingPercentEncoding
                }

                self.openAuthorizeView()
            }
        }
    }

    func deliverUrl(url: NSURL) {

        safari?.dismissViewControllerAnimated(true, completion: nil)

        if let query = url.query?.stringByRemovingPercentEncoding {
            let queryDictionary = query.dictionaryFromHttpParameters()

            let parameters: [String: String] = [
                "oauth_verifier": queryDictionary["oauth_verifier"]!,
            ]

            request(accessTokenUrl, parameters: parameters, renewTokenOnError: false) {
                data, response, error in

                if let parametersString = NSString(data: data!, encoding:NSUTF8StringEncoding) {
                    let responseParameters = (parametersString as String).dictionaryFromHttpParameters()
                    if let token = responseParameters["oauth_token"], tokenSecret = responseParameters["oauth_token_secret"] {

                        self.token = token.stringByRemovingPercentEncoding
                        self.tokenSecret = tokenSecret.stringByRemovingPercentEncoding
//                        (UIApplication.sharedApplication().delegate as! AppDelegate).saveCredentials()

                        if let completionHandler = self.authorizeCompletionHandler {
                            completionHandler()
                            self.authorizeCompletionHandler = nil
                        }
                    }
                }
            }
        }
    }

    private func renewAccessToken(completionHandler: (Void) -> Void) {
        request(renewAccessTokenUrl, renewTokenOnError: false) {
            data, response, error in

            if let parametersString = NSString(data: data!, encoding:NSUTF8StringEncoding) {
                let responseParameters = (parametersString as String).dictionaryFromHttpParameters()
                if let token = responseParameters["oauth_token"], tokenSecret = responseParameters["oauth_token_secret"] {
                    self.token = token.stringByRemovingPercentEncoding
                    self.tokenSecret = tokenSecret.stringByRemovingPercentEncoding

//                    (UIApplication.sharedApplication().delegate as! AppDelegate).saveCredentials()
                }
            }

            completionHandler()
        }
    }

    private func signatureBaseString(url: String, method: Method, var parameters: [String : String]) -> String {
        var baseString = method == .GET ? "GET" : "POST"
        baseString += "&"
        baseString += url.stringByAddingPercentEncodingForURLQueryValue()
        baseString += "&"

        if parameters["oauth_token"] != nil {
            parameters["oauth_token"] = parameters["oauth_token"]!.stringByAddingPercentEncodingForURLQueryValue()
        }
        baseString += parameters.stringFromHttpParameters().stringByAddingPercentEncodingForURLQueryValue()

        return baseString
    }

    private func request(url: String, method: Method = .GET, var parameters: [String : String] = [String: String](), renewTokenOnError: Bool = true, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void)  -> Void {

        parameters["oauth_consumer_key"] = consumerKey
        parameters["oauth_timestamp"] = String(Int(NSDate().timeIntervalSince1970))
        parameters["oauth_nonce"] = NSUUID().UUIDString
        parameters["oauth_signature_method"] = "HMAC-SHA1"
        parameters["oauth_version"] = "1.0"

        if let token = self.token {
            parameters["oauth_token"] = token
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {

            var request: NSMutableURLRequest

            let baseString = self.signatureBaseString(url, method: method, parameters: parameters)
            var key = self.consumerSecret.stringByAddingPercentEncodingForURLQueryValue()
            key += "&"
            if let tokenSecret = self.tokenSecret {
                key += tokenSecret.stringByAddingPercentEncodingForURLQueryValue()
            }

            let signature = baseString.hmacsha1(key)
            parameters["oauth_signature"] = signature

            var oauthHeader = "OAuth realm=\"\""
            for k in Array(parameters.keys).sort() {
                oauthHeader += ",\(k)=\"\(parameters[k]!.stringByAddingPercentEncodingForURLQueryValue())\""
            }

            if let token = self.token {
                parameters["oauth_token"] = token.stringByAddingPercentEncodingForURLQueryValue()
            }

            if method == .GET {
                let requestURL = NSURL(string:"\(url)?\(parameters.stringFromHttpParameters())")
                request = NSMutableURLRequest(URL: requestURL!)
            }
            else {
                request = NSMutableURLRequest(URL: NSURL(string: url)!)
                request.HTTPMethod = "POST"
                request.HTTPBody = parameters.stringFromHttpParameters().dataUsingEncoding(NSUTF8StringEncoding)
            }

            request.addValue(oauthHeader, forHTTPHeaderField: "Authorization")

            let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
                var shouldRunCallback = true

                if renewTokenOnError {
                    if let urlResponse = response {
                        let httpResponse = urlResponse as! NSHTTPURLResponse
                        if httpResponse.statusCode == 401 {
                            self.renewAccessToken() {
                                self.request(url, method: method, parameters: parameters, renewTokenOnError: false, completionHandler: completionHandler)
                            }
                            shouldRunCallback = false
                        }
                    }
                }

                if shouldRunCallback {
                    completionHandler(data, response, error)
                }
            }

            task.resume()
        }
    }

}

class ETradeClient {

    let oauth: OAuth

    var viewController: UIViewController?

    var accounts: [Account]?

    var updateHandler: (Void) -> Void = {}

    init() {
        let secretsPath = NSBundle.mainBundle().pathForResource("Secrets", ofType: "plist")
        let secrets = NSDictionary(contentsOfFile: secretsPath!)! as! [String : String]

        oauth = OAuth(
            consumerKey: secrets["etrade_oauth_key"]!,
            consumerSecret: secrets["etrade_oauth_secret"]!,
            requestTokenUrl: "https://etws.etrade.com/oauth/request_token",
            authorizeUrl: "https://us.etrade.com/e/t/etws/authorize",
            accessTokenUrl: "https://etws.etrade.com/oauth/access_token",
            renewAccessTokenUrl: "https://etws.etrade.com/oauth/renew_access_token")
    }

    func deliverUrl(url: NSURL) {
        oauth.deliverUrl(url)
    }

    func authorize(completionHandler: (Void) -> Void) {
        oauth.authorize(completionHandler)
    }

    private func extractDouble(data: AnyObject) -> Double {
        var value = data as? Double

        if value == nil {
            if let valueString = data as? String {
                value = Double(valueString)
            }
        }

        return value!
    }

    private func updateAccounts(data: NSData) {
        do {
            let jsonResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers)

            if let json = jsonResult["json.accountListResponse"], response = json {
                let accountList = response["response"] as! [AnyObject]

                self.accounts = []

                for accountItem in accountList {
                    let acc = accountItem as! [String: AnyObject]

                    let account = Account(acc["accountId"] as! String)

                    self.accounts?.append(account)
                }
            }
        }
        catch {}
    }

    private func updateBalance(account: Account, data: NSData) {
        do {
            let jsonResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers)

            if let json = jsonResult["json.accountBalanceResponse"], response = json {

                let accountBalance = response["accountBalance"] as! [String: AnyObject]

                let position = Position(
                    symbol: "Cash",
                    description: "NET CASH",
                    category: Category.Cash,
                    price: extractDouble(accountBalance["netCash"]!),
                    basis: 0,
                    amount: 1)

                account.sync {
                    account.positions.append(position)
                }
            }
        }
        catch {}
    }

    private func updatePositions(account: Account, data: NSData) {
        do {
            let jsonResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers)

            if let json = jsonResult["json.accountPositionsResponse"], response = json {
                let positionList = response["response"] as! [AnyObject]

                for positionItem in positionList {
                    let pos = positionItem as! [String: AnyObject]

                    let product = pos["productId"] as! [String: AnyObject]

                    var category: Category
                    switch(product["typeCode"] as! String) {
                    case "EQ": category = Category.Equity
                    case "INDX": category = Category.ETF
                    case "MF": category = Category.Fund
                    case "FI": category = Category.Bond
                    default: continue
                    }

                    if (pos["qty"] as! Int) <= 0 {
                        continue
                    }

                    let position = Position(
                        symbol: product["symbol"] as! String,
                        description: pos["description"] as! String,
                        category: category,
                        price: extractDouble(pos["currentPrice"]!),
                        basis: extractDouble(pos["costBasis"]!),
                        amount: pos["qty"] as! UInt
                    )
                    account.positions.append(position)
                }
            }
        }
        catch {}
    }

    func update(completionHandler: (Void) -> Void) {
        oauth.request("https://etwssandbox.etrade.com/accounts/sandbox/rest/accountlist.json") {
            data, response, error in

            self.updateAccounts(data!)

            if let account = self.accounts?.first {
                account.positions = []

                let group = dispatch_group_create()

                dispatch_group_enter(group)
                self.oauth.request("https://etwssandbox.etrade.com/accounts/sandbox/rest/accountpositions/\(account.id).json") {
                    data, response, error in

                    self.updatePositions(account, data: data!)
                    dispatch_group_leave(group)
                }

                dispatch_group_enter(group)
                self.oauth.request("https://etwssandbox.etrade.com/accounts/sandbox/rest/accountbalance/\(account.id).json") {
                    data, response, error in

                    self.updateBalance(account, data: data!)
                    dispatch_group_leave(group)
                }

                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    dispatch_group_wait(group, DISPATCH_TIME_FOREVER)

                    completionHandler()
                    self.updateHandler()
                }
            }
        }
    }

    func setUpdateHander(completionHandler: (Void) -> Void) {
        self.updateHandler = completionHandler
    }

}