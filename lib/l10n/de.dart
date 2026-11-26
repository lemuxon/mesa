// Türkçe metin → çeviri. Anahtarlar test/l10n_test.dart ile denetlenir
// (yeni metin: tr() ekleyin, buraya ve diğer dillere çevirisini yazın).
const de = <String, String>{
  'Pazartesi': 'Montag',
  'Salı': 'Dienstag',
  'Çarşamba': 'Mittwoch',
  'Perşembe': 'Donnerstag',
  'Cuma': 'Freitag',
  'Cumartesi': 'Samstag',
  'Pazar': 'Sonntag',
  'Bugün': 'Heute',
  'Dün': 'Gestern',
  '{day} Ocak': '{day}. Januar',
  '{day} Şubat': '{day}. Februar',
  '{day} Mart': '{day}. März',
  '{day} Nisan': '{day}. April',
  '{day} Mayıs': '{day}. Mai',
  '{day} Haziran': '{day}. Juni',
  '{day} Temmuz': '{day}. Juli',
  '{day} Ağustos': '{day}. August',
  '{day} Eylül': '{day}. September',
  '{day} Ekim': '{day}. Oktober',
  '{day} Kasım': '{day}. November',
  '{day} Aralık': '{day}. Dezember',
  '{day}.{month}.{year}': '{day}.{month}.{year}',
  'bugün {clock}': 'heute {clock}',
  'yarın {clock}': 'morgen {clock}',
  'şimdi': 'jetzt',
  '{n} dk': '{n} Min.',
  '{n} sa': '{n} Std.',
  '{n} g': '{n} T.',
  'B': 'B',
  'KB': 'KB',
  'MB': 'MB',
  'GB': 'GB',
  'Çıkartma': 'Sticker',
  '📷 Fotoğraf': '📷 Foto',
  'Otomatik yanıt': 'Automatische Antwort',
  'Sessize al': 'Stummschalten',
  'Önemli işaretle': 'Als wichtig markieren',
  '15 dakika': '15 Minuten',
  '1 saat': '1 Stunde',
  '6 saat': '6 Stunden',
  '1 gün': '1 Tag',
  'Pzt': 'Mo',
  'Sal': 'Di',
  'Çar': 'Mi',
  'Per': 'Do',
  'Cum': 'Fr',
  'Cmt': 'Sa',
  'Paz': 'So',
  'hafta içi': 'werktags',
  'hafta sonu': 'am Wochenende',
  'Tüm uygulamalar': 'Alle Apps',
  'Kimden: "{sender}"': 'Von: „{sender}“',
  'İçerik: {words}': 'Enthält: {words}',
  'gruplar dahil': 'inkl. Gruppen',
  'Süresiz': 'Unbegrenzt',
  '7 gün': '7 Tage',
  '30 gün': '30 Tage',
  '90 gün': '90 Tage',
  '1 yıl': '1 Jahr',
  'Tamam 👍': 'Okay 👍',
  'Şu an müsait değilim, sonra yazarım.':
      'Ich kann gerade nicht, ich schreibe später.',
  'Yoldayım, birazdan oradayım.': 'Bin unterwegs, gleich da.',
  'Teşekkürler!': 'Danke!',
  '{step} bir giriş adımı değil': '{step} ist kein Anmeldeschritt',
  '🎥 Video': '🎥 Video',
  '🎵 Ses dosyası': '🎵 Audiodatei',
  '🎤 Sesli mesaj': '🎤 Sprachnachricht',
  '🎤 Ses': '🎤 Audio',
  '⏺ Görüntülü mesaj': '⏺ Videonachricht',
  '📍 Konum': '📍 Standort',
  '📄 Dosya': '📄 Datei',
  '👤 Kişi': '👤 Kontakt',
  '📊 Anket': '📊 Umfrage',
  'Arşiv': 'Archiv',
  'Arşivde sohbet yok.\nGelen kutusunda bir sohbete uzun basıp "Arşivle"yi seçebilirsiniz.':
      'Keine Chats im Archiv.\nTippe im Posteingang lange auf einen Chat und wähle „Archivieren“.',
  'Yedekleniyor… Fotoğraflar çoksa biraz sürebilir.':
      'Sicherung läuft… Bei vielen Fotos kann das etwas dauern.',
  'Yedek kaydedildi: {messages} mesaj, {files} fotoğraf ({bytes}).':
      'Sicherung gespeichert: {messages, plural, one{# Nachricht} other{# Nachrichten}}, {files, plural, one{# Foto} other{# Fotos}} ({bytes}).',
  'Yedek alınamadı: {error}': 'Sicherung fehlgeschlagen: {error}',
  'bilinmeyen hata': 'unbekannter Fehler',
  'Yedekten geri yüklensin mi?': 'Aus Sicherung wiederherstellen?',
  'Bu telefondaki Mesa mesajları, kişileri ve kuralları yedektekilerle değiştirilir. Telegram ve web servisi girişleri yedekte yoktur; gerekirse yeniden giriş yaparsınız.':
      'Die Nachrichten, Personen und Regeln von Mesa auf diesem Telefon werden durch die aus der Sicherung ersetzt. Anmeldungen bei Telegram und Webdiensten sind nicht in der Sicherung; melde dich bei Bedarf neu an.',
  'Vazgeç': 'Abbrechen',
  'Dosya seç': 'Datei auswählen',
  'Geri yükleniyor…': 'Wird wiederhergestellt…',
  'Geri yüklendi: {messages} mesaj, {files} fotoğraf.':
      'Wiederhergestellt: {messages, plural, one{# Nachricht} other{# Nachrichten}}, {files, plural, one{# Foto} other{# Fotos}}.',
  'Şifre yanlış. Yedeği alırken girdiğiniz şifreyi deneyin.':
      'Falsches Passwort. Versuch es mit dem Passwort, das du beim Sichern eingegeben hast.',
  'Dosya açılamadı: {error}': 'Datei konnte nicht geöffnet werden: {error}',
  'yedek bozuk': 'Sicherung ist beschädigt',
  'Geri yüklenemedi: {error}': 'Wiederherstellung fehlgeschlagen: {error}',
  'Yedek': 'Sicherung',
  'Yedekle': 'Sichern',
  'Mesajlar, kişiler, kurallar ve fotoğraflar; şifreli dosya. Henüz yedek alınmadı.':
      'Nachrichten, Personen, Regeln und Fotos; verschlüsselte Datei. Noch keine Sicherung.',
  'Mesajlar, kişiler, kurallar ve fotoğraflar; şifreli dosya. Son yedek: {when}':
      'Nachrichten, Personen, Regeln und Fotos; verschlüsselte Datei. Letzte Sicherung: {when}',
  'Yedekten geri yükle': 'Aus Sicherung wiederherstellen',
  'Yeni telefonda ya da sıfırlamadan sonra':
      'Auf einem neuen Telefon oder nach dem Zurücksetzen',
  'En az 8 karakter olmalı.': 'Mindestens 8 Zeichen.',
  'Şifreler aynı değil.': 'Die Passwörter stimmen nicht überein.',
  'Yedek şifresi': 'Sicherungspasswort',
  'Yedeğin şifresi': 'Passwort der Sicherung',
  'Bu şifreyi unutursanız yedek açılamaz; kimse kurtaramaz. Bir yere not edin.':
      'Wenn du dieses Passwort vergisst, lässt sich die Sicherung nicht öffnen; niemand kann sie wiederherstellen. Schreib es dir auf.',
  'Şifre': 'Passwort',
  'Göster': 'Anzeigen',
  'Gizle': 'Ausblenden',
  'Şifre (tekrar)': 'Passwort (wiederholen)',
  'Aç': 'Öffnen',
  'Açıldı. Bu sohbetten yeni mesaj gelince yanıtlarınız {appName} açılmadan, doğrudan gider.':
      'Aktiviert. Sobald in diesem Chat eine neue Nachricht kommt, gehen deine Antworten direkt raus, ohne {appName} zu öffnen.',
  'Mesajınız bu sohbete de kaydedildi.':
      'Deine Nachricht wurde auch in diesem Chat gespeichert.',
  'Gönderilmedi': 'Nicht gesendet',
  'Tekrar gönder': 'Erneut senden',
  'Mesaj gönderilemedi': 'Nachricht nicht gesendet',
  'Sil': 'Löschen',
  'Karşı tarafa hiç gitmedi': 'Sie ist nie beim Empfänger angekommen',
  'Kaydedilenlerden çıkar': 'Aus Gespeicherten entfernen',
  'Kaydet': 'Speichern',
  'Tüm uygulamalardan kaydedilenler tek listede':
      'Gespeicherte Nachrichten aus allen Apps in einer Liste',
  'Kopyala': 'Kopieren',
  'Kaydedilenlerden çıkarıldı.': 'Aus Gespeicherten entfernt.',
  'Kaydedildi ⭐': 'Gespeichert ⭐',
  'Kopyalandı.': 'Kopiert.',
  'Yeniden gönderiliyor…': 'Wird erneut gesendet…',
  'Gönderilemedi. Bağlantıyı kontrol edin.':
      'Senden fehlgeschlagen. Prüfe die Verbindung.',
  'Ne zaman gönderilsin?': 'Wann soll sie gesendet werden?',
  '⏰ {when} Telegram\'dan gönderilecek.':
      '⏰ Wird {when} über Telegram gesendet.',
  '⏰ {when} kendiliğinden gönderilecek.': '⏰ Wird {when} automatisch gesendet.',
  '⏰ {when} bildirim gelecek: dokununca {appName} mesaj yazılmış olarak açılır, ➤ ile gönderirsiniz. {viaAppNote}':
      '⏰ Du bekommst {when} eine Benachrichtigung: Ein Tippen öffnet {appName} mit der fertigen Nachricht, du sendest sie mit ➤. {viaAppNote}',
  'O zamana kadar bu sohbetten yeni mesaj gelirse kendiliğinden gider.':
      'Kommt vorher eine neue Nachricht in diesem Chat, wird sie automatisch gesendet.',
  'Planlı mesajlar': 'Geplante Nachrichten',
  'İptal et': 'Abbrechen',
  '{appName} bu sohbet için şu an doğrudan gönderme yolu vermiyor: zamanı gelince bildirime dokunup {appName} içinde gönderirsiniz. {viaAppNote}':
      '{appName} bietet für diesen Chat gerade keinen direkten Sendeweg: Tippe zur geplanten Zeit auf die Benachrichtigung und sende in {appName}. {viaAppNote}',
  'Telegram bağlantısı açık değil.': 'Die Telegram-Verbindung ist nicht offen.',
  '{appName} açılamadı.': '{appName} konnte nicht geöffnet werden.',
  'Gönderiliyor…': 'Wird gesendet…',
  '{kind} gönderiliyor…': '{kind} wird gesendet…',
  '{appName} açıldı; göndermek için orada ➤ düğmesine dokunun.':
      '{appName} wurde geöffnet; tippe dort auf ➤, um zu senden.',
  '{appName} dışarıdan {kind} kabul etmiyor.':
      '{appName} nimmt {kind} nicht von anderen Apps an.',
  'Gönderilemedi.': 'Senden fehlgeschlagen.',
  'Fotoğraf': 'Foto',
  'Video': 'Video',
  'Sesli mesaj': 'Sprachnachricht',
  'Dosya': 'Datei',
  'Planlı mesaj': 'Geplante Nachricht',
  'Zaman seç': 'Zeit wählen',
  'Gönderilecek mesaj': 'Zu sendende Nachricht',
  'Sesli mesaj için mikrofon izni gerekli.':
      'Für Sprachnachrichten wird die Mikrofonberechtigung benötigt.',
  'Kayıt başlatılamadı.': 'Aufnahme konnte nicht gestartet werden.',
  'Kayıt çok kısa.': 'Aufnahme ist zu kurz.',
  'Uygulama açılamadı.': 'App konnte nicht geöffnet werden.',
  'Siz': 'Du',
  'Hazır yanıtlar': 'Schnellantworten',
  'Gizli okuma açık: Telegram\'da "görüldü" ve "yazıyor" gitmez.':
      'Unsichtbares Lesen ist an: Telegram sendet weder „gelesen“ noch „schreibt“.',
  'Burada okumak {name}\'ta "görüldü" göndermez. Yanıt verirseniz gider.':
      'Hier zu lesen sendet in {name} kein „gelesen“. Es wird gesendet, wenn du antwortest.',
  'Görüldü gönderilmez': '„Gelesen“ wird nicht gesendet',
  'Medya': 'Medien',
  '{name} uygulamasında aç': 'In {name} öffnen',
  'Bu sohbette henüz mesaj yok.':
      'In diesem Chat gibt es noch keine Nachrichten.',
  '{count} planlı mesaj · ilki {when}':
      '{count, plural, one{# geplante Nachricht} other{# geplante Nachrichten}} · erste {when}',
  'Mesajınız {name}\'ta hazır açılır; orada ➤ ile gönderin.':
      'Deine Nachricht öffnet sich fertig in {name}; sende sie dort mit ➤.',
  'Klavye': 'Tastatur',
  'Emoji': 'Emoji',
  '{appName} ile yaz': 'In {appName} schreiben',
  'Mesaj yaz': 'Nachricht schreiben',
  'Çıkartma ve GIF': 'Sticker und GIFs',
  'Fotoğraf, video, dosya': 'Foto, Video, Datei',
  'Zamanla': 'Planen',
  'Kamera': 'Kamera',
  'Sesli mesajı gönder': 'Sprachnachricht senden',
  'Gönder (basılı tutun: zamanla)': 'Senden (gedrückt halten: planen)',
  'Web servislerine yanıt, servisin kendi sayfasından yazılır.':
      'Antworten an Webdienste schreibst du auf der Seite des Dienstes.',
  '{name} telefonda kurulu değil.':
      '{name} ist auf diesem Telefon nicht installiert.',
  '{name} sayfasında yanıtla': 'Auf der {name}-Seite antworten',
  'çevrimiçi': 'online',
  'son görülme {seen}': 'zuletzt online {seen}',
  'bugün {time}': 'heute um {time}',
  'dün {time}': 'gestern um {time}',
  'Kaydı sil': 'Aufnahme löschen',
  '◀ İptal için kaydırın': '◀ Zum Abbrechen wischen',
  'Sesli mesaj: dokunun ya da basılı tutun':
      'Sprachnachricht: tippen oder gedrückt halten',
  'Galeri': 'Galerie',
  'Açıklama ekle': 'Beschreibung hinzufügen',
  '{appName} hazır açılır; orada gönderin':
      'Öffnet sich fertig in {appName}; dort senden',
  'Gönder': 'Senden',
  'Gönderilemedi': 'Nicht gesendet',
  'Gönderiliyor': 'Wird gesendet',
  'Görüldü': 'Gelesen',
  'Gönderildi': 'Gesendet',
  'Burada okumak {appName}\'ta "görüldü" göndermez. Yanıt verirseniz gider.':
      'Hier zu lesen sendet in {appName} kein „gelesen“. Es wird gesendet, wenn du antwortest.',
  'Anladım': 'Verstanden',
  'Oynat': 'Abspielen',
  'Sesli mesaj indirilemedi.': 'Sprachnachricht konnte nicht geladen werden.',
  'Duraklat': 'Pause',
  'Dinle': 'Anhören',
  '{appName}\'ta aç': 'In {appName} öffnen',
  'Yanıt:': 'Antwort:',
  'Yükleniyor %{percent}': 'Wird hochgeladen {percent} %',
  'Şu an gönderince {appName} açılıyor. Açarsanız bu sohbetten mesaj geldiğinde yanıtlarınız doğrudan gider.':
      'Gerade öffnet sich beim Senden {appName}. Aktiviere das, dann gehen deine Antworten direkt raus, sobald eine Nachricht aus diesem Chat kommt.',
  'Kapat': 'Schließen',
  'Hatırlatma': 'Erinnerung',
  'Sabitlendi': 'Angeheftet',
  'Önemli': 'Wichtig',
  'Sabitlemeyi kaldır': 'Loslösen',
  'Sabitle': 'Anheften',
  'Sonra hatırlat': 'Später erinnern',
  'Arşivden çıkar': 'Aus Archiv holen',
  'Arşivle': 'Archivieren',
  'Kişiyle birleştir': 'Mit Person zusammenführen',
  'Aynı kişinin başka uygulamadaki sohbetiyle tek yerde':
      'Den Chat dieser Person in einer anderen App an einem Ort',
  '{name} kişisinden ayır': 'Von {name} trennen',
  'Kişi': 'Person',
  'Ne zaman hatırlatılsın?': 'Wann sollen wir dich erinnern?',
  '⏰ {when} hatırlatılacak': '⏰ Erinnerung {when}',
  '{target}: {name} ve {name2} sohbetleri birleşti':
      '{target}: Chats von {name} und {name2} zusammengeführt',
  '"{title}" silinsin mi?': '„{title}“ löschen?',
  'Sohbet ve mesajları yalnızca Mesa\'dan silinir; {name} uygulamasındaki sohbete dokunulmaz.':
      'Der Chat und seine Nachrichten werden nur aus Mesa gelöscht; der Chat in {name} bleibt unberührt.',
  '{title} ile birleştir': 'Mit {title} zusammenführen',
  'Aynı kişinin başka uygulamadaki sohbetini seçin. Mesajlar tek yerde görünür; istediğiniz zaman ayırabilirsiniz.':
      'Wähle den Chat dieser Person in einer anderen App. Die Nachrichten erscheinen an einem Ort; du kannst sie jederzeit wieder trennen.',
  'Ara': 'Suchen',
  'Adını değiştir': 'Umbenennen',
  '{name} sohbetini ayır': 'Den Chat {name} trennen',
  'Kişinin adı': 'Name der Person',
  '1 saat sonra': 'In 1 Stunde',
  '3 saat sonra': 'In 3 Stunden',
  'Bu akşam': 'Heute Abend',
  'Yarın sabah': 'Morgen früh',
  'Tarih ve saat seç': 'Datum und Uhrzeit wählen',
  'Yanıt bekliyor · {count}': 'Warten auf Antwort · {count}',
  'Ertelenen sohbetler': 'Zurückgestellte Chats',
  'Şimdi göster': 'Jetzt anzeigen',
  'Sohbetler': 'Chats',
  'Servisler': 'Dienste',
  'Kurallar': 'Regeln',
  'Ayarlar': 'Einstellungen',
  'Yanıt gerekmez': 'Keine Antwort nötig',
  'Yeni mesaj gelene kadar listeden kalkar':
      'Verschwindet aus der Liste, bis eine neue Nachricht kommt',
  'Birleşik bildirimler açık. Yeni mesajlar artık Mesa bildirimiyle gelecek.':
      'Einheitliche Benachrichtigungen sind an. Neue Nachrichten kommen jetzt als Benachrichtigungen von Mesa.',
  'Mesajlar': 'Nachrichten',
  'Hepsi okundu': 'Alles gelesen',
  '{unreadTotal} okunmamış': '{unreadTotal} ungelesen',
  'Haftalık özet': 'Wochenübersicht',
  'Kaydedilenler': 'Gespeichert',
  'Diğer': 'Mehr',
  'Tümünü okundu say': 'Alle als gelesen markieren',
  'Arşiv ({archivedCount})': 'Archiv ({archivedCount})',
  'Tümü': 'Alle',
  'Ekle': 'Hinzufügen',
  'Servis ekle': 'Dienst hinzufügen',
  '{count} ertelenmiş sohbet':
      '{count, plural, one{# zurückgestellter Chat} other{# zurückgestellte Chats}}',
  'Zamanı gelince hatırlatılacak': 'Du wirst zur passenden Zeit erinnert',
  '{name} artık tek satırda: {name2} ve {name3} mesajları birlikte.':
      '{name} ist jetzt eine Zeile: Nachrichten aus {name2} und {name3} zusammen.',
  'Tüm mesajlarda ara': 'Alle Nachrichten durchsuchen',
  'Henüz mesaj yok': 'Noch keine Nachrichten',
  'WhatsApp, Instagram, Discord gibi uygulamalardan yeni mesaj geldikçe burada toplanır; eski mesajlar görünmez. Telegram\'ı Ayarlar\'dan bağlarsanız geçmişi de gelir.':
      'Neue Nachrichten aus Apps wie WhatsApp, Instagram und Discord sammeln sich hier, sobald sie eintreffen; ältere erscheinen nicht. Verbinde Telegram in den Einstellungen, um auch den Verlauf zu bekommen.',
  'Bildirimleri birleştir': 'Benachrichtigungen vereinheitlichen',
  'Her uygulamanın ayrı bildirimi yerine tek tip Mesa bildirimleri: kişi fotoğrafı, doğrudan yanıt ve kurallarınla birlikte.':
      'Eine Art Mesa-Benachrichtigung statt einer eigenen für jede App: mit Kontaktfoto, direkter Antwort und deinen Regeln.',
  'Bildirim servisi çalışmıyor': 'Der Benachrichtigungsdienst läuft nicht',
  'Yeni mesajlar şu an yakalanmıyor. Xiaomi uygulamayı arka planda engelliyor: Otomatik başlatma iznini açın ve uygulama ayarlarında pil tasarrufunu "Kısıtlama yok" yapın. Ardından "Yeniden bağla"ya dokunun.':
      'Neue Nachrichten werden gerade nicht erfasst. Xiaomi blockiert die App im Hintergrund: Aktiviere die Berechtigung „Autostart“ und stelle die Akkuoptimierung in den App-Einstellungen auf „Keine Einschränkungen“. Tippe dann auf „Neu verbinden“.',
  'Yeni mesajlar şu an yakalanmıyor. Telefon uygulamayı arka planda kapatmış olabilir: uygulama ayarlarında pil kısıtlamasını kaldırın, ardından "Yeniden bağla"ya dokunun.':
      'Neue Nachrichten werden gerade nicht erfasst. Das Telefon hat die App vielleicht im Hintergrund beendet: Entferne die Akkubeschränkung in den App-Einstellungen und tippe dann auf „Neu verbinden“.',
  'Otomatik başlatma': 'Autostart',
  'Uygulama ayarları': 'App-Einstellungen',
  'Yeniden bağla': 'Neu verbinden',
  'Aynı kişi mi?': 'Dieselbe Person?',
  'Telefon numaraları aynı. Birleştirirseniz mesajları tek satırda, tek zaman çizgisinde görürsünüz.':
      'Die Telefonnummern stimmen überein. Führst du sie zusammen, siehst du die Nachrichten in einer Zeile und einem Verlauf.',
  'Adları aynı. Birleştirirseniz mesajları tek satırda, tek zaman çizgisinde görürsünüz.':
      'Die Namen stimmen überein. Führst du sie zusammen, siehst du die Nachrichten in einer Zeile und einem Verlauf.',
  'Farklı kişiler': 'Verschiedene Personen',
  'Birleştir': 'Zusammenführen',
  'Uygulamanın dili': 'App-Sprache',
  'Telefonun dili': 'Sprache des Telefons',
  'Dil': 'Sprache',
  'Telefonun dili ({language})': 'Sprache des Telefons ({language})',
  'Mesa\'yı açmak için kimliğinizi doğrulayın':
      'Bestätige deine Identität, um Mesa zu öffnen',
  'Mesa kilitli': 'Mesa ist gesperrt',
  'Kilidi aç': 'Entsperren',
  'Fotoğraflar': 'Fotos',
  'Videolar': 'Videos',
  'Ocak': 'Januar',
  'Şubat': 'Februar',
  'Mart': 'März',
  'Nisan': 'April',
  'Mayıs': 'Mai',
  'Haziran': 'Juni',
  'Temmuz': 'Juli',
  'Ağustos': 'August',
  'Eylül': 'September',
  'Ekim': 'Oktober',
  'Kasım': 'November',
  'Aralık': 'Dezember',
  'Henüz fotoğraf ya da video yok': 'Noch keine Fotos oder Videos',
  'Bildiriminde önizlemesi gelen fotoğraflar ve Telegram medyası burada toplanır.':
      'Fotos mit Vorschau in Benachrichtigungen und Telegram-Medien sammeln sich hier.',
  'Tam boyut': 'Originalgröße',
  'Medya açılamadı.': 'Medien konnten nicht geöffnet werden.',
  'Görsel açılamadı.': 'Bild konnte nicht geöffnet werden.',
  'İndiriliyor…': 'Wird geladen…',
  'Açılıyor…': 'Wird geöffnet…',
  'İndiriliyor… %{percent}': 'Wird geladen… {percent} %',
  'Sesi kapat': 'Ton aus',
  'Sesi aç': 'Ton an',
  'Tam ekrandan çık': 'Vollbild beenden',
  'Tam ekran': 'Vollbild',
  'Başlangıç saati': 'Startzeit',
  'Bitiş saati': 'Endzeit',
  'En az bir gün seçin.': 'Wähle mindestens einen Tag.',
  'Kural silinsin mi?': 'Regel löschen?',
  '"{name}" kalıcı olarak silinecek.': '„{name}“ wird endgültig gelöscht.',
  'Yeni kural': 'Neue Regel',
  'Kuralı düzenle': 'Regel bearbeiten',
  'Kural adı': 'Name der Regel',
  'Ne yapılsın?': 'Was soll passieren?',
  'Mesaja, geldiği uygulama üzerinden otomatik cevap verilir.':
      'Die Nachricht wird über die App, aus der sie kam, automatisch beantwortet.',
  'Mesajlar kaydedilir ama okunmamış sayılmaz.':
      'Nachrichten werden gespeichert, zählen aber nicht als ungelesen.',
  'Sohbet, açılana kadar listenin en üstünde yıldızla durur.':
      'Der Chat bleibt mit einem Stern oben in der Liste, bis du ihn öffnest.',
  'Yanıt metni': 'Antworttext',
  'Şu an müsait değilim, sonra yazacağım.':
      'Ich kann gerade nicht, ich schreibe später.',
  'Otomatik yanıt için bir metin yazın':
      'Schreib einen Text für die automatische Antwort',
  'Aynı sohbete tekrar yanıt için bekle':
      'Warten, bevor im selben Chat erneut geantwortet wird',
  'Hangi mesajlarda?': 'Bei welchen Nachrichten?',
  'Uygulama seçilmedi: tüm uygulamalar': 'Keine App gewählt: alle Apps',
  'Yalnızca seçilen uygulamalar': 'Nur gewählte Apps',
  'Kimden (isteğe bağlı)': 'Von (optional)',
  'Sohbet ya da kişi adında geçen ifade': 'Text im Chat- oder Personennamen',
  'Anahtar kelimeler (isteğe bağlı)': 'Stichwörter (optional)',
  'acil, toplantı, fatura': 'dringend, Besprechung, Rechnung',
  'Virgülle ayırın; herhangi biri geçerse kural çalışır':
      'Mit Kommas trennen; die Regel greift, wenn eines davon vorkommt',
  'Grup sohbetlerinde de çalışsın': 'Auch in Gruppenchats',
  'Gruptaki herkes otomatik yanıtı görür.':
      'Alle in der Gruppe sehen die automatische Antwort.',
  'Ne zaman?': 'Wann?',
  'Yalnızca belirli saatlerde': 'Nur zu bestimmten Zeiten',
  'Gün boyu': 'Ganztägig',
  'Başlangıç {from}': 'Beginn {from}',
  'Bitiş {to}': 'Ende {to}',
  'Gece yarısını aşar: {from}–{to} (ertesi gün)':
      'Über Mitternacht: {from}–{to} (nächster Tag)',
  'Koşul yok: bu kural her yeni mesaja yanıt verir (bekleme süresi ve saatlik sınırla).':
      'Keine Bedingungen: Diese Regel antwortet auf jede neue Nachricht (mit Wartezeit und Stundenlimit).',
  'Kurallar nasıl çalışır?': 'Wie funktionieren Regeln?',
  'Kurallar uygulama kapalıyken de, yeni mesaj gelir gelmez çalışır.\n\nOtomatik yanıt güvenliği: aynı anda gelen mesajlara tek yanıt; aynı sohbete bekleme süresi dolmadan tekrar yanıt yok; tüm sohbetlerde saatte en fazla 20 yanıt.\n\nYanıt, kaynak uygulamanın bildirimi üzerinden (Telegram\'da doğrudan) gider; bildirim yoksa gönderilmez.':
      'Regeln greifen, sobald eine neue Nachricht eintrifft, auch wenn die App geschlossen ist.\n\nSicherheit bei automatischen Antworten: eine einzige Antwort auf gleichzeitig eintreffende Nachrichten; keine erneute Antwort im selben Chat, bevor die Wartezeit abgelaufen ist; höchstens 20 Antworten pro Stunde über alle Chats.\n\nDie Antwort geht über die Benachrichtigung der Quell-App (bei Telegram direkt); ohne Benachrichtigung wird sie nicht gesendet.',
  'Otomatik yanıt, sessize alma, önemli işaretleme':
      'Automatische Antwort, stummschalten, als wichtig markieren',
  '{active} etkin kural':
      '{active, plural, one{# aktive Regel} other{# aktive Regeln}}',
  'Kural ekle': 'Regel hinzufügen',
  'Kurallarınız': 'Deine Regeln',
  'Son 7 günde {recentFires} kez çalıştı':
      'In den letzten 7 Tagen {recentFires, plural, one{einmal} other{#-mal}} ausgeführt',
  'Henüz kural yok': 'Noch keine Regeln',
  'Yukarıdaki hazır kurallardan birine dokunun ya da kendiniz ekleyin.':
      'Tippe oben auf eine der fertigen Regeln oder füge eine eigene hinzu.',
  'WhatsApp\'ta "acil" geçen mesajları önemli işaretle':
      'WhatsApp-Nachrichten mit „dringend“ als wichtig markieren',
  'İş grubunu sessize al': 'Arbeitsgruppe stummschalten',
  'Gece 23:00–08:00 arası "Sabah yazarım" diye yanıtla':
      'Zwischen 23:00 und 08:00 mit „Ich schreibe morgen früh“ antworten',
  'Gece modu': 'Nachtmodus',
  '23:00–08:00 otomatik yanıt': 'Automatische Antwort 23:00–08:00',
  'Gece otomatik yanıt': 'Nächtliche automatische Antwort',
  'Şu an uyuyorum, sabah dönerim 🌙':
      'Ich schlafe gerade, ich melde mich morgen früh 🌙',
  'Meşgulüm': 'Beschäftigt',
  'Herkese kısa yanıt': 'Kurze Antwort an alle',
  'Şu an müsait değilim, birazdan yazarım.':
      'Ich kann gerade nicht, ich schreibe gleich.',
  'Mesai dışı': 'Nach Feierabend',
  'Hafta içi 18:00–09:00': 'Werktags 18:00–09:00',
  'Mesai dışı yanıt': 'Antwort nach Feierabend',
  'Mesai saatleri dışındayım, yarın dönüş yapacağım.':
      'Ich bin außerhalb meiner Arbeitszeit und melde mich morgen.',
  'Acil mesajlar': 'Dringende Nachrichten',
  '"acil", "hemen" geçenleri öne çıkar':
      'Hebt Nachrichten mit „dringend“, „sofort“ hervor',
  'acil': 'dringend',
  'hemen': 'sofort',
  'önemli': 'wichtig',
  'ara beni': 'ruf mich an',
  'Hazır kurallar': 'Fertige Regeln',
  'Mesajlarda ara': 'Nachrichten durchsuchen',
  'Bütün uygulamalardaki mesajlarda arar. En az iki harf yazın.':
      'Durchsucht die Nachrichten aller Apps. Gib mindestens zwei Buchstaben ein.',
  'Sonuç bulunamadı.': 'Keine Ergebnisse.',
  '{name} açılamadı.': '{name} konnte nicht geöffnet werden.',
  'Servisler nasıl çalışır?': 'Wie funktionieren Dienste?',
  'Her servis kendi resmi web sitesiyle, uygulamanın içindeki tarayıcıda açılır. Giriş bilgileriniz yalnızca bu telefonda kalır; Mesa yalnızca o servisin sunucusuyla konuşur.\n\nArka planda bağlı servisler uygulama kapalıyken de yeni mesajları bildirir ve mesajlar Sohbetler\'e düşer. Bunun için telefonun pil ayarında Mesa\'ya "Kısıtlama yok" verilmelidir. Her açık servis pil ve bellek harcar.\n\nInstagram, X ve LinkedIn gibi bazı siteler açıkken mesaj bildirimi göndermez; onlarda okunmamış sayısı arttığında haber verilir.\n\n"Google ile giriş" bu sayfalarda çalışmaz; e-posta ve şifreyle girin.':
      'Jeder Dienst öffnet sich mit seiner offiziellen Website im Browser der App. Deine Anmeldedaten bleiben nur auf diesem Telefon; Mesa spricht nur mit dem Server dieses Dienstes.\n\nIm Hintergrund verbundene Dienste melden neue Nachrichten auch bei geschlossener App, und die Nachrichten landen in den Chats. Dafür muss Mesa in den Akkueinstellungen des Telefons auf „Keine Einschränkungen“ stehen. Jeder offene Dienst braucht Akku und Speicher.\n\nManche Seiten wie Instagram, X und LinkedIn senden keine Nachrichtenbenachrichtigungen, solange sie offen sind; bei ihnen wirst du benachrichtigt, wenn die Zahl der ungelesenen steigt.\n\n„Mit Google anmelden“ funktioniert auf diesen Seiten nicht; melde dich mit E-Mail und Passwort an.',
  '{unread} okunmamış': '{unread} ungelesen',
  'Tüm uygulamalar tek yerde': 'Alle Apps an einem Ort',
  'Uygulamalar': 'Apps',
  'Web servisleri': 'Webdienste',
  '{name} ayarları': 'Einstellungen für {name}',
  'Okunmamış var': 'Ungelesene Nachrichten',
  'Bildirim kapalı': 'Benachrichtigungen aus',
  'Arka planda bağlı': 'Im Hintergrund verbunden',
  'Yalnızca açıkken': 'Nur solange geöffnet',
  'Henüz web servisi yok': 'Noch keine Webdienste',
  'Telefonda uygulaması olmayan servisleri resmi web sürümleriyle buraya ekleyin. Yeni mesajlar Sohbetler\'e ve bildirimlere düşer.':
      'Füge hier Dienste ohne App auf diesem Telefon mit ihrer offiziellen Webversion hinzu. Neue Nachrichten landen in den Chats und Benachrichtigungen.',
  'Başka bir site': 'Andere Website',
  'Adresini yazarak, ör. vk.com/im':
      'Durch Eingabe der Adresse, z. B. vk.com/im',
  'KakaoTalk, Viber, LINE ve Signal\'in web sürümü yok. Uygulamaları telefona kurulursa mesajları bildirimlerden otomatik toplanır.':
      'KakaoTalk, Viber, LINE und Signal haben keine Webversion. Sind ihre Apps auf dem Telefon installiert, werden ihre Nachrichten automatisch aus den Benachrichtigungen gesammelt.',
  'Ekli · ikinci hesap eklenir': 'Hinzugefügt · fügt ein zweites Konto hinzu',
  'Uygulaması kurulu, bildirimleri zaten geliyor':
      'App ist installiert, ihre Benachrichtigungen kommen bereits',
  'https ile açılan geçerli bir site adresi yazın.':
      'Gib eine gültige Website-Adresse ein, die mit https beginnt.',
  'Ad': 'Name',
  'Adres': 'Adresse',
  '{name} oturumu kapatılsın mı?': 'Von {name} abmelden?',
  'Bu servisin giriş bilgileri ve site verileri telefondan silinir. Yeniden giriş yapmanız gerekir.':
      'Die Anmeldedaten und Websitedaten dieses Dienstes werden vom Telefon gelöscht. Du musst dich neu anmelden.',
  'Oturumu kapat': 'Abmelden',
  '{name} kaldırılsın mı?': '{name} entfernen?',
  'Oturum ve site verileri telefondan silinir. Sohbetler\'deki eski mesajlar kalır.':
      'Sitzung und Websitedaten werden vom Telefon gelöscht. Alte Nachrichten in den Chats bleiben.',
  'Kaldır': 'Entfernen',
  'Arka planda bağlı kalsın': 'Im Hintergrund verbunden bleiben',
  'Uygulama kapalıyken de yeni mesajlar bildirilir; pil kullanımı artar':
      'Neue Nachrichten werden auch bei geschlossener App gemeldet; verbraucht mehr Akku',
  'Bildirimler': 'Benachrichtigungen',
  'Yeni mesajlar Sohbetler\'e ve bildirimlere':
      'Neue Nachrichten in Chats und Benachrichtigungen',
  'Videolar kendiliğinden oynasın': 'Videos automatisch abspielen',
  'Kapalıyken videolar dokununca oynar; sayfa daha akıcı olur':
      'Wenn aus, starten Videos erst beim Antippen; die Seite läuft flüssiger',
  'Eski mesajlar silinsin mi?': 'Alte Nachrichten löschen?',
  '{days} öncesine ait mesajlar ve görselleri Mesa\'dan kalıcı olarak silinecek. Kaynak uygulamalardaki mesajlara dokunulmaz.':
      'Nachrichten und Bilder, die älter als {days} sind, werden endgültig aus Mesa gelöscht. Nachrichten in den Quell-Apps bleiben unberührt.',
  'Seçilen uygulamalarda yanıt, Mesa yeniden başlasa da doğrudan gider':
      'In den gewählten Apps gehen Antworten direkt raus, auch wenn Mesa neu startet',
  'Kendi bildirimi de kalsın': 'Eigene Benachrichtigung auch behalten',
  'Seçtiğiniz uygulamanın bildirimi çubuktan kaldırılmaz. Bildirim orada durdukça, Mesa yeniden başlasa da (güncelleme, telefonun yeniden açılması) o sohbete yanıt ve planlı mesaj uygulamaya geçmeden gider. Aynı mesaj için iki bildirim görürsünüz; Mesa\'nınki sessiz gelir.':
      'Die Benachrichtigung der gewählten App wird nicht aus der Statusleiste entfernt. Solange sie dort bleibt, gehen Antworten und geplante Nachrichten an diesen Chat direkt raus, ohne die App zu öffnen, auch wenn Mesa neu startet (Update, Neustart des Telefons). Du siehst zwei Benachrichtigungen für dieselbe Nachricht; die von Mesa kommt lautlos.',
  'Ana ekranda boş bir yere basılı tutun → Bileşenler (Widget) → Mesa\'yı sürükleyip bırakın.':
      'Tippe lange auf eine freie Stelle des Startbildschirms → Widgets → ziehe Mesa an die gewünschte Stelle.',
  'Birleşik bildirimler': 'Einheitliche Benachrichtigungen',
  'Uygulamaların ayrı bildirimleri yerine kişi fotoğraflı, yanıtlanabilen tek tip bildirim':
      'Eine Art Benachrichtigung mit Kontaktfoto, auf die du antworten kannst, statt einzelner Benachrichtigungen jeder App',
  'Önemli mesajlarda bildirim': 'Bei wichtigen Nachrichten benachrichtigen',
  '"Önemli işaretle" kuralına uyunca, sessizdekiler dahil':
      'Wenn die Regel „Als wichtig markieren“ greift, auch bei stummgeschalteten',
  'Ana ekran': 'Startbildschirm',
  'Ana ekran bileşeni': 'Startbildschirm-Widget',
  'Okunmamışlar ve yanıt bekleyenler, uygulamayı açmadan':
      'Ungelesene und wartende Antworten, ohne die App zu öffnen',
  'Bağlantılar': 'Verbindungen',
  'Doğrudan bağlantı: sessiz gruplar ve geçmiş':
      'Direkte Verbindung: stummgeschaltete Gruppen und Verlauf',
  'Telegram\'da gizli okuma': 'Unsichtbares Lesen in Telegram',
  'Okuduğunuzda "görüldü", yazarken "yazıyor" gitmez':
      'Kein „gelesen“ beim Lesen, kein „schreibt“ beim Schreiben',
  'Telegram kanallarını gösterme': 'Telegram-Kanäle ausblenden',
  'Kişiler ve gruplar gelmeye devam eder':
      'Personen und Gruppen kommen weiterhin',
  'Okunan uygulamalar': 'Erfasste Apps',
  'Gizlilik': 'Datenschutz',
  'Görmeden okuma': 'Ungesehen lesen',
  'WhatsApp, Instagram ve diğerlerinde mesajı burada okumak karşı tarafa "görüldü" göndermez. Yanıt verirseniz gider.':
      'Liest du hier eine Nachricht aus WhatsApp, Instagram und anderen, erhält der Absender kein „gelesen“. Es wird gesendet, wenn du antwortest.',
  'Silinen mesajlar korunur': 'Gelöschte Nachrichten bleiben erhalten',
  'Gönderen mesajı silse de metni burada "silindi" etiketiyle kalır.':
      'Auch wenn der Absender eine Nachricht löscht, bleibt ihr Text hier mit dem Hinweis „gelöscht“.',
  'Mesajları sakla': 'Nachrichten behalten',
  '{retentionDays} sonra silinir': 'Gelöscht nach {retentionDays}',
  'Yazma': 'Schreiben',
  '{count} yanıt': '{count, plural, one{# Antwort} other{# Antworten}}',
  'Telefonda ekran kilidi ya da parmak izi tanımlı değil.':
      'Auf diesem Telefon ist keine Displaysperre und kein Fingerabdruck eingerichtet.',
  'Uygulama kilidini açmak için doğrulayın':
      'Bestätigen, um die App-Sperre einzuschalten',
  'Uygulama kilidi': 'App-Sperre',
  'Parmak izi, yüz tanıma ya da ekran kilidi':
      'Fingerabdruck, Gesichtserkennung oder Displaysperre',
  'Yeni hazır yanıt': 'Neue Schnellantwort',
  'Hazır yanıt yok.': 'Keine Schnellantworten.',
  'Düzelt': 'Beheben',
  'Sistem durumu · her şey hazır': 'Systemstatus · alles bereit',
  'Sistem durumu · {problems} ayar eksik':
      'Systemstatus · {problems, plural, one{# Einstellung fehlt} other{# Einstellungen fehlen}}',
  'Bildirim erişimi': 'Benachrichtigungszugriff',
  'Mesajlar yakalanıyor': 'Nachrichten werden erfasst',
  'İzin var ama sistem servisi bağlamadı':
      'Berechtigung erteilt, aber das System hat den Dienst nicht verbunden',
  'Mesajları okumak için gerekli': 'Nötig, um Nachrichten zu lesen',
  'Bağla': 'Verbinden',
  'İzin ver': 'Erlauben',
  'Bildirim izni': 'Benachrichtigungsberechtigung',
  'Yeni mesajlar bildirilir': 'Neue Nachrichten werden gemeldet',
  'Kapalıysa yeni mesaj bildirimi görmezsiniz':
      'Wenn aus, siehst du keine Benachrichtigungen zu neuen Nachrichten',
  'Pil kısıtlaması yok': 'Keine Akkubeschränkung',
  'Arka planda kapatılmaz': 'Wird im Hintergrund nicht beendet',
  'Telefon uygulamayı arka planda kapatıp mesajları geciktirebilir':
      'Das Telefon kann die App im Hintergrund beenden und Nachrichten verzögern',
  'Otomatik başlatma (Xiaomi)': 'Autostart (Xiaomi)',
  'Açık olmalı; telefon yeniden başlayınca da çalışsın':
      'Muss an sein, damit es auch nach einem Neustart läuft',
  'Kontrol et': 'Prüfen',
  'Mikrofon': 'Mikrofon',
  'Sesli mesaj kaydedilebilir': 'Sprachnachrichten können aufgenommen werden',
  'Yalnızca sesli mesaj için; ilk kayıtta sorulur':
      'Nur für Sprachnachrichten; wird bei der ersten Aufnahme abgefragt',
  'Tüm mesajlar tek tip, buradan yanıtlanabilen bildirimle':
      'Alle Nachrichten mit einer Art Benachrichtigung, auf die du hier antworten kannst',
  'Kapalıysa yeni mesajları fark etmezsiniz':
      'Wenn aus, bemerkst du neue Nachrichten nicht',
  'Pil kısıtlamasını kaldır': 'Akkubeschränkung entfernen',
  'Arka planda kapatılmasın, mesajlar gecikmesin':
      'Damit sie im Hintergrund nicht beendet wird und Nachrichten nicht verspätet kommen',
  'Telefon yeniden açılınca da çalışsın':
      'Damit sie auch nach einem Neustart läuft',
  'Son uygulamalarda kilitle': 'In „Letzte Apps“ sperren',
  'Son uygulamalarda karta basılı tutup kilide dokunun; kilitsizken kaydırınca kapanıyor':
      'Halte in „Letzte Apps“ die Karte gedrückt und tippe auf das Schloss; ungesperrt wird die App beim Wegwischen beendet',
  'Yaptım': 'Erledigt',
  'WhatsApp\'a geçmeden yanıt': 'Antworten, ohne zu WhatsApp zu wechseln',
  'Uygulama yeniden başlasa da yanıtlar doğrudan gitsin':
      'Antworten gehen direkt raus, auch wenn die App neu startet',
  'Kurulumu tamamla · {done}/{count}':
      'Einrichtung abschließen · {done}/{count}',
  'Mesajlar eksiksiz ve gecikmeden gelsin':
      'Damit Nachrichten vollständig und ohne Verzögerung ankommen',
  'Sonra': 'Später',
  'Telegram\'ı bağla · isteğe bağlı': 'Telegram verbinden · optional',
  'Sessiz gruplar ve geçmiş de gelsin':
      'Auch stummgeschaltete Gruppen und Verlauf erhalten',
  'Daha az göster': 'Weniger anzeigen',
  '{pending} adım daha':
      '{pending, plural, one{noch # Schritt} other{noch # Schritte}}',
  'İsteğe bağlı adımlar': 'Optionale Schritte',
  'Henüz kaydedilen mesaj yok': 'Noch keine gespeicherten Nachrichten',
  'Bir mesaja basılı tutup "Kaydet"e dokunun. Adres, kod, tarih gibi önemli mesajlar hangi uygulamadan gelirse gelsin burada toplanır.':
      'Tippe lange auf eine Nachricht und dann auf „Speichern“. Wichtige Nachrichten wie Adressen, Codes und Termine sammeln sich hier, egal aus welcher App.',
  'Fotoğraflar ve profil resimleri': 'Fotos und Profilbilder',
  'Telegram önbelleği': 'Telegram-Cache',
  'Geçici dosyalar': 'Temporäre Dateien',
  'Önbellek temizlensin mi?': 'Cache leeren?',
  'Telegram\'da 7 gündür açılmamış fotoğraf ve videolar, web servislerinin önbelleği ve geçici dosyalar silinir. Mesajlar, kişiler ve oturumlar silinmez; Telegram medyası açınca yeniden iner.':
      'Telegram-Fotos und -Videos, die seit 7 Tagen nicht geöffnet wurden, der Cache der Webdienste und temporäre Dateien werden gelöscht. Nachrichten, Personen und Sitzungen werden nicht gelöscht; Telegram-Medien werden beim Öffnen neu geladen.',
  'Temizle': 'Leeren',
  '{freed} yer açıldı.': '{freed} freigegeben.',
  'Temizlenecek önbellek yoktu.': 'Es gab keinen Cache zum Leeren.',
  'Eski mesajları silmek için: saklama süresi.':
      'Alte Nachrichten löschen: Aufbewahrungsdauer.',
  'Önbelleği temizle': 'Cache leeren',
  'Günlere göre': 'Nach Tagen',
  'En çok yazıştıkların': 'Mit wem du am meisten schreibst',
  '{count} mesaj · {name}':
      '{count, plural, one{# Nachricht} other{# Nachrichten}} · {name}',
  'Son 7 gün': 'Letzte 7 Tage',
  '{total} mesaj': '{total, plural, one{# Nachricht} other{# Nachrichten}}',
  '{incoming} gelen': '{incoming} empfangen',
  '{outgoing} giden': '{outgoing} gesendet',
  '{people} kişi': '{people, plural, one{# Person} other{# Personen}}',
  '%{percent}': '{percent} %',
  'En yoğun saatin {hour}:00': 'Deine aktivste Stunde ist {hour}:00',
  'Gelen her 10 mesaja {ratio} yanıt':
      '{ratio} Antworten auf 10 empfangene Nachrichten',
  'Gönderenin silip sende kalan {deleted} mesaj':
      '{deleted, plural, one{# Nachricht, die der Absender gelöscht hat, ist bei dir geblieben} other{# Nachrichten, die Absender gelöscht haben, sind bei dir geblieben}}',
  'Bilgiler': 'Fakten',
  'Çıkartmalar': 'Sticker',
  'Bu bölümde çıkartma yok.': 'In diesem Bereich gibt es keine Sticker.',
  'GIF ara (boşsa kaydedilenler)': 'GIFs suchen (leer: gespeicherte)',
  'Kaydedilmiş GIF yok. Yukarıdan arayabilirsiniz.':
      'Keine gespeicherten GIFs. Du kannst oben suchen.',
  'GIF bulunamadı.': 'Keine GIFs gefunden.',
  'Telegram bağlantısı kapatılsın mı?': 'Telegram-Verbindung trennen?',
  'Bu cihazın oturumu Telegram\'dan çıkarılır. Daha önce alınan mesajlar Mesa\'da kalır.':
      'Die Sitzung dieses Geräts wird aus Telegram entfernt. Bereits empfangene Nachrichten bleiben in Mesa.',
  'Çıkış yap': 'Abmelden',
  'Telegram bağlantısı': 'Telegram-Verbindung',
  'Bu derlemede Telegram uygulama kimliği yok. my.telegram.org → "API development tools" bölümünden api_id ve api_hash alınıp android/local.properties dosyasına telegram.apiId ve telegram.apiHash olarak yazılmalı, ardından uygulama yeniden derlenmeli.':
      'Dieser Build hat keine Telegram-App-ID. Hole dir unter my.telegram.org → „API development tools“ eine api_id und einen api_hash, trage sie in android/local.properties als telegram.apiId und telegram.apiHash ein und baue die App neu.',
  '+90 5xx xxx xx xx': '+49 15x xxxxxxxx',
  'Devam': 'Weiter',
  'Telegram hesabınız bağlı. Sessizdeki gruplar dahil yeni mesajlar gelen kutusuna düşer. Bir sohbeti açınca son mesajları da indirilir.':
      'Dein Telegram-Konto ist verbunden. Neue Nachrichten, auch aus stummgeschalteten Gruppen, landen im Posteingang. Beim Öffnen eines Chats werden auch die letzten Nachrichten geladen.',
  'Bu giriş adımı desteklenmiyor.':
      'Dieser Anmeldeschritt wird nicht unterstützt.',
  'Telegram hesabınızı bağlayın': 'Verbinde dein Telegram-Konto',
  'Mesa, Telegram\'ın resmi kütüphanesiyle hesabınıza doğrudan bağlanır. Böylece bildirim üretmeyen sessiz grupların mesajları da gelir.':
      'Mesa verbindet sich mit Telegrams offizieller Bibliothek direkt mit deinem Konto, sodass auch Nachrichten aus stummgeschalteten Gruppen ohne Benachrichtigung ankommen.',
  'Telegram\'a bağlan': 'Mit Telegram verbinden',
  'Çıkış yapılıyor…': 'Wird abgemeldet…',
  'Telegram\'a bağlanılıyor…': 'Verbindung zu Telegram…',
  'Telefon numaranız': 'Deine Telefonnummer',
  'Doğrulama kodu': 'Bestätigungscode',
  'E-posta kodu': 'E-Mail-Code',
  'İki adımlı doğrulama şifresi': 'Passwort der zweistufigen Bestätigung',
  'Telefon numarası (ülke koduyla)': 'Telefonnummer (mit Ländervorwahl)',
  'Kod': 'Code',
  '• Bağlantı yalnızca Telegram sunucularına gider; mesajlar yalnızca bu telefonda saklanır.\n• Okundu bilgisi gönderilmez, çevrimiçi görünmezsiniz.\n• Bu cihaz Telegram\'da "Etkin oturumlar" listesinde görünür.\n• Bağlıyken bildirim çubuğunda sessiz bir "Telegram\'a bağlı" bildirimi durur.':
      '• Die Verbindung geht nur zu den Telegram-Servern; Nachrichten werden nur auf diesem Telefon gespeichert.\n• Lesebestätigungen werden nicht gesendet, und du erscheinst nicht online.\n• Dieses Gerät erscheint in Telegram unter „Aktive Sitzungen“.\n• Solange verbunden, bleibt eine lautlose Benachrichtigung „Mit Telegram verbunden“ in der Statusleiste.',
  'Bir sohbete basılı tutun: sabitleyin, sonraya erteleyin ya da aynı kişinin başka uygulamadaki sohbetiyle birleştirin.':
      'Tippe lange auf einen Chat: anheften, auf später verschieben oder mit dem Chat derselben Person in einer anderen App zusammenführen.',
  'Gönder düğmesine basılı tutun: mesajı istediğiniz saate planlayın.':
      'Halte den Senden-Knopf gedrückt: plane die Nachricht für eine beliebige Uhrzeit.',
  'Bir mesaja basılı tutup "Kaydet": tüm uygulamalardan kaydettikleriniz üstteki 🔖 listesinde.':
      'Tippe lange auf eine Nachricht und dann auf „Speichern“: Was du aus allen Apps speicherst, steht oben in der 🔖-Liste.',
  'Sohbetin üstündeki galeri düğmesi: o kişiyle paylaşılan tüm fotoğraf ve videolar tek yerde.':
      'Der Galerie-Knopf oben im Chat: alle mit dieser Person geteilten Fotos und Videos an einem Ort.',
  'Bildirimden yazmadan yanıtlayın: hazır yanıtlarınız bildirimin altında tek dokunuşla. Listeyi Ayarlar → Hazır yanıtlar\'dan değiştirin.':
      'Antworte aus der Benachrichtigung, ohne zu tippen: deine Schnellantworten sind dort nur einen Tipp entfernt. Ändere die Liste unter Einstellungen → Schnellantworten.',
  'Ana ekran bileşeni: okunmamışlar ve yanıt bekleyenler uygulamayı açmadan. Ayarlar → Ana ekran → Ekle.':
      'Startbildschirm-Widget: ungelesene Nachrichten und wartende Antworten, ohne die App zu öffnen. Einstellungen → Startbildschirm → Hinzufügen.',
  'Haftalık özet: kimlerle en çok yazıştığınızı üstteki grafik düğmesinden görün.':
      'Wochenübersicht: Mit dem Diagramm-Knopf oben siehst du, mit wem du am meisten schreibst.',
  'Günün ipucu': 'Tipp des Tages',
  'Tüm mesajların tek yerde': 'Alle deine Nachrichten an einem Ort',
  'WhatsApp, Telegram, Instagram, Discord ve diğerleri tek gelen kutusunda; uygulamalar arasında gidip gelmeden.':
      'WhatsApp, Telegram, Instagram, Discord und mehr in einem Posteingang, ohne zwischen Apps zu springen.',
  'Bir kişi, tek sohbet': 'Eine Person, ein Chat',
  'Aynı kişiyle WhatsApp\'tan, Instagram\'dan, Telegram\'dan yazıştıklarınız tek zaman çizgisinde; yanıtı istediğiniz uygulamadan verin.':
      'Was du mit derselben Person über WhatsApp, Instagram und Telegram schreibst, in einem Verlauf; antworte über die App deiner Wahl.',
  'Görüldü göndermeden oku': 'Lesen, ohne „gelesen“ zu senden',
  'WhatsApp ve Instagram mesajlarını burada okumak karşı tarafa "görüldü" göndermez; Telegram\'da da isteğe bağlı.':
      'WhatsApp- und Instagram-Nachrichten hier zu lesen sendet kein „gelesen“; bei Telegram ist es ebenfalls einstellbar.',
  'Silinen mesajın yazısı kalır': 'Der Text gelöschter Nachrichten bleibt',
  'Gönderen "herkesten sil" dese de yazdığı metin burada "silindi" etiketiyle durur.':
      'Auch wenn der Absender „Für alle löschen“ wählt, bleibt sein Text hier mit dem Hinweis „gelöscht“.',
  'Yanıt bekleyenler en üstte; sohbeti sonraya ertele, mesajı istediğin saate planla.':
      'Wartende Antworten ganz oben; Chat auf später verschieben, Nachricht für eine beliebige Uhrzeit planen.',
  'Telefonunda kalır': 'Bleibt auf deinem Telefon',
  'Mesajlar yalnızca bu telefonda saklanır; hiçbir sunucuya gönderilmez.':
      'Nachrichten werden nur auf diesem Telefon gespeichert und nie an einen Server gesendet.',
  'Bildirim erişimini aç': 'Benachrichtigungszugriff erlauben',
  'Mesa mesajları uygulamaların bildirimlerinden okur. Açılan listede Mesa\'yı bulup izin verin.':
      'Mesa liest Nachrichten aus den Benachrichtigungen der Apps. Suche Mesa in der Liste, die sich öffnet, und erlaube den Zugriff.',
  'İzin verilemiyor mu?': 'Lässt sich nicht aktivieren?',
  'Android, mağaza dışından kurulan uygulamalarda bu izni kısıtlar. Mesa\'nın anahtarına bir kez dokunun, sonra Uygulama bilgileri → ⋮ → Kısıtlanmış ayarlara izin ver\'i seçip tekrar deneyin.':
      'Android schränkt diese Berechtigung bei Apps ein, die nicht aus einem App-Store installiert wurden. Tippe einmal auf den Schalter von Mesa, öffne dann App-Info → ⋮ → Eingeschränkte Einstellungen zulassen und versuche es erneut.',
  'Uygulama bilgileri': 'App-Info',
  // Güvenli bağlantı (1.1)
  'Anahtar (secret)': 'Schlüssel (Secret)',
  'Açık · {provider}': 'An · {provider}',
  'Açılan pencerede "Tamam"a dokunarak VPN iznini verin.':
      'Tippe im sich öffnenden Fenster auf „OK“, um das VPN zu erlauben.',
  'Bağlantıdan ekle': 'Aus Link hinzufügen',
  'Başka bir VPN açık. Android aynı anda tek VPN\'e izin verir; şifreli DNS açılınca o kapanır.':
      'Ein anderes VPN ist aktiv. Android erlaubt nur ein VPN gleichzeitig; wenn du sicheres DNS einschaltest, wird es beendet.',
  'Başka bir VPN açıldığı için şifreli DNS kapandı.':
      'Sicheres DNS wurde beendet, weil ein anderes VPN eingeschaltet wurde.',
  'Bildirim panelini aşağı çekip düzenle simgesine dokunun ve "Şifreli DNS" kutucuğunu ekleyin; tek dokunuşla açıp kapatırsınız.':
      'Ziehe die Benachrichtigungsleiste herunter, tippe auf das Bearbeiten-Symbol und füge die Kachel „Sicheres DNS“ hinzu – so schaltest du es mit einem Tippen ein und aus.',
  'Bir hata oluştu.': 'Etwas ist schiefgelaufen.',
  'Bu bir Telegram proxy bağlantısı değil.':
      'Das ist kein Telegram-Proxy-Link.',
  'Bu telefonun tarayıcı bileşeni bunu desteklemiyor.':
      'Die Browser-Komponente dieses Telefons unterstützt das nicht.',
  'Bütün telefonda reklamları ve izleyicileri engeller':
      'Blockiert Werbung und Tracker auf dem ganzen Telefon',
  'Bütün telefonda şifreli DNS': 'Sicheres DNS für das ganze Telefon',
  'Dene': 'Testen',
  'Discord, Slack gibi web servisleri DNS ve SNI engellerine takılmadan açılır. VPN gerekmez, kendi VPN\'inizle de çakışmaz.':
      'Webdienste wie Discord und Slack öffnen sich, ohne an DNS- und SNI-Sperren hängen zu bleiben. Kein VPN nötig, und es kollidiert nicht mit deinem eigenen VPN.',
  'Elle ekle': 'Manuell hinzufügen',
  'En hızlı seçeneklerden biri; gizlilik odaklı':
      'Eine der schnellsten Optionen; datenschutzorientiert',
  'Engellenen servislere erişin ve DNS sorgularınızı gizleyin. Sunucu yok, hesap yok.':
      'Erreiche gesperrte Dienste und verberge deine DNS-Anfragen. Keine Server, kein Konto.',
  'Engellenen servislere erişin, DNS sorgularınızı gizleyin, reklamları engelleyin':
      'Gesperrte Dienste erreichen, DNS-Anfragen verbergen, Werbung blockieren',
  'Erişim kalkanı': 'Zugangsschutz',
  'Erişim kalkanı açıldı. Web servislerini yeniden açınca devreye girer.':
      'Der Zugangsschutz ist an. Er greift, sobald du die Webdienste neu öffnest.',
  'Geçerli bir MTProto anahtarı girin.':
      'Gib einen gültigen MTProto-Schlüssel ein.',
  'Google\'ın genel DNS\'i': 'Öffentliches DNS von Google',
  'Güvenli bağlantı': 'Sichere Verbindung',
  'Her zaman açık': 'Immer an',
  'Hızlı ayarlar kutucuğu': 'Schnelleinstellungs-Kachel',
  'Hızı ölç': 'Geschwindigkeit messen',
  'Kapalı': 'Aus',
  'Kullanıcı adı (isteğe bağlı)': 'Benutzername (optional)',
  'Kullanılıyor': 'In Verwendung',
  'Ortalama {ms} ms · {cached} önbellekten · {failed} başarısız':
      'Durchschnitt {ms} ms · {cached} aus dem Cache · {failed} fehlgeschlagen',
  'Parola (isteğe bağlı)': 'Passwort (optional)',
  'Port': 'Port',
  'Proxy bağlantısı': 'Proxy-Link',
  'Proxy ekle': 'Proxy hinzufügen',
  'Proxy eklemek için önce Telegram bağlantısını başlatın.':
      'Um einen Proxy hinzuzufügen, starte zuerst die Telegram-Verbindung.',
  'Proxy eklendi ve Telegram için açıldı.':
      'Proxy hinzugefügt und für Telegram eingeschaltet.',
  'Sunucu': 'Server',
  'Sunucu ve port (1–65535) gerekli.':
      'Server und Port (1–65535) sind erforderlich.',
  'Telefon açılınca kendiliğinden başlasın: sistemin VPN ayarlarında Mesa için "Her zaman açık VPN"i seçin.':
      'Automatisch beim Einschalten starten: Wähle in den VPN-Einstellungen des Systems „Durchgehend aktives VPN“ für Mesa.',
  'Telefonun "Özel DNS" ayarı bir sunucuya sabitlenmiş; o ayar kapatılmadan şifreli DNS etkisiz kalabilir.':
      'Die Einstellung „Privates DNS“ des Telefons ist auf einen Server festgelegt; sicheres DNS wirkt möglicherweise erst, wenn du sie ausschaltest.',
  'Telegram proxy': 'Telegram-Proxy',
  'Telegram\'a doğrudan erişim': 'Direkter Zugriff auf Telegram',
  'Ulaşılamıyor': 'Nicht erreichbar',
  'VPN izni verilmedi. Açmak için yeniden deneyin.':
      'Die VPN-Berechtigung wurde nicht erteilt. Versuche es erneut, um es einzuschalten.',
  'Web servisleri için erişim kalkanı': 'Zugangsschutz für Webdienste',
  'Zararlı siteleri engeller; kâr amacı gütmeyen kuruluş':
      'Blockiert schädliche Websites; betrieben von einer gemeinnützigen Organisation',
  'Zararlı sitelerle birlikte yetişkin içeriği de engeller':
      'Blockiert neben schädlichen Websites auch Inhalte für Erwachsene',
  'Zararlı ve oltalama sitelerini engeller':
      'Blockiert schädliche und Phishing-Websites',
  '{connections} bağlantı · {splits} engel aşma':
      '{connections} Verbindungen · {splits} umgangene Sperren',
  '{count, plural, one{# sorgu} other{# sorgu}}':
      '{count, plural, one{# Anfrage} other{# Anfragen}}',
  'Ölçülüyor…': 'Wird gemessen…',
  'Şifreli DNS': 'Sicheres DNS',
  'Şifreli DNS ve erişim kalkanı': 'Sicheres DNS und Zugangsschutz',
  'Şifreli DNS, operatörün DNS engellerini aşar ve hangi sitelere girdiğinizi operatörden gizler. IP adresinizi gizlemez; tam bir VPN değildir. DNS sorguları seçtiğiniz sağlayıcıya gider, Mesa\'nın sunucusu yoktur.':
      'Sicheres DNS umgeht DNS-Sperren deines Anbieters und verbirgt vor ihm, welche Websites du besuchst. Es verbirgt nicht deine IP-Adresse; es ist kein vollständiges VPN. DNS-Anfragen gehen an den gewählten Anbieter; Mesa hat keine Server.',
  // 2. aşama: tam VPN, odak modu, otomatik yedek, balonlar (1.2)
  '3 saat': '3 Stunden',
  'Acil durum': 'Notfälle',
  'Aynı kişi 5 dakika içinde 3 kez yazarsa bildirim gelir.':
      'Schreibt dieselbe Person dreimal innerhalb von 5 Minuten, wirst du benachrichtigt.',
  'Açık': 'An',
  'Açık · siz kapatana kadar': 'An · bis du es ausschaltest',
  'Açık · {time} saatine kadar': 'An · bis {time}',
  'Bağlantı yoksa interneti kes': 'Internet ohne VPN sperren',
  'Bağlanıyor… sunucudan henüz yanıt yok':
      'Verbinde… noch keine Antwort vom Server',
  'Bağlı': 'Verbunden',
  'Başlangıç': 'Beginn',
  'Ben kapatana kadar': 'Bis ich es ausschalte',
  'Bildirim panelindeki "Odak modu" kutucuğuyla da tek dokunuşla açıp kapatabilirsiniz.':
      'Du kannst ihn auch mit einem Tippen über die Kachel „Fokusmodus“ in der Benachrichtigungsleiste ein- und ausschalten.',
  'Bildirimdeki sohbet ekranın üstünde yüzen balonda açılır; uygulamayı açmadan yanıtlayın':
      'Der Chat aus der Benachrichtigung öffnet sich in einer schwebenden Blase; antworte, ohne die App zu öffnen',
  'Birleşik bildirimler kapalı: WhatsApp gibi uygulamaların kendi bildirimleri yine ses çıkarabilir. Odak modunun her şeyi susturması için birleşik bildirimleri açın.':
      'Einheitliche Benachrichtigungen sind aus: Apps wie WhatsApp können mit eigenen Benachrichtigungen weiter klingeln. Schalte sie ein, damit der Fokusmodus alles stummschaltet.',
  'Bitiş': 'Ende',
  'Bu yapılandırma bu telefonda açılamıyor; silip yeniden içe aktarın.':
      'Diese Konfiguration lässt sich auf diesem Telefon nicht öffnen; lösche sie und importiere sie erneut.',
  'Bütün trafiğiniz kendi WireGuard sunucunuz ya da bir VPN sağlayıcısı üzerinden geçer; IP adresiniz değişir.':
      'Dein gesamter Datenverkehr läuft über deinen eigenen WireGuard-Server oder einen VPN-Anbieter; deine IP-Adresse ändert sich.',
  'Dosya okunamadı.': 'Datei konnte nicht gelesen werden.',
  'Dosyadan içe aktar': 'Aus Datei importieren',
  'Eklenecek sohbet yok.': 'Keine Chats zum Hinzufügen.',
  'Her gün': 'Jeden Tag',
  'Her gün belirli saatlerde': 'Täglich zu festen Zeiten',
  'Her hafta': 'Jede Woche',
  'Israrla yazana izin ver': 'Hartnäckige Nachrichten durchlassen',
  'Kayıtlı parola açılamadı; otomatik yedeği yeniden açın.':
      'Das gespeicherte Passwort ließ sich nicht öffnen; schalte die automatische Sicherung erneut ein.',
  'Klasör seç': 'Ordner wählen',
  'Klasöre yazılamadı; klasörü yeniden seçin.':
      'In den Ordner konnte nicht geschrieben werden; wähle ihn erneut.',
  'Odak modu': 'Fokusmodus',
  'Odak modu açık': 'Fokusmodus ist an',
  'Odaktayken yalnızca VIP kişiler, "Önemli işaretle" kuralına uyan mesajlar ve acil durumlar bildirim verir. Diğer mesajlar Mesa\'da sessizce birikir; odak bitince kısa bir özet gelir.':
      'Im Fokus benachrichtigen dich nur VIPs, Nachrichten, auf die die Regel „Als wichtig markieren“ zutrifft, und Notfälle. Andere sammeln sich still in Mesa; am Ende kommt eine kurze Zusammenfassung.',
  'Otomatik yedek': 'Automatische Sicherung',
  'Otomatik yedek açıldı; ilk yedek şimdi alınıyor.':
      'Automatische Sicherung ist an; die erste wird jetzt erstellt.',
  'Panodan yapıştır': 'Aus Zwischenablage einfügen',
  'Sabah 08:00\'e kadar': 'Bis morgen früh um 08:00',
  'Seçtiğiniz klasöre düzenli olarak şifreli yedek alınır; en yeni 5 otomatik yedek saklanır. Otomatik çalışabilmesi için parola bu telefonda, telefonun güvenli donanım anahtarıyla şifrelenip saklanır.':
      'Verschlüsselte Sicherungen werden regelmäßig im gewählten Ordner gespeichert; die neuesten 5 automatischen Sicherungen bleiben erhalten. Damit es von selbst läuft, wird das Passwort auf diesem Telefon gespeichert, verschlüsselt mit dem sicheren Hardwareschlüssel des Telefons.',
  'Seçtiğiniz klasöre düzenli, şifreli yedek':
      'Regelmäßige verschlüsselte Sicherungen in einem Ordner deiner Wahl',
  'Sistemin VPN ayarlarında Mesa için "Her zaman açık VPN" ve "VPN olmadan bağlantıları engelle"yi açın.':
      'Schalte in den VPN-Einstellungen des Systems für Mesa „Durchgehend aktives VPN“ und „Verbindungen ohne VPN blockieren“ ein.',
  'Sohbet balonları': 'Chat-Blasen',
  'Sohbet bulunamadı.': 'Chat nicht gefunden.',
  'Sunucudan uzun süredir yanıt yok':
      'Seit einer Weile keine Antwort vom Server',
  'Sunucunun adresi çözülemedi. İnternet bağlantınızı kontrol edin.':
      'Die Serveradresse konnte nicht aufgelöst werden. Prüfe deine Internetverbindung.',
  'Tam VPN (WireGuard)': 'Vollständiges VPN (WireGuard)',
  'Tünel açılamadı ({code}).': 'Tunnel konnte nicht gestartet werden ({code}).',
  'VIP ekle': 'VIP hinzufügen',
  'VIP kişiler': 'VIPs',
  'VIP kişiler dışında sessizlik; zamanlanabilir, bitince özet':
      'Ruhe außer für VIPs; planbar, Zusammenfassung am Ende',
  'VIP kişiler odaktayken de size ulaşır: aile, yakın arkadaşlar, iş için önemli biri.':
      'VIPs erreichen dich auch im Fokus: Familie, enge Freunde, jemand Wichtiges von der Arbeit.',
  'WireGuard yapılandırması': 'WireGuard-Konfiguration',
  'WireGuard yapılandırması eklendi.': 'WireGuard-Konfiguration hinzugefügt.',
  'Yalnızca VIP kişiler bildirim verir': 'Nur VIPs benachrichtigen dich',
  'Yapılandırma dosyasını kendi sunucunuzdan ya da WireGuard dosyası veren bir sağlayıcıdan (ör. Proton VPN\'in ücretsiz planı) alabilirsiniz.':
      'Die Konfigurationsdatei bekommst du von deinem eigenen Server oder von einem Anbieter, der WireGuard-Dateien anbietet (z. B. der kostenlose Tarif von Proton VPN).',
  'Yapılandırma okunamadı. Dosyanın bir WireGuard (.conf) dosyası olduğundan emin olun.':
      'Die Konfiguration konnte nicht gelesen werden. Prüfe, ob die Datei eine WireGuard-Datei (.conf) ist.',
  'Yapılandırmada sunucu ([Peer]) yok.':
      'Die Konfiguration enthält keinen Server ([Peer]).',
  'Yedek yazılamadı; yer kalmamış olabilir.':
      'Die Sicherung konnte nicht geschrieben werden; der Speicher ist vielleicht voll.',
  'Zamanlama': 'Zeitplan',
  'son: {when}': 'zuletzt: {when}',
  'yalnızca bazı adresler': 'nur einige Adressen',
  '{count, plural, one{# mesaj susturuldu} other{# mesaj susturuldu}}':
      '{count, plural, one{# Nachricht stummgeschaltet} other{# Nachrichten stummgeschaltet}}',
  'Çıkar': 'Entfernen',
  'İçe aktar': 'Importieren',
  'Şimdi yedekle': 'Jetzt sichern',
  '↓ {rx} · ↑ {tx}': '↓ {rx} · ↑ {tx}',
  // 1.2.1: WhatsApp'ta yazılan yanıtlar
  'Ayarı aç': 'Einstellung öffnen',
  'WhatsApp\'ta yazdıklarım': 'Was ich in WhatsApp schreibe',
  'WhatsApp\'ta yazdıklarınız da görünsün':
      'Auch zeigen, was du in WhatsApp schreibst',
  'WhatsApp\'tan yazdığınız yanıtlar burada görünmüyor. Görünsün mü?':
      'Antworten, die du in WhatsApp schreibst, erscheinen hier nicht. Anzeigen?',
  // 1.2.1: otomatik gönderim
  'Bu servis şunları yapar:\n• WhatsApp\'ta açık sohbete gelen ve sizin yazdığınız yeni mesajlar Mesa\'daki aynı sohbete eklenir; sohbet Mesa\'da yoksa açılır.\n• WhatsApp\'ta açtığınız sohbet burada da okunmuş sayılır.\n• Mesa\'dan yazdığınız mesaj, Mesa\'dan çıkmadan WhatsApp üzerinden gönderilir.\n\nAçılan sayfada "İndirilen uygulamalar"a girip "Mesa: WhatsApp yanıtlarım"ı açın. Yalnızca WhatsApp okunur ve hiçbir şey telefondan çıkmaz.\n\nAyar soluk görünüyorsa: Uygulama bilgisi → ⋮ → Kısıtlanmış ayarlara izin ver.':
      'Dieser Dienst:\n• Fügt neue Nachrichten im geöffneten WhatsApp-Chat, empfangene und von dir geschriebene, demselben Chat in Mesa hinzu und legt den Chat in Mesa an, falls er fehlt.\n• Markiert in WhatsApp geöffnete Chats auch hier als gelesen.\n• Sendet in Mesa geschriebene Nachrichten über WhatsApp, ohne Mesa zu verlassen.\n\nÖffne auf der nächsten Seite „Heruntergeladene Apps“ und schalte „Mesa: meine WhatsApp-Antworten“ ein. Gelesen wird nur WhatsApp, und nichts verlässt dein Telefon.\n\nIst die Einstellung ausgegraut: App-Info → ⋮ → Eingeschränkte Einstellungen zulassen.',
  'WhatsApp\'ta yazdıklarınız ve orada açıkken gelenler de Mesa\'da görünür; Mesa\'dan yazdıklarınız WhatsApp\'ta kendiliğinden gönderilir':
      'Was du in WhatsApp schreibst und was dort bei geöffnetem Chat eintrifft, erscheint auch in Mesa; in Mesa geschriebene Nachrichten werden in WhatsApp automatisch gesendet',
  'Mesajınız {name} üzerinden, Mesa\'dan çıkmadan gönderilir.':
      'Deine Nachricht wird über {name} gesendet, ohne Mesa zu verlassen.',
  'Otomatik gönder': 'Automatisch senden',
  'WhatsApp\'ta gönderilemedi; mesajınız yazma alanında.':
      'In WhatsApp konnte nicht gesendet werden; deine Nachricht steht wieder im Eingabefeld.',
  // Mesajdan işe tek dokunuş
  'Açılamadı.': 'Konnte nicht geöffnet werden.',
  'Bağlantıyı aç': 'Link öffnen',
  'E-postayı kopyala': 'E-Mail kopieren',
  'Haritada aç': 'In Karten öffnen',
  'Hatırlat': 'Erinnern',
  'Hatırlatma kurulamadı.': 'Erinnerung konnte nicht gesetzt werden.',
  'IBAN\'ı kopyala': 'IBAN kopieren',
  'Kodu kopyala': 'Code kopieren',
  'Kopyalandı': 'Kopiert',
  'Takvim uygulaması bulunamadı.': 'Keine Kalender-App gefunden.',
  'Takvime ekle': 'Zum Kalender hinzufügen',
  'Telefonla ara': 'Anrufen',
  '{time} için hatırlatma kuruldu': 'Erinnerung für {time} gesetzt',
};
