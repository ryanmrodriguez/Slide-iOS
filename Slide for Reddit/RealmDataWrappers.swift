//
//  RealmDataWrappers.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/26/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation

import reddift

class RealmDataWrapper {
    static func friendToRealm(user: User) -> Object {
        let rFriend = RFriend()
        rFriend.name = user.name
        rFriend.friendSince = NSDate(timeIntervalSince1970: TimeInterval(user.date))
        return rFriend
    }
    
    static func messageToRMessage(message: Message) -> RMessage {
        let title = message.baseJson["link_title"] as? String ?? ""
        var bodyHtml = message.bodyHtml.replacingOccurrences(of: "<blockquote>", with: "<cite>").replacingOccurrences(of: "</blockquote>", with: "</cite>")
        bodyHtml = bodyHtml.replacingOccurrences(of: "<div class=\"md\">", with: "")
        let rMessage = RMessage()
        rMessage.htmlBody = bodyHtml
        rMessage.name = message.name
        rMessage.id = message.id
        
        rMessage.author = message.author
        rMessage.subreddit = message.subreddit
        rMessage.created = NSDate(timeIntervalSince1970: TimeInterval(message.createdUtc))
        rMessage.isNew = message.new
        rMessage.linkTitle = title
        rMessage.context = message.context
        rMessage.wasComment = message.wasComment
        rMessage.subject = message.subject
        return rMessage
    }
    
    //Takes a More from reddift and turns it into a Realm model
    static func moreToRMore(more: More) -> RMore {
        let rMore = RMore()
        if more.id.endsWith("_") {
            rMore.id = "more_\(NSUUID().uuidString)"
        } else {
            rMore.id = more.id
        }
        rMore.name = more.name
        rMore.parentId = more.parentId
        rMore.count = more.count
        for s in more.children {
            let str = RString()
            str.value = s
            rMore.children.append(str)
        }
        return rMore
    }
    
}

class RMessage: Object {
    override class func primaryKey() -> String? {
        return "id"
    }
    
    @objc dynamic var id = ""
    @objc dynamic var name = ""
    @objc dynamic var author = ""
    @objc dynamic var created = NSDate(timeIntervalSince1970: 1)
    @objc dynamic var htmlBody = ""
    @objc dynamic var isNew = false
    @objc dynamic var linkTitle = ""
    @objc dynamic var context = ""
    @objc dynamic var wasComment = false
    @objc dynamic var subreddit = ""
    @objc dynamic var subject = ""
    
}

class RModlogItem: Object {
    override class func primaryKey() -> String? {
        return "id"
    }
    
    @objc dynamic var id = ""
    @objc dynamic var mod = ""
    @objc dynamic var targetBody = ""
    @objc dynamic var created = NSDate(timeIntervalSince1970: 1)
    @objc dynamic var subreddit = ""
    @objc dynamic var targetTitle = ""
    @objc dynamic var permalink = ""
    @objc dynamic var details = ""
    @objc dynamic var action = ""
    @objc dynamic var targetAuthor = ""
    @objc dynamic var subject = ""
}


class RString: Object {
    @objc dynamic var value = ""
}

class RMore: Object {
    override class func primaryKey() -> String? {
        return "id"
    }
        
    @objc dynamic var count = 0
    @objc dynamic var id = ""
    @objc dynamic var name = ""
    @objc dynamic var parentId = ""
    let children = List<RString>()
}

class RFriend: Object {
    @objc dynamic var name = ""
    @objc dynamic var friendSince = NSDate(timeIntervalSince1970: 1)
}

extension String {
    func convertHtmlSymbols() throws -> String? {
        guard let data = data(using: .utf8) else {
            return nil
        }
        
        return try NSAttributedString(data: data, options: convertToNSAttributedStringDocumentReadingOptionKeyDictionary([convertFromNSAttributedStringDocumentAttributeKey(NSAttributedString.DocumentAttributeKey.documentType): convertFromNSAttributedStringDocumentType(NSAttributedString.DocumentType.html), convertFromNSAttributedStringDocumentAttributeKey(NSAttributedString.DocumentAttributeKey.characterEncoding): String.Encoding.utf8.rawValue]), documentAttributes: nil).string
    }
}

extension String {
    init(htmlEncodedString: String) {
        self.init()
        guard let encodedData = htmlEncodedString.data(using: .utf8) else {
            self = htmlEncodedString
            return
        }
        
        let attributedOptions: [String: Any] = [
            convertFromNSAttributedStringDocumentAttributeKey(NSAttributedString.DocumentAttributeKey.documentType): convertFromNSAttributedStringDocumentType(NSAttributedString.DocumentType.html),
            convertFromNSAttributedStringDocumentAttributeKey(NSAttributedString.DocumentAttributeKey.characterEncoding): String.Encoding.utf8.rawValue,
            ]
        
        do {
            let attributedString = try NSAttributedString(data: encodedData, options: convertToNSAttributedStringDocumentReadingOptionKeyDictionary(attributedOptions), documentAttributes: nil)
            self = attributedString.string
        } catch {
            print("Error: \(error)")
            self = htmlEncodedString
        }
    }
}
// Helper function inserted by Swift 4.2 migrator.
private func convertToNSAttributedStringDocumentReadingOptionKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.DocumentReadingOptionKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.DocumentReadingOptionKey(rawValue: key), value) })
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringDocumentAttributeKey(_ input: NSAttributedString.DocumentAttributeKey) -> String {
    return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringDocumentType(_ input: NSAttributedString.DocumentType) -> String {
    return input.rawValue
}

//From https://stackoverflow.com/a/43665681/3697225
extension String {
    func dictionaryValue() -> [String: AnyObject] {
        if let data = self.data(using: String.Encoding.utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject]
                return json ?? [:]
            } catch {
                print("Error converting to JSON")
            }
        }
        return NSDictionary() as! [String : AnyObject]
    }
}

extension NSDictionary {
    func jsonString() -> String {
        do {
            let jsonData: Data = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
                return String.init(data: jsonData, encoding: .utf8)!
        } catch {
            return "{}"
        }
    }
}
