//
//  BringAPI.swift
//  Bring Sync
//
//  Created by Dirk Boller on 01.12.2024.
//
//  Ported from nodeJS library of Max Hauser: https://github.com/foxriver76/node-bring-api
//  functions used in this app where changed to Swift Structures of correct type, not used functions
//  from the nodeJS port are returning only String: Any dictionaries (marked in the function documentation
//  header as not tested yet

import Foundation

// MARK: - BringListElement
class BringListElement: Codable, Hashable, Equatable {
    let listUuid, name, theme: String
    
    enum CodingKeys: String, CodingKey {
        case listUuid = "listUuid"
        case name, theme
    }
    
    init(listUuid: String, name: String, theme: String) {
        self.listUuid = listUuid
        self.name = name
        self.theme = theme
    }
    
    static func == (lhs: BringListElement, rhs: BringListElement) -> Bool {
        return lhs.listUuid == rhs.listUuid
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(listUuid)
    }
}

// MARK: - BringListElement
class BringList: Codable {
    let lists: [BringListElement]
}

// MARK: - BringItemElement
class BringItemElement: Codable, Hashable, Equatable {
    let id = UUID()
    let specification, name: String
    
    enum CodingKeys: String, CodingKey {
        case specification, name
    }
    
    init(specification: String, name: String) {
        self.specification = specification
        self.name = name
    }
    
    static func == (lhs: BringItemElement, rhs: BringItemElement) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - BringItem
class BringItem: Codable {
    let uuid, status: String
    let purchase: [BringItemElement]
}

typealias BringLists = [BringListElement]
typealias BringItems = [BringItemElement]

class Bring {
    private var mail: String
    private var password: String
    private var url: String
    private var uuid: String
    private var headers: [String: String]
    private var bearerToken: String?
    private var refreshToken: String?
    private var putHeaders: [String: String]

    init(mail: String, password: String) {
        //options: [String: Any]
        self.mail = mail//options["mail"] as! String
        self.password = password//options["password"] as! String
        self.url = "https://api.getbring.com/rest/v2/"
        self.uuid = ""
        self.headers = [
            "X-BRING-API-KEY": "cof4Nc6D8saplXjE3h3HXqHH8m7VU2i1Gs0g85Sp",
            "X-BRING-CLIENT": "webApp",
            "X-BRING-CLIENT-SOURCE": "webApp",
            "X-BRING-COUNTRY": "DE"
        ]
        self.putHeaders = self.headers
    }

    // MARK: - Login
    func login() async throws {
        let url = URL(string: "\(self.url)bringauth")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = self.headers
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Create the form URL-encoded body
        let body = "email=\(self.mail)&password=\(self.password)"
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorResponse = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "Cannot Login", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response: \(errorResponse)"])
        }

        // Handle JSON response
        let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        if let error = json["error"] as? String {
            throw NSError(domain: "Cannot Login", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error: \(error)"])
        }

        self.uuid = json["uuid"] as! String
        self.bearerToken = json["access_token"] as? String ?? ""
        self.refreshToken = json["refresh_token"] as? String ?? ""

        self.headers["X-BRING-USER-UUID"] = self.uuid
        self.headers["Authorization"] = "Bearer \(self.bearerToken!)"
        self.putHeaders = self.headers.merging([
            "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"
        ]) { (current, _) in current }
    }

    // MARK: - Load Lists
    func loadLists() async throws -> BringLists {
        let url = URL(string: "\(self.url)bringusers/\(self.uuid)/lists")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = self.headers

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Cannot get lists", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
      
        guard let listData = try? JSONDecoder().decode(BringList.self, from: data) else {
            return []
        }
        
        return listData.lists
    }

    // MARK: - Get Items
    func getItems(listUuid: String) async throws -> BringItems {
        let url = URL(string: "\(self.url)bringlists/\(listUuid)")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = self.headers

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Cannot get items", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        guard let itemData = try? JSONDecoder().decode(BringItem.self, from: data) else {
            return []
        }
        
        return itemData.purchase
    }

    // MARK: - Save Item
    func saveItem(listUuid: String, itemName: String, specification: String) async throws -> String {
        let saveItemURL = URL(string: "\(url)bringlists/\(listUuid)")!
        
        // Erstelle URL-encoded body (application/x-www-form-urlencoded)
        let body = [
            "purchase": itemName,
            "recently": "",
            "specification": specification,
            "remove": "",
            "sender": "null"
        ]
        
        // URL-encoded body erstellen
        var bodyString = ""
        for (key, value) in body {
            if let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                bodyString += "\(encodedKey)=\(encodedValue)&"
            }
        }
        
        // Entferne das letzte "&" Zeichen
        bodyString = String(bodyString.dropLast())
        
        // Request zusammenstellen
        var request = URLRequest(url: saveItemURL)
        request.httpMethod = "PUT"
        request.allHTTPHeaderFields = putHeaders
        request.httpBody = bodyString.data(using: .utf8)
        
        // Sende die Anfrage
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Überprüfen des Statuscodes
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 204 {
            throw NSError(domain: "SaveItemError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unexpected response status: \(httpResponse.statusCode)"])
        }
        
        // Falls der Body eine Antwort enthält, geben wir sie zurück (um zu prüfen, was der Server zurückgibt)
        if let responseString = String(data: data, encoding: .utf8) {
            return responseString
        } else {
            throw NSError(domain: "SaveItemError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid response data"])
        }
    }

    // MARK: - Save Item Image
    // ported from ChatGPT but not tested
    func saveItemImage(itemUuid: String, image: [String: Any]) async throws -> [String: Any] {
        let url = URL(string: "\(self.url)bringlistitemdetails/\(itemUuid)/image")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.allHTTPHeaderFields = self.putHeaders

        request.httpBody = try! JSONSerialization.data(withJSONObject: image)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 else {
            throw NSError(domain: "Cannot save item image", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        return json
    }

    // MARK: - Remove Item
    // ported from ChatGPT but not tested
    func removeItem(listUuid: String, itemName: String) async throws -> String {
        let url = URL(string: "\(self.url)bringlists/\(listUuid)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.allHTTPHeaderFields = self.putHeaders

        let body = [
            "remove": itemName,
            "sender": "null"
        ]
        request.httpBody = try! JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 else {
            throw NSError(domain: "Cannot remove item", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        return String(data: data, encoding: .utf8) ?? ""
    }

    // MARK: - Get User Settings
    // ported from ChatGPT but not tested
    func getUserSettings() async throws -> [String: Any] {
        let url = URL(string: "\(self.url)bringusersettings/\(self.uuid)")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = self.headers

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Cannot get user settings", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        if let stringData = String(data: data, encoding: .utf8)  {
            print(stringData)
        }
        
        let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        return json
    }

    // MARK: - Load Translations
    // ported from ChatGPT but not tested
    func loadTranslations(locale: String) async throws -> [String: Any] {
        let url = URL(string: "https://web.getbring.com/locale/articles.\(locale).json")!
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Cannot get translations", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        if let stringData = String(data: data, encoding: .utf8)  {
            print(stringData)
        }
        
        let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        return json
    }
    
    // MARK: - Load Catalog
    // ported from ChatGPT but not tested
    func loadCatalog(locale: String) async throws -> [String: Any] {
        let url = URL(string: "https://web.getbring.com/locale/catalog.\(locale).json")!
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Cannot get catalog", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        if let stringData = String(data: data, encoding: .utf8)  {
            print(stringData)
        }
        
        let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        return json
    }

    // MARK: - Get Pending Invitations
    // ported from ChatGPT but not tested
    func getPendingInvitations() async throws -> [[String: Any]] {
        let url = URL(string: "\(self.url)bringusers/\(self.uuid)/invitations?status=pending")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = self.headers

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Cannot get pending invitations", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]]
        return json
    }
}
