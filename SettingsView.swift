//
//  SettingsView.swift
//  Bring Sync
//
//  Created by Dirk Boller on 01.12.2024.
//
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var model: Model
    @Binding var isPresented: Bool
    let font:Font = Font.custom("CourierNewPS-BoldMT",size:17.0)
    
    var body: some View {
        Form {
            Text("Anmeldedaten für Bring").font(.title)
            if model.email.isEmpty || model.password.isEmpty {
                Text("Es sind noch keine Bring Zugangsdaten gespeichert. Diese müssen zuerst hinterlegt werden")
            }
            Text("Email Bring")
            TextField("Email", text: $model.email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Text("Passwort Bring")
            SecureField("Password", text: $model.password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Text("\(model.settingsMessage)").font(font).padding()
            Spacer()
           
            Button("Speichern") {
                model.saveToKeychain()
                Task {
                    await model.login()
                   
                    if model.isLoggedIn {
                        DispatchQueue.main.async {
                            model.syncLists()
                        }
                    }
                  
                    if model.updateMessage.isEmpty {
                        isPresented = false
                    }
                }
            }.buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    @State var isPresented: Bool = true
    SettingsView(isPresented: $isPresented).environmentObject(Model(previewDisplay: true))
}
