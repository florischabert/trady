//
//  Credentials.swift
//  Trady
//
//  Created by Floris Chabert on 2/24/16.
//  Copyright © 2016 Floris Chabert. All rights reserved.
//

import Foundation

class Credentials: NSObject, NSCoding {
    let username: String
    let password: String
    var account: String

    init(username: String, password: String, account: String) {
        self.username = username
        self.password = password
        self.account = account
    }

    required convenience init(coder decoder: NSCoder) {
        let username = decoder.decodeObjectForKey("username") as! String
        let password = decoder.decodeObjectForKey("password") as! String
        let account = decoder.decodeObjectForKey("account") as! String

        self.init(username: username, password: password, account: account)
    }

    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(username, forKey: "username")
        coder.encodeObject(password, forKey: "password")
        coder.encodeObject(account, forKey: "account")
    }

    func saveToKeyChain(deleteOnly: Bool = false) {
        let accessControlError:UnsafeMutablePointer<Unmanaged<CFError>?> = nil
        let accessControlRef = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            SecAccessControlCreateFlags.UserPresence,
            accessControlError
        )

        let query: [NSString : AnyObject] = [
            kSecClass : kSecClassGenericPassword,
            kSecAttrAccessControl: accessControlRef!,
            kSecAttrService : "Trady",
            kSecValueData : NSKeyedArchiver.archivedDataWithRootObject(self)
        ]

        SecItemDelete(query)
        if !deleteOnly {
            SecItemAdd(query, nil)
        }
    }

    static func loadFromKeyChain() -> (Credentials?, error: OSStatus) {
        var credentials: Credentials? = nil

        let query: [NSString : AnyObject] = [
            kSecClass : kSecClassGenericPassword,
            kSecAttrService : "Trady",
            kSecReturnData: kCFBooleanTrue,
            kSecMatchLimit : kSecMatchLimitOne,
            kSecUseOperationPrompt: "Identification required to access your portfolio."
        ]

        var result : AnyObject?
        let err = SecItemCopyMatching(query, &result)

        if err == errSecSuccess {
            if let data = result as? NSData {
                credentials = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? Credentials
            }
        }

        return (credentials, err)
    }

}