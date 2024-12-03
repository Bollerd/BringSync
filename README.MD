# Bring Sync / Homepod2Bring

Diese App synchronisiert Einträge aus einer Apple Erinnerungen Liste in eine Bring Einkaufsliste. Entstanden ist diese App deshalb, da wir Bring schon seit Jahren genutzt haben und über Amazon Echo Dots per Alexa Einträge in Bring hinzufügen können. Nachdem ein Homepod Mini als Homekit Steuerzentrale angeschafft wurde bestand das Problem, dass in dem Raum mit dem Homepod Mini keine Einträge in Bring per Siri hinzugefügt werden können, da Siri und der Homepod dies nicht unterstützen.

Allerings kann man in eine Liste mit Namen `Einkaufsliste` (oder jeder andere beliebige Listenname) in der Erinnerungen App Einträge per Sprachbefehl mit "Siri füge Milch auf meine Einkaufsliste hinzu" erfassen. Jetzt besteht nur noch das Problem. Wie bekommt man die Daten aus der "Einkaufsliste" in den Erinnerungen in die Einkaufsliste von Bring.

Bei der Suche bin ich auf bring-shopping als npm Module von Max Hauser gestossen. Daher nutzte die ursprüngliche Version dieser App eine zusätzliche nodeJS App auf einem Raspberry, um die Daten zu übertragen. Nachdem ich das npm Module von Max Hauser auf Github per Fork von request auf axios portiert hatte, kam auf meinen Pullrequest von Max Hauser die Rückantwort, dass er sich für meinen Port bedankt und dies als Anlass genommen hat auf fetch umzustellen, um keinerlei Abhängigkeiten zu haben. Was mich wiederum zum nachdenken gebracht hat, wieso ich eigentlich ein nodeJS Backend nutze und damit zum Sychronisieren mich immer im heimischen WLAN befinden muss. Daraufhin habe ich seinen neuen nodeJS Code von ChatGPT nach Swift portieren zu lassen. Und dann die Funktionen, die ich benutze entsprechend angepasst, weil der generierte Code nur generische `String:[Any]` Rückgabewerte statt die korrekten Strukturen in Swift hatte. Oder teils gar nicht funktioniert hat (saveItems Funktion).

## Funktionen der App

Die App zeigt in zwei Dropdowns alle verfügbaren Einkaufslisten aus Bring und der Erinnerungen App an. Hier muss man dann jeweils eine Liste wählen, für die die Synchronisation erfolgen soll. Mit `Listen aktualisieren` werden die sowohl dieverfügbaren Listen für die Dropdowns aktualisiert als auch die in der gewählten Erinnerungsliste aktuell gespeicherten "Einkaufserinnerugen".

Mit `Nach Bring synchronisieren` werden die Einträge aus der Apple Erinnerungen App nach Bring übertragen und in den Erinnerugen gelöscht.

Damit der Zugriff auf Bring funktioniert, muß über die Einstellungen sowohl die Emailadresse als auch das Passwort für Bring in der App hinterlegt werden. Diese Informationen werden sicher im Schlüsselbund von Apple gespeichert.

Die Synchronisation kann über die App erfolgen oder per Siri Integration über die Kurzbefehle App. In der App Kurzbefehle kann die Übertragung direkt mit Siri über den Begriff `Synchronisiere die Einkaufsliste` mit eigenem selbst definierten Sprachbefehl hinterlegt werden. Die App selbst kann durch "Synchronisiere Bring", "Synchronisiere Homepod mit Bring", "Synchronisiere Erinnerungen mit Bring",  "Synchronisiere die Einkaufsliste", "Starte Homepod2Bring", "Starte Bring Sync" geöffnet werden.

## Technische Informationen
Die Zugangsdaten zu Bring werden über das Security Framework von Apple im Schlüsselbund von Apple sicher und verschlüsselt hinterlegt.

Der Swift Code für den Bring Zugriff wurde durch ChatGPT von diesem nodeJS Code 
https://github.com/foxriver76/node-bring-api nach Swift übersetzt.

Im generierten Code habe ich alle von mir bisher nicht benutzen und nicht getesteten Funktionen markiert. Die Rückgabewerte in Form von String: [Any] habe ich für die von mir verwendeten Funktionen umgeschrieben und für Swift sauber typisiert.

Probleme gab es mit der saveItem Methode, da ChatGPT diese zuerst nach im korrekten Format als `application/x-www-form-urlencoded` erzeugt hat.

Die Siri Integration wird durch die structs SiriIntent und AppShortcuts in der Datei Model realisiert.

Die App ist sowohl für Light- als auch Darkmode ausgelegt und bietet auch zwei verschiedene App Icons.

## Notwendige Anpassungen
Die App kann mit dem vorhandenen Code aus Github direkt 1:1 verwendet werden.

## App Screenshots

### Synchronisations Ansicht
![Übersicht](https://ios.dbweb.info/wp-content/uploads/2024/12/bringsync1-scaled.jpg)

### Anmeldedaten
![Anmeldedaten](https://ios.dbweb.info/wp-content/uploads/2024/12/bringsync2-scaled.jpg)

### Siri Integration
![Siri](https://ios.dbweb.info/wp-content/uploads/2024/12/bringsync3-scaled.jpg)

