//
//  ContentView.swift
//  Bring Sync
//
//  Created by Dirk Boller on 07.03.24.
//

import SwiftUI
import EventKit

struct ContentView: View {
    @EnvironmentObject var model: Model
    @State var isSettingVisible = false
    let font:Font = Font.custom("CourierNewPS-BoldMT",size:17.0)
    var body: some View {
        VStack {
            HStack {
                Text("Homepod2Bring").font(.title)
                Spacer()
                Button {
                    self.isSettingVisible = true
                } label: {
                    Image(systemName: "gearshape.fill").font(.title).symbolVariant(.fill)
                        .foregroundColor(.accentColor)
                }
            }.padding(.horizontal)
            
          //  Text("Homepod2Bring").font(.title)
            Spacer().frame(height: 40)
            if model.email == "" || model.password == "" || model.isLoggedIn == false {
                if model.email == "" || model.password == "" {
                    Text("Bring Anmeldedaten unvollständig").font(.title).multilineTextAlignment(.center)
                } else {
                    if model.isLoggedIn == false {
                        Text("Bring Anmeldedaten fehlerhaft oder keine Anmeldung möglich").font(.title).multilineTextAlignment(.center)
                    }
                }
            } else {
                VStack {
                    Text("Synchronisation zwischen folgenden Listen").font(.headline).multilineTextAlignment(.center)
                    HStack {
                        Text("Bringliste")
                        Spacer()
                        Picker("Bring Liste", selection: $model.selectedBringList) {
                            ForEach(model.bringListen, id: \.self) {
                                Text($0.name)
                            }
                        }.onChange(of: model.selectedBringList) {
                            newValue in
                            self.model.selectedBringListId = newValue.listUuid
                        }
                    }
                    HStack {
                        Text("Erinnerungen")
                        Spacer()
                        Picker("Erinnungen Liste", selection: $model.selectedReminderList) {
                            ForEach(model.reminderListen, id: \.self) {
                                Text($0)
                            }
                        }.onChange(of: model.selectedReminderList) {
                            newValue in
                            self.model.syncLists()
                        }
                    }
                }.padding(10).background(Color("BackgroundLists"))//.background(Color.mint.opacity(0.4))
                    .cornerRadius(10)
                List {
                    ForEach(model.allReminders, id: \.self) {
                        Text($0.title)
                    }
                }
                Text("\($model.updateMessage.wrappedValue)").font(font).multilineTextAlignment(.center).padding()
                Spacer()
                Button("Listen aktualisieren") {
                    self.model.syncLists()
                    self.model.startTransfer(noTransfer: true)
                }.buttonStyle(.borderedProminent)
                Button("Nach Bring synchronisieren") {
                    self.model.startTransfer(noTransfer: false)
                }.buttonStyle(.borderedProminent)
                    .padding()
            }
            
            Spacer()
            Text("Made with ❤️ in SwiftUI by Dirk v \(VERSION) (\(BUILD))").font(.footnote)
        }.sheet(isPresented: $isSettingVisible) {
            SettingsView(isPresented: $isSettingVisible).presentationDragIndicator(.visible)
        }.onAppear(perform: {
            if model.email.isEmpty || model.password.isEmpty {
                isSettingVisible = true
            }
        }).padding()
    }
}
/*
#Preview {
    ContentView().environmentObject(Model(previewDisplay: true))
}
*/
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(Model(previewDisplay: true))
    }
}
