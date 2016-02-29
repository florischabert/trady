//
//  OFXClient.swift
//  Trady
//
//  Created by Floris Chabert on 2/24/16.
//  Copyright © 2016 Floris Chabert. All rights reserved.
//

import Foundation

class Tag {
    let name: String
    let field: String?
    let subTags: [Tag]?

    init(_ name: String, _ subTags: [Tag]) {
        self.name = name
        self.subTags = subTags
        field = nil
    }

    init(_ name: String, _ field: String) {
        self.name = name
        self.field = field
        subTags = nil
    }

    func toString() -> String {
        var string = ""

        if let field = field {
            string += "<\(name)>\(field)\n"
        }

        if let subTags = subTags {
            string += "<\(name)>\n"
            for subTag in subTags {
                string += subTag.toString()
            }
            string += "</\(name)>\n"
        }

        return string
    }
}

extension String {
    func toSGMLDictionary() -> [String: AnyObject] {
        var data = self.stringByReplacingOccurrencesOfString("\n", withString: "")
        var dict: [String: AnyObject] = [:]

        while let tagStart = data.rangeOfString("<"), tagEnd = data.rangeOfString(">") {

            let tagName = data[tagStart.endIndex..<tagEnd.startIndex]
            var tagValue: AnyObject

            if let closingTag = data.rangeOfString("</\(tagName)>") {
                tagValue = data[tagEnd.endIndex..<closingTag.startIndex].toSGMLDictionary()
                data = data[closingTag.endIndex..<data.endIndex]
            }
            else {
                data = data[tagEnd.endIndex..<data.endIndex]

                let valueEnd = data.rangeOfString("<")?.startIndex ?? data.endIndex

                tagValue = data[data.startIndex..<valueEnd]
                data = data[valueEnd..<data.endIndex]
            }

            if let currentTagValue = dict[tagName] {
                var currentTagValueArray = currentTagValue as? [AnyObject] ?? [currentTagValue]
                currentTagValueArray.append(tagValue)
                dict[tagName] = currentTagValueArray
            }
            else {
                dict[tagName] = tagValue
            }
        }
        
        return dict
    }
}

extension NSDate {
    static func dateString(format: String) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.stringFromDate(NSDate())
    }
}

class OFXClient {
    enum Error: ErrorType {
        case BadFormat
    }

    let url: NSURL
    let appID = "QWIN"
    let appVersion = "1200"

    init(url: NSURL) {
        self.url = url
    }

    private func parse(string: String) -> [String: AnyObject]? {
        var ofx: [String: AnyObject]?

        let string = string.stringByReplacingOccurrencesOfString("\n", withString: "")

        if let startTag = string.rangeOfString("<OFX>"), endTag = string.rangeOfString("</OFX>") {
            ofx = string[startTag.endIndex..<endTag.startIndex].toSGMLDictionary()
        }

        return ofx
    }

    private func request(credentials: Credentials, ofxString: String, completionHandler: (ofx: [String: AnyObject]?) -> Void) {
        let urlRequest = NSMutableURLRequest(URL: url)
        urlRequest.HTTPMethod = "POST"

        let header =
            "OFXHEADER:100\n" +
            "DATA:OFXSGML\n" +
            "VERSION:102\n" +
            "SECURITY:NONE\n" +
            "ENCODING:USASCII\n" +
            "CHARSET:1252\n" +
            "COMPRESSION:NONE\n" +
            "OLDFILEUID:NONE\n" +
            "NEWFILEUID:\(NSUUID().UUIDString)\n" +
            "\n"

        let logon =
            Tag("SIGNONMSGSRQV1", [
                Tag("SONRQ", [
                    Tag("DTCLIENT", NSDate.dateString("yyyyMMddHHmmss")),
                    Tag("USERID", credentials.username),
                    Tag("USERPASS", credentials.password),
                    Tag("LANGUAGE", "ENG"),
                    Tag("FI", [
                        Tag("ORG", "MyCreditUnion"),
                        Tag("FID", "31337")
                    ]),
                    Tag("APPID", appID),
                    Tag("APPVER", appVersion)
                ])
            ]).toString()

        let postString = header + "<OFX>\n" + logon + ofxString + "</OFX>\n"
        let postData = postString.dataUsingEncoding(NSUTF8StringEncoding)
        urlRequest.HTTPBody = postData!
        urlRequest.addValue(String(postData!.length), forHTTPHeaderField: "Content-Length")

        urlRequest.addValue("application/x-ofx", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("*/*, application/x-ofx", forHTTPHeaderField: "Accept")

        let task = NSURLSession.sharedSession().dataTaskWithRequest(urlRequest) {
            data, response, error in

            var ofx: [String: AnyObject]?
            
            guard error == nil && data != nil else {
                completionHandler(ofx: ofx)
                return
            }

            if let httpStatus = response as? NSHTTPURLResponse where httpStatus.statusCode != 200 {
                completionHandler(ofx: ofx)
                return

            }

            if let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding) as? String {
                if let ofxTag = responseString.rangeOfString("<OFX>") {
                    let ofxString = responseString[ofxTag.startIndex..<responseString.endIndex]
                    ofx = ofxString.toSGMLDictionary()
                }
            }

            completionHandler(ofx: ofx)

        }
        task.resume()
    }

    func login(username: String, _ password: String, completionHandler: (credentials: Credentials?) -> Void) -> Void {

        let ofx =
            Tag("SIGNUPMSGSRQV1", [
                Tag("ACCTINFOTRNRQ", [
                    Tag("TRNUID", NSUUID().UUIDString),
                    Tag("CLTCOOKIE", "4"),
                    Tag("ACCTINFORQ", [
                        Tag("DTACCTUP", "19700101000000")
                    ])
                ])
            ]).toString()

        request(Credentials(username: username, password: password, account: ""), ofxString: ofx) { ofx in
            if let ofx = ofx, account = (ofx as NSDictionary).valueForKeyPath("OFX.SIGNUPMSGSRSV1.ACCTINFOTRNRS.ACCTINFORS.ACCTINFO.INVACCTINFO.INVACCTFROM.ACCTID") as? String {
                completionHandler(credentials: Credentials(username: username, password: password, account: account))
            }
            else {
                completionHandler(credentials: nil)
            }
        }
    }


    func getAccount(credentials: Credentials, completionHandler: (account: Account?) -> Void) -> Void {

        let ofx =
            Tag("INVSTMTMSGSRQV1", [
                Tag("INVSTMTTRNRQ", [
                    Tag("TRNUID", NSUUID().UUIDString),
                    Tag("CLTCOOKIE", "4"),
                    Tag("INVSTMTRQ", [
                        Tag("INVACCTFROM", [
                            Tag("BROKERID", "etrade.com"),
                            Tag("ACCTID", credentials.account)
                        ]),
                        Tag("INCTRAN", [
                            Tag("DTSTART", NSDate.dateString("yyyyMMdd")),
                            Tag("INCLUDE", "N")
                        ]),
                        Tag("INCOO", "Y"),
                        Tag("INCPOS", [
                            Tag("DTASOF",  NSDate.dateString("yyyyMMddHHmmss")),
                            Tag("INCLUDE", "Y")
                        ]),
                        Tag("INCBAL", "Y")
                    ])
                ])
            ]).toString()

        request(credentials, ofxString: ofx) { ofx in
            if let ofx = ofx {
                let ofx = ofx as NSDictionary

                var cash: Double?
                var value: Double?

                if let cashString = ofx.valueForKeyPath("OFX.INVSTMTMSGSRSV1.INVSTMTTRNRS.INVSTMTRS.INVBAL.AVAILCASH") as? String {
                    cash = Double(cashString)
                }

                for balance in ofx.valueForKeyPath("OFX.INVSTMTMSGSRSV1.INVSTMTTRNRS.INVSTMTRS.INVBAL.BALLIST.BAL") as! NSArray {
                    if let name = balance["NAME"] as? String where name == "Total Account Value" {
                        if let balValue = balance["VALUE"] as? String {
                            value = Double(balValue)
                        }
                    }
                }

                let account = Account(credentials.account, value: (value ?? 0) + (cash ?? 0), cash: cash ?? 0)
                account.positions.append(Position(symbol: "CASH", category: Category.Cash, price: account.cash, quantity: 1))

                for positionType in ["POSMF", "POSSTOCK", "POSDEBT", "POSOPT", "POSOTHER"] {
                    if let positions = ofx.valueForKeyPath("OFX.INVSTMTMSGSRSV1.INVSTMTTRNRS.INVSTMTRS.INVPOSLIST.\(positionType)") as? NSArray {
                        for position in positions {
                            var category = Category.Cash
                            switch (positionType) {
                                case "POSMF": category = Category.Fund
                                case "POSSTOCK": category = Category.Equity
                                case "POSDEBT": category = Category.Bond
                                case "POSOPT": category = Category.Option
                                default: Category.Cash
                            }

                            var symbol = (position.valueForKeyPath("INVPOS.MEMO") as? String)
                            symbol = symbol?.stringByReplacingOccurrencesOfString(".", withString: "-")

                            let position = Position(
                                symbol: symbol ?? "UKW",
                                category: category,
                                price: Double(position.valueForKeyPath("INVPOS.UNITPRICE") as! String) ?? 0.0,
                                quantity: Double(position.valueForKeyPath("INVPOS.UNITS") as! String) ?? 0
                            )
                            account.positions.append(position)
                        }
                    }
                }

                account.positions.sortInPlace { Double($0.quantity)*$0.price > Double($1.quantity)*$1.price }

                completionHandler(account: account)
            }
            else {
                completionHandler(account: nil)
            }
        }
    }
    
}