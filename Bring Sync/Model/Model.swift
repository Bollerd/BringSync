import SwiftUI
import os
import EventKit
import AppIntents
import Security
import Foundation

struct SiriIntent: AppIntent {
    static let title: LocalizedStringResource = "Synchronisiere die Einkaufsliste"
    
    func perform() async throws -> some ReturnsValue<String> & ProvidesDialog {// some IntentResult & ReturnsValue<String> {
        let model = Model()
        let siriResponse = await   model.syncDataFromSiri()
       // return .result(value: siriResponse)
     
        return .result(
            value: siriResponse,
            dialog: "\(siriResponse)"
        )
      
    }
}
/*
struct SiriIntent: AppIntent {
    static let title: LocalizedStringResource = "Was gibt es heute in der Kantine?"
    
    func perform() async throws -> some ReturnsValue<String> & ProvidesDialog {//IntentResult & ReturnsValue<String> {//some ReturnsValue & ProvidesDialog {
        let model = Model()
        await model.readData()
        let siriResponse = model.getCanteenMenuForSiri()
        return .result(
            value: siriResponse,
            dialog: "\(siriResponse)"
        )
    }
}
*/
struct AppShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SiriIntent(),
            phrases: ["Synchronisiere Bring",
                      "Synchronisiere Homepod mit Bring",
                      "Synchronisiere Erinnerungen mit Bring",
                      "Synchronisiere die Einkaufsliste",
                      "Starte Homepod2Bring",
                      "Starte Bring Sync"]
        )
    }
}

class Model: ObservableObject {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "main")
    var reminders = Reminders()
    @Published var allReminders = [EKReminder]()
    @Published var updateMessage = ""
    @Published var settingsMessage = ""
    @Published var bringListen = [BringListElement(listUuid: "", name: "", theme: "")]
    @Published var selectedBringList = BringListElement(listUuid: "", name: "", theme: "")
    @Published var reminderListen: [String] = ["Preview 1", "Preview 2"]
    @Published var email: String = ""
    @Published var password: String = ""
    @AppStorage("selectedBringListId") var selectedBringListId: String = ""
    @AppStorage("selectedReminderList") var selectedReminderList: String = ""
    private var bring: Bring?
    @Published var isLoggedIn = false
    private var isKeychainRead = false
    private var lists: [BringListElement] = []
    
    init(previewDisplay: Bool = false) {
        if Reminders.requestAccess() {
            print("Access granted")
        } else {
            print("Byebye and tschüss")
            return
        }
        self.readFromKeychain()
        Task {
            if !(self.email.isEmpty || self.password.isEmpty) {
                bring = Bring(mail: self.email, password: self.password)
                await self.login()
                
                DispatchQueue.main.async {
                    self.syncLists()
                }
            }
        }
    }
    
    func setBringCredential(email: String, password: String) {
        self.bring = Bring(mail: email, password: password)
    }
    
    func login() async -> Bool {
        self.bring = Bring(mail: self.email, password: self.password)
        
        if let bring = self.bring {
            do {
                try await bring.login()
                DispatchQueue.main.async {
                    self.isLoggedIn = true
                }
                return true
            } catch {
                DispatchQueue.main.async {
                    self.isLoggedIn = false
                }
                return false
            }
            
        } else {
            DispatchQueue.main.async {
                self.isLoggedIn = false
            }
            return false
        }
    }
    
    func syncLists()  {
        self.reminderListen = reminders.getLists()
        self.startTransfer(noTransfer: true) //TODO this line is called from syncLists already
        if self.selectedReminderList != "" {
            reminders.showListItems(withName: self.selectedReminderList)
        }
        
        self.allReminders = reminders.allReminders
        if self.allReminders.count == 0 {
            self.updateMessage = NOT_REMINDERS_TO_TRANSFER
        } else {
            self.updateMessage = ""
        }
    }
    
    
    func syncDataFromSiri() async -> String  {
        var siriMessage: String = ""
        
        if self.selectedBringListId == "" {
            return "Bitte wähle zuerst eine Bring Liste aus."
        }
        
        if self.selectedReminderList == "" {
            return "Bitte wähle zuerst eine Erinnerungen Liste aus."
        }
        
        self.syncLists()
        
        siriMessage = self.updateMessage
        
        if siriMessage == NOT_REMINDERS_TO_TRANSFER {
            return siriMessage
        }
        
        self.readFromKeychain()
        
        if !(self.email.isEmpty || self.password.isEmpty) {
            bring = Bring(mail: self.email, password: self.password)
            await self.login()
            
            if self.isLoggedIn {
                startTransfer(noTransfer: false)
                siriMessage = "Es war mir eine Freude die Daten an Bring zu übertragen. Gerne wieder!"
            } else {
                siriMessage = "Anmeldung an Bring nicht erfolgreich. Bitte überprüfen ob die Anmeldedaten korrekt sind."
            }
        } else {
            siriMessage = "Die Anmeldedaten für Bring sind unvollständig. Bitte in der App hinterlegen."
        }
      
        return siriMessage
    }
    
    func transferToBring(description: String) async {
        if let bring = self.bring {
            do {
                let _ = try await bring.saveItem(listUuid:  self.selectedBringList.listUuid, itemName: description, specification: "" )
                DispatchQueue.main.async {
                    self.updateMessage += "\n" + description + " übertragen"
                }
            } catch {
                logger.error("\(description) konnte nicht gespeichertw werden: \(String(describing: error))")
            }
        } else {
            logger.error("No existing bring object")
        }
    }
    
    func startTransfer(noTransfer: Bool) {
        Task {
           if let bring = self.bring {
                do {
                    self.lists = try await bring.loadLists()
                    
                } catch {
                    logger.error("Error loading Bring lists: \(String(describing: error))")
                }
            } else {
                logger.error("No existing bring object")
            }
            
            DispatchQueue.main.async {
                self.bringListen = self.lists
                for bringListe in self.lists {
                    if bringListe.listUuid == self.selectedBringListId {
                        self.selectedBringList = bringListe
                    }
                }
                if self.bringListen.count >= 1 && self.selectedBringListId == "" {
                    self.selectedBringList = self.bringListen[0]
                    self.selectedBringListId = self.selectedBringList.listUuid
                }
                
                if noTransfer == false {
                    for (index, reminder) in self.allReminders.reversed().enumerated() {
                        let reversedIndex = self.allReminders.count - index - 1
                        print("Index: \(index) / \(reversedIndex), Element: \(reminder)")
                        Task {
                            await self.transferToBring(description: reminder.title)
                            self.reminders.delete(itemAtIndex:reversedIndex, onListNamed: self.selectedReminderList)
                        }
                    }
                    self.allReminders.removeAll()
                }
            }
        }
    }
    
    private func saveToKeychainCore() {
        if let emailData = email.data(using: .utf8),
           let passwordData = password.data(using: .utf8) {
            let emailQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: "email",
                kSecValueData as String: emailData
            ]
            let passwordQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: "password",
                kSecValueData as String: passwordData
            ]
            let status1 = SecItemAdd(emailQuery as CFDictionary, nil)
            let status2 = SecItemAdd(passwordQuery as CFDictionary, nil)
            
            if status1 != errSecSuccess || status2 != errSecSuccess {
                self.settingsMessage = "Error saving to keychain"
            }
        } else {
            self.settingsMessage = "Not all required fields are filled"
        }
    }
    
    func saveToKeychain() {
        let emailQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "email"
        ]
        let passwordQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "password"
        ]
        
        if self.isKeychainRead == true {
            let status1 = SecItemDelete(emailQuery as CFDictionary)
            let status2 = SecItemDelete(passwordQuery as CFDictionary)
            
            if status1 == errSecSuccess && status2 == errSecSuccess {
                self.saveToKeychainCore()
            } else {
                self.settingsMessage = "Error deleting existing keychain entries"
            }
        } else {
            self.saveToKeychainCore()
        }
    }

    func readFromKeychain() {
        let emailQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "email",
            kSecReturnData as String: kCFBooleanTrue as CFBoolean
        ]
        var dataTypeRef: AnyObject?
        let status1 = SecItemCopyMatching(emailQuery as CFDictionary, &dataTypeRef)
        if status1 == errSecSuccess,
           let data = dataTypeRef as? Data,
           let storedEmail = String(data: data, encoding: .utf8) {
            email = storedEmail
            self.isKeychainRead = true
        }
        
        let passwordQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "password",
            kSecReturnData as String: kCFBooleanTrue as CFBoolean
        ]
        var dataTypeRef2: AnyObject?
        let status2 = SecItemCopyMatching(passwordQuery as CFDictionary, &dataTypeRef2)
        if status2 == errSecSuccess,
           let data = dataTypeRef2 as? Data,
           let storedPassword = String(data: data, encoding: .utf8) {
            password = storedPassword
        }
    }
}

