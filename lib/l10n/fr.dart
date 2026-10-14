// Türkçe metin → çeviri. Anahtarlar test/l10n_test.dart ile denetlenir
// (yeni metin: tr() ekleyin, buraya ve diğer dillere çevirisini yazın).
const fr = <String, String>{
  'Pazartesi': 'Lundi',
  'Salı': 'Mardi',
  'Çarşamba': 'Mercredi',
  'Perşembe': 'Jeudi',
  'Cuma': 'Vendredi',
  'Cumartesi': 'Samedi',
  'Pazar': 'Dimanche',
  'Bugün': 'Aujourd\'hui',
  'Dün': 'Hier',
  '{day} Ocak': '{day} janvier',
  '{day} Şubat': '{day} février',
  '{day} Mart': '{day} mars',
  '{day} Nisan': '{day} avril',
  '{day} Mayıs': '{day} mai',
  '{day} Haziran': '{day} juin',
  '{day} Temmuz': '{day} juillet',
  '{day} Ağustos': '{day} août',
  '{day} Eylül': '{day} septembre',
  '{day} Ekim': '{day} octobre',
  '{day} Kasım': '{day} novembre',
  '{day} Aralık': '{day} décembre',
  '{day}.{month}.{year}': '{day}/{month}/{year}',
  'bugün {clock}': 'aujourd\'hui {clock}',
  'yarın {clock}': 'demain {clock}',
  'şimdi': 'maintenant',
  '{n} dk': '{n} min',
  '{n} sa': '{n} h',
  '{n} g': '{n} j',
  'B': 'o',
  'KB': 'Ko',
  'MB': 'Mo',
  'GB': 'Go',
  'Çıkartma': 'Autocollant',
  '📷 Fotoğraf': '📷 Photo',
  'Otomatik yanıt': 'Réponse automatique',
  'Sessize al': 'Mettre en sourdine',
  'Önemli işaretle': 'Marquer comme important',
  '15 dakika': '15 minutes',
  '1 saat': '1 heure',
  '6 saat': '6 heures',
  '1 gün': '1 jour',
  'Pzt': 'Lun',
  'Sal': 'Mar',
  'Çar': 'Mer',
  'Per': 'Jeu',
  'Cum': 'Ven',
  'Cmt': 'Sam',
  'Paz': 'Dim',
  'hafta içi': 'en semaine',
  'hafta sonu': 'le week-end',
  'Tüm uygulamalar': 'Toutes les applis',
  'Kimden: "{sender}"': 'De : « {sender} »',
  'İçerik: {words}': 'Contient : {words}',
  'gruplar dahil': 'groupes inclus',
  'Süresiz': 'Illimitée',
  '7 gün': '7 jours',
  '30 gün': '30 jours',
  '90 gün': '90 jours',
  '1 yıl': '1 an',
  'Tamam 👍': 'D\'accord 👍',
  'Şu an müsait değilim, sonra yazarım.':
      'Je ne suis pas disponible pour le moment, je vous écris plus tard.',
  'Yoldayım, birazdan oradayım.': 'Je suis en route, j\'arrive bientôt.',
  'Teşekkürler!': 'Merci !',
  '{step} bir giriş adımı değil': '{step} n\'est pas une étape de connexion',
  '🎥 Video': '🎥 Vidéo',
  '🎵 Ses dosyası': '🎵 Fichier audio',
  '🎤 Sesli mesaj': '🎤 Message vocal',
  '🎤 Ses': '🎤 Audio',
  '⏺ Görüntülü mesaj': '⏺ Message vidéo',
  '📍 Konum': '📍 Position',
  '📄 Dosya': '📄 Fichier',
  '👤 Kişi': '👤 Contact',
  '📊 Anket': '📊 Sondage',
  'Arşiv': 'Archives',
  'Arşivde sohbet yok.\nGelen kutusunda bir sohbete uzun basıp "Arşivle"yi seçebilirsiniz.':
      'Aucune discussion archivée.\nAppuyez longuement sur une discussion dans la boîte de réception et choisissez « Archiver ».',
  'Yedekleniyor… Fotoğraflar çoksa biraz sürebilir.':
      'Sauvegarde en cours… Cela peut prendre un moment s\'il y a beaucoup de photos.',
  'Yedek kaydedildi: {messages} mesaj, {files} fotoğraf ({bytes}).':
      'Sauvegarde enregistrée : {messages, plural, one{# message} other{# messages}}, {files, plural, one{# photo} other{# photos}} ({bytes}).',
  'Yedek alınamadı: {error}': 'Échec de la sauvegarde : {error}',
  'bilinmeyen hata': 'erreur inconnue',
  'Yedekten geri yüklensin mi?': 'Restaurer depuis la sauvegarde ?',
  'Bu telefondaki Mesa mesajları, kişileri ve kuralları yedektekilerle değiştirilir. Telegram ve web servisi girişleri yedekte yoktur; gerekirse yeniden giriş yaparsınız.':
      'Les messages, personnes et règles de Mesa sur ce téléphone seront remplacés par ceux de la sauvegarde. Les connexions à Telegram et aux services web ne sont pas sauvegardées ; reconnectez-vous si nécessaire.',
  'Vazgeç': 'Annuler',
  'Dosya seç': 'Choisir un fichier',
  'Geri yükleniyor…': 'Restauration…',
  'Geri yüklendi: {messages} mesaj, {files} fotoğraf.':
      'Restauré : {messages, plural, one{# message} other{# messages}}, {files, plural, one{# photo} other{# photos}}.',
  'Şifre yanlış. Yedeği alırken girdiğiniz şifreyi deneyin.':
      'Mot de passe incorrect. Essayez celui que vous avez saisi lors de la sauvegarde.',
  'Dosya açılamadı: {error}': 'Impossible d\'ouvrir le fichier : {error}',
  'yedek bozuk': 'sauvegarde endommagée',
  'Geri yüklenemedi: {error}': 'Échec de la restauration : {error}',
  'Yedek': 'Sauvegarde',
  'Yedekle': 'Sauvegarder',
  'Mesajlar, kişiler, kurallar ve fotoğraflar; şifreli dosya. Henüz yedek alınmadı.':
      'Messages, personnes, règles et photos ; fichier chiffré. Aucune sauvegarde pour l\'instant.',
  'Mesajlar, kişiler, kurallar ve fotoğraflar; şifreli dosya. Son yedek: {when}':
      'Messages, personnes, règles et photos ; fichier chiffré. Dernière sauvegarde : {when}',
  'Yedekten geri yükle': 'Restaurer depuis une sauvegarde',
  'Yeni telefonda ya da sıfırlamadan sonra':
      'Sur un nouveau téléphone ou après une réinitialisation',
  'En az 8 karakter olmalı.': 'Au moins 8 caractères.',
  'Şifreler aynı değil.': 'Les mots de passe ne correspondent pas.',
  'Yedek şifresi': 'Mot de passe de sauvegarde',
  'Yedeğin şifresi': 'Mot de passe de la sauvegarde',
  'Bu şifreyi unutursanız yedek açılamaz; kimse kurtaramaz. Bir yere not edin.':
      'Si vous oubliez ce mot de passe, la sauvegarde ne pourra pas être ouverte ; personne ne pourra la récupérer. Notez-le quelque part.',
  'Şifre': 'Mot de passe',
  'Göster': 'Afficher',
  'Gizle': 'Masquer',
  'Şifre (tekrar)': 'Mot de passe (confirmation)',
  'Aç': 'Ouvrir',
  'Açıldı. Bu sohbetten yeni mesaj gelince yanıtlarınız {appName} açılmadan, doğrudan gider.':
      'Activé. Dès qu\'un nouveau message arrive dans cette discussion, vos réponses partent directement, sans ouvrir {appName}.',
  'Mesajınız bu sohbete de kaydedildi.':
      'Votre message a aussi été enregistré dans cette discussion.',
  'Gönderilmedi': 'Non envoyé',
  'Tekrar gönder': 'Renvoyer',
  'Mesaj gönderilemedi': 'Message non envoyé',
  'Sil': 'Supprimer',
  'Karşı tarafa hiç gitmedi': 'Il n\'est jamais arrivé au destinataire',
  'Kaydedilenlerden çıkar': 'Retirer des enregistrés',
  'Kaydet': 'Enregistrer',
  'Tüm uygulamalardan kaydedilenler tek listede':
      'Les messages enregistrés de toutes les applis dans une seule liste',
  'Kopyala': 'Copier',
  'Kaydedilenlerden çıkarıldı.': 'Retiré des enregistrés.',
  'Kaydedildi ⭐': 'Enregistré ⭐',
  'Kopyalandı.': 'Copié.',
  'Yeniden gönderiliyor…': 'Nouvel envoi…',
  'Gönderilemedi. Bağlantıyı kontrol edin.':
      'Envoi impossible. Vérifiez la connexion.',
  'Ne zaman gönderilsin?': 'Quand l\'envoyer ?',
  '⏰ {when} Telegram\'dan gönderilecek.': '⏰ Sera envoyé via Telegram {when}.',
  '⏰ {when} kendiliğinden gönderilecek.':
      '⏰ Sera envoyé automatiquement {when}.',
  '⏰ {when} bildirim gelecek: dokununca {appName} mesaj yazılmış olarak açılır, ➤ ile gönderirsiniz. {viaAppNote}':
      '⏰ Vous recevrez une notification {when} : en la touchant, {appName} s\'ouvre avec le message rédigé, et vous l\'envoyez avec ➤. {viaAppNote}',
  'O zamana kadar bu sohbetten yeni mesaj gelirse kendiliğinden gider.':
      'Si un nouveau message arrive dans cette discussion d\'ici là, il sera envoyé automatiquement.',
  'Planlı mesajlar': 'Messages programmés',
  'İptal et': 'L\'annuler',
  '{appName} bu sohbet için şu an doğrudan gönderme yolu vermiyor: zamanı gelince bildirime dokunup {appName} içinde gönderirsiniz. {viaAppNote}':
      '{appName} ne permet pas pour l\'instant d\'envoyer directement dans cette discussion : le moment venu, touchez la notification et envoyez-le dans {appName}. {viaAppNote}',
  'Telegram bağlantısı açık değil.':
      'La connexion à Telegram n\'est pas ouverte.',
  '{appName} açılamadı.': 'Impossible d\'ouvrir {appName}.',
  'Gönderiliyor…': 'Envoi…',
  '{kind} gönderiliyor…': 'Envoi : {kind}…',
  '{appName} açıldı; göndermek için orada ➤ düğmesine dokunun.':
      '{appName} est ouvert ; touchez-y le bouton ➤ pour envoyer.',
  '{appName} dışarıdan {kind} kabul etmiyor.':
      '{appName} n\'accepte pas de {kind} venant d\'autres applis.',
  'Gönderilemedi.': 'Envoi impossible.',
  'Fotoğraf': 'Photo',
  'Video': 'Vidéo',
  'Sesli mesaj': 'Message vocal',
  'Dosya': 'Fichier',
  'Planlı mesaj': 'Message programmé',
  'Zaman seç': 'Choisir l\'heure',
  'Gönderilecek mesaj': 'Message à envoyer',
  'Sesli mesaj için mikrofon izni gerekli.':
      'L\'autorisation du micro est nécessaire pour les messages vocaux.',
  'Kayıt başlatılamadı.': 'Impossible de démarrer l\'enregistrement.',
  'Kayıt çok kısa.': 'Enregistrement trop court.',
  'Uygulama açılamadı.': 'Impossible d\'ouvrir l\'appli.',
  'Siz': 'Vous',
  'Hazır yanıtlar': 'Réponses rapides',
  'Gizli okuma açık: Telegram\'da "görüldü" ve "yazıyor" gitmez.':
      'Lecture discrète activée : Telegram n\'envoie ni « vu » ni « écrit… ».',
  'Burada okumak {name}\'ta "görüldü" göndermez. Yanıt verirseniz gider.':
      'Lire ici n\'envoie pas « vu » dans {name}. C\'est envoyé si vous répondez.',
  'Görüldü gönderilmez': '« Vu » n\'est pas envoyé',
  'Medya': 'Médias',
  '{name} uygulamasında aç': 'Ouvrir dans {name}',
  'Bu sohbette henüz mesaj yok.':
      'Pas encore de message dans cette discussion.',
  '{count} planlı mesaj · ilki {when}':
      '{count, plural, one{# message programmé} other{# messages programmés}} · le premier {when}',
  'Mesajınız {name}\'ta hazır açılır; orada ➤ ile gönderin.':
      'Votre message s\'ouvre prêt dans {name} ; envoyez-le là-bas avec ➤.',
  'Klavye': 'Clavier',
  'Emoji': 'Emoji',
  '{appName} ile yaz': 'Écrire dans {appName}',
  'Mesaj yaz': 'Écrire un message',
  'Çıkartma ve GIF': 'Autocollants et GIF',
  'Fotoğraf, video, dosya': 'Photo, vidéo, fichier',
  'Zamanla': 'Programmer',
  'Kamera': 'Appareil photo',
  'Sesli mesajı gönder': 'Envoyer le message vocal',
  'Gönder (basılı tutun: zamanla)': 'Envoyer (appui long : programmer)',
  'Web servislerine yanıt, servisin kendi sayfasından yazılır.':
      'Les réponses aux services web s\'écrivent sur la page du service.',
  '{name} telefonda kurulu değil.':
      '{name} n\'est pas installé sur ce téléphone.',
  '{name} sayfasında yanıtla': 'Répondre sur la page {name}',
  'çevrimiçi': 'en ligne',
  'son görülme {seen}': 'vu {seen}',
  'bugün {time}': 'aujourd\'hui à {time}',
  'dün {time}': 'hier à {time}',
  'Kaydı sil': 'Supprimer l\'enregistrement',
  '◀ İptal için kaydırın': '◀ Glissez pour annuler',
  'Sesli mesaj: dokunun ya da basılı tutun':
      'Message vocal : touchez ou maintenez',
  'Galeri': 'Galerie',
  'Açıklama ekle': 'Ajouter une légende',
  '{appName} hazır açılır; orada gönderin':
      'S\'ouvre prêt dans {appName} ; envoyez-le là-bas',
  'Gönder': 'Envoyer',
  'Gönderilemedi': 'Non envoyé',
  'Gönderiliyor': 'Envoi',
  'Görüldü': 'Vu',
  'Gönderildi': 'Envoyé',
  'Burada okumak {appName}\'ta "görüldü" göndermez. Yanıt verirseniz gider.':
      'Lire ici n\'envoie pas « vu » dans {appName}. C\'est envoyé si vous répondez.',
  'Anladım': 'Compris',
  'Oynat': 'Lire',
  'Sesli mesaj indirilemedi.': 'Impossible de télécharger le message vocal.',
  'Duraklat': 'Pause',
  'Dinle': 'Écouter',
  '{appName}\'ta aç': 'Ouvrir dans {appName}',
  'Yanıt:': 'Réponse :',
  'Yükleniyor %{percent}': 'Envoi {percent} %',
  'Şu an gönderince {appName} açılıyor. Açarsanız bu sohbetten mesaj geldiğinde yanıtlarınız doğrudan gider.':
      'Pour l\'instant, envoyer ouvre {appName}. Activez cette option : dès qu\'un message arrive de cette discussion, vos réponses partiront directement.',
  'Kapat': 'Fermer',
  'Hatırlatma': 'Rappel',
  'Sabitlendi': 'Épinglée',
  'Önemli': 'Important',
  'Sabitlemeyi kaldır': 'Désépingler',
  'Sabitle': 'Épingler',
  'Sonra hatırlat': 'Me le rappeler plus tard',
  'Arşivden çıkar': 'Désarchiver',
  'Arşivle': 'Archiver',
  'Kişiyle birleştir': 'Fusionner avec une personne',
  'Aynı kişinin başka uygulamadaki sohbetiyle tek yerde':
      'La discussion de cette personne dans une autre appli, au même endroit',
  '{name} kişisinden ayır': 'Séparer de {name}',
  'Kişi': 'Personne',
  'Ne zaman hatırlatılsın?': 'Quand vous le rappeler ?',
  '⏰ {when} hatırlatılacak': '⏰ Rappel {when}',
  '{target}: {name} ve {name2} sohbetleri birleşti':
      '{target} : discussions {name} et {name2} fusionnées',
  '"{title}" silinsin mi?': 'Supprimer « {title} » ?',
  'Sohbet ve mesajları yalnızca Mesa\'dan silinir; {name} uygulamasındaki sohbete dokunulmaz.':
      'La discussion et ses messages sont supprimés uniquement de Mesa ; la discussion dans {name} n\'est pas touchée.',
  '{title} ile birleştir': 'Fusionner avec {title}',
  'Aynı kişinin başka uygulamadaki sohbetini seçin. Mesajlar tek yerde görünür; istediğiniz zaman ayırabilirsiniz.':
      'Choisissez la discussion de cette personne dans une autre appli. Les messages apparaîtront au même endroit ; vous pourrez les séparer à tout moment.',
  'Ara': 'Rechercher',
  'Adını değiştir': 'Renommer',
  '{name} sohbetini ayır': 'Séparer la discussion {name}',
  'Kişinin adı': 'Nom de la personne',
  '1 saat sonra': 'Dans 1 heure',
  '3 saat sonra': 'Dans 3 heures',
  'Bu akşam': 'Ce soir',
  'Yarın sabah': 'Demain matin',
  'Tarih ve saat seç': 'Choisir la date et l\'heure',
  'Yanıt bekliyor · {count}': 'En attente de réponse · {count}',
  'Ertelenen sohbetler': 'Discussions reportées',
  'Şimdi göster': 'Afficher maintenant',
  'Sohbetler': 'Discussions',
  'Servisler': 'Services',
  'Kurallar': 'Règles',
  'Ayarlar': 'Paramètres',
  'Yanıt gerekmez': 'Pas besoin de répondre',
  'Yeni mesaj gelene kadar listeden kalkar':
      'Disparaît de la liste jusqu\'au prochain message',
  'Birleşik bildirimler açık. Yeni mesajlar artık Mesa bildirimiyle gelecek.':
      'Les notifications unifiées sont activées. Les nouveaux messages arriveront désormais en notifications Mesa.',
  'Mesajlar': 'Messages',
  'Hepsi okundu': 'Tout est lu',
  '{unreadTotal} okunmamış': '{unreadTotal} non lus',
  'Haftalık özet': 'Résumé de la semaine',
  'Kaydedilenler': 'Enregistrés',
  'Diğer': 'Plus',
  'Tümünü okundu say': 'Tout marquer comme lu',
  'Arşiv ({archivedCount})': 'Archives ({archivedCount})',
  'Tümü': 'Tous',
  'Ekle': 'Ajouter',
  'Servis ekle': 'Ajouter un service',
  '{count} ertelenmiş sohbet':
      '{count, plural, one{# discussion reportée} other{# discussions reportées}}',
  'Zamanı gelince hatırlatılacak': 'Vous serez prévenu le moment venu',
  '{name} artık tek satırda: {name2} ve {name3} mesajları birlikte.':
      '{name} tient maintenant sur une ligne : messages de {name2} et {name3} ensemble.',
  'Tüm mesajlarda ara': 'Rechercher dans tous les messages',
  'Henüz mesaj yok': 'Aucun message pour l\'instant',
  'WhatsApp, Instagram, Discord gibi uygulamalardan yeni mesaj geldikçe burada toplanır; eski mesajlar görünmez. Telegram\'ı Ayarlar\'dan bağlarsanız geçmişi de gelir.':
      'Les nouveaux messages d\'applis comme WhatsApp, Instagram et Discord s\'affichent ici à leur arrivée ; les anciens n\'apparaissent pas. Connectez Telegram dans les Paramètres pour récupérer aussi son historique.',
  'Bildirimleri birleştir': 'Unifier les notifications',
  'Her uygulamanın ayrı bildirimi yerine tek tip Mesa bildirimleri: kişi fotoğrafı, doğrudan yanıt ve kurallarınla birlikte.':
      'Un seul type de notification Mesa au lieu d\'une par appli : avec la photo du contact, la réponse directe et vos règles.',
  'Bildirim servisi çalışmıyor':
      'Le service de notifications ne fonctionne pas',
  'Yeni mesajlar şu an yakalanmıyor. Xiaomi uygulamayı arka planda engelliyor: Otomatik başlatma iznini açın ve uygulama ayarlarında pil tasarrufunu "Kısıtlama yok" yapın. Ardından "Yeniden bağla"ya dokunun.':
      'Les nouveaux messages ne sont pas capturés en ce moment. Xiaomi bloque l\'appli en arrière-plan : activez l\'autorisation « Démarrage automatique » et réglez l\'économie de batterie sur « Aucune restriction » dans les paramètres de l\'appli. Puis touchez « Reconnecter ».',
  'Yeni mesajlar şu an yakalanmıyor. Telefon uygulamayı arka planda kapatmış olabilir: uygulama ayarlarında pil kısıtlamasını kaldırın, ardından "Yeniden bağla"ya dokunun.':
      'Les nouveaux messages ne sont pas capturés en ce moment. Le téléphone a peut-être fermé l\'appli en arrière-plan : levez la restriction de batterie dans les paramètres de l\'appli, puis touchez « Reconnecter ».',
  'Otomatik başlatma': 'Démarrage automatique',
  'Uygulama ayarları': 'Paramètres de l\'appli',
  'Yeniden bağla': 'Reconnecter',
  'Aynı kişi mi?': 'Même personne ?',
  'Telefon numaraları aynı. Birleştirirseniz mesajları tek satırda, tek zaman çizgisinde görürsünüz.':
      'Les numéros de téléphone sont identiques. En fusionnant, vous voyez les messages sur une seule ligne et une seule chronologie.',
  'Adları aynı. Birleştirirseniz mesajları tek satırda, tek zaman çizgisinde görürsünüz.':
      'Les noms sont identiques. En fusionnant, vous voyez les messages sur une seule ligne et une seule chronologie.',
  'Farklı kişiler': 'Personnes différentes',
  'Birleştir': 'Fusionner',
  'Uygulamanın dili': 'Langue de l\'appli',
  'Telefonun dili': 'Langue du téléphone',
  'Dil': 'Langue',
  'Telefonun dili ({language})': 'Langue du téléphone ({language})',
  'Mesa\'yı açmak için kimliğinizi doğrulayın':
      'Confirmez votre identité pour ouvrir Mesa',
  'Mesa kilitli': 'Mesa est verrouillé',
  'Kilidi aç': 'Déverrouiller',
  'Fotoğraflar': 'Photos',
  'Videolar': 'Vidéos',
  'Ocak': 'Janvier',
  'Şubat': 'Février',
  'Mart': 'Mars',
  'Nisan': 'Avril',
  'Mayıs': 'Mai',
  'Haziran': 'Juin',
  'Temmuz': 'Juillet',
  'Ağustos': 'Août',
  'Eylül': 'Septembre',
  'Ekim': 'Octobre',
  'Kasım': 'Novembre',
  'Aralık': 'Décembre',
  'Henüz fotoğraf ya da video yok': 'Pas encore de photos ni de vidéos',
  'Bildiriminde önizlemesi gelen fotoğraflar ve Telegram medyası burada toplanır.':
      'Les photos avec aperçu dans les notifications et les médias Telegram s\'affichent ici.',
  'Tam boyut': 'Taille réelle',
  'Medya açılamadı.': 'Impossible d\'ouvrir le média.',
  'Görsel açılamadı.': 'Impossible d\'ouvrir l\'image.',
  'İndiriliyor…': 'Téléchargement…',
  'Açılıyor…': 'Ouverture…',
  'İndiriliyor… %{percent}': 'Téléchargement… {percent} %',
  'Sesi kapat': 'Couper le son',
  'Sesi aç': 'Activer le son',
  'Tam ekrandan çık': 'Quitter le plein écran',
  'Tam ekran': 'Plein écran',
  'Başlangıç saati': 'Heure de début',
  'Bitiş saati': 'Heure de fin',
  'En az bir gün seçin.': 'Choisissez au moins un jour.',
  'Kural silinsin mi?': 'Supprimer la règle ?',
  '"{name}" kalıcı olarak silinecek.':
      '« {name} » sera supprimée définitivement.',
  'Yeni kural': 'Nouvelle règle',
  'Kuralı düzenle': 'Modifier la règle',
  'Kural adı': 'Nom de la règle',
  'Ne yapılsın?': 'Que faire ?',
  'Mesaja, geldiği uygulama üzerinden otomatik cevap verilir.':
      'Le message reçoit une réponse automatique via l\'appli d\'où il vient.',
  'Mesajlar kaydedilir ama okunmamış sayılmaz.':
      'Les messages sont enregistrés mais ne comptent pas comme non lus.',
  'Sohbet, açılana kadar listenin en üstünde yıldızla durur.':
      'La discussion reste en haut de la liste avec une étoile jusqu\'à ce que vous l\'ouvriez.',
  'Yanıt metni': 'Texte de la réponse',
  'Şu an müsait değilim, sonra yazacağım.':
      'Je ne suis pas disponible pour le moment, je vous écrirai plus tard.',
  'Otomatik yanıt için bir metin yazın':
      'Saisissez un texte pour la réponse automatique',
  'Aynı sohbete tekrar yanıt için bekle':
      'Attendre avant de répondre à nouveau à la même discussion',
  'Hangi mesajlarda?': 'Pour quels messages ?',
  'Uygulama seçilmedi: tüm uygulamalar':
      'Aucune appli choisie : toutes les applis',
  'Yalnızca seçilen uygulamalar': 'Seulement les applis choisies',
  'Kimden (isteğe bağlı)': 'De (facultatif)',
  'Sohbet ya da kişi adında geçen ifade':
      'Texte dans le nom de la discussion ou de la personne',
  'Anahtar kelimeler (isteğe bağlı)': 'Mots-clés (facultatif)',
  'acil, toplantı, fatura': 'urgent, réunion, facture',
  'Virgülle ayırın; herhangi biri geçerse kural çalışır':
      'Séparez par des virgules ; la règle s\'applique si l\'un d\'eux apparaît',
  'Grup sohbetlerinde de çalışsın': 'Aussi dans les discussions de groupe',
  'Gruptaki herkes otomatik yanıtı görür.':
      'Tout le groupe voit la réponse automatique.',
  'Ne zaman?': 'Quand ?',
  'Yalnızca belirli saatlerde': 'Seulement à certaines heures',
  'Gün boyu': 'Toute la journée',
  'Başlangıç {from}': 'Début {from}',
  'Bitiş {to}': 'Fin {to}',
  'Gece yarısını aşar: {from}–{to} (ertesi gün)':
      'Passe minuit : {from}–{to} (le lendemain)',
  'Koşul yok: bu kural her yeni mesaja yanıt verir (bekleme süresi ve saatlik sınırla).':
      'Aucune condition : cette règle répond à chaque nouveau message (avec le délai d\'attente et la limite horaire).',
  'Kurallar nasıl çalışır?': 'Comment fonctionnent les règles ?',
  'Kurallar uygulama kapalıyken de, yeni mesaj gelir gelmez çalışır.\n\nOtomatik yanıt güvenliği: aynı anda gelen mesajlara tek yanıt; aynı sohbete bekleme süresi dolmadan tekrar yanıt yok; tüm sohbetlerde saatte en fazla 20 yanıt.\n\nYanıt, kaynak uygulamanın bildirimi üzerinden (Telegram\'da doğrudan) gider; bildirim yoksa gönderilmez.':
      'Les règles s\'appliquent dès qu\'un nouveau message arrive, même quand l\'appli est fermée.\n\nSécurité des réponses automatiques : une seule réponse aux messages arrivés en même temps ; pas de nouvelle réponse à la même discussion avant la fin du délai d\'attente ; au plus 20 réponses par heure pour toutes les discussions.\n\nLa réponse passe par la notification de l\'appli d\'origine (directement sur Telegram) ; sans notification, elle n\'est pas envoyée.',
  'Otomatik yanıt, sessize alma, önemli işaretleme':
      'Réponse automatique, sourdine, marquer comme important',
  '{active} etkin kural':
      '{active, plural, one{# règle active} other{# règles actives}}',
  'Kural ekle': 'Ajouter une règle',
  'Kurallarınız': 'Vos règles',
  'Son 7 günde {recentFires} kez çalıştı':
      'Appliquée {recentFires, plural, one{# fois} other{# fois}} ces 7 derniers jours',
  'Henüz kural yok': 'Aucune règle pour l\'instant',
  'Yukarıdaki hazır kurallardan birine dokunun ya da kendiniz ekleyin.':
      'Touchez une des règles prêtes ci-dessus ou ajoutez la vôtre.',
  'WhatsApp\'ta "acil" geçen mesajları önemli işaretle':
      'Marquer comme importants les messages WhatsApp contenant « urgent »',
  'İş grubunu sessize al': 'Mettre en sourdine le groupe du travail',
  'Gece 23:00–08:00 arası "Sabah yazarım" diye yanıtla':
      'Répondre « Je vous écris demain matin » entre 23:00 et 08:00',
  'Gece modu': 'Mode nuit',
  '23:00–08:00 otomatik yanıt': 'Réponse automatique de 23:00 à 08:00',
  'Gece otomatik yanıt': 'Réponse automatique de nuit',
  'Şu an uyuyorum, sabah dönerim 🌙':
      'Je dors, je vous réponds demain matin 🌙',
  'Meşgulüm': 'Occupé',
  'Herkese kısa yanıt': 'Réponse courte à tout le monde',
  'Şu an müsait değilim, birazdan yazarım.':
      'Je ne suis pas disponible pour le moment, je vous écris bientôt.',
  'Mesai dışı': 'Hors horaires',
  'Hafta içi 18:00–09:00': 'En semaine 18:00–09:00',
  'Mesai dışı yanıt': 'Réponse hors horaires',
  'Mesai saatleri dışındayım, yarın dönüş yapacağım.':
      'Je suis en dehors de mes horaires de travail, je vous réponds demain.',
  'Acil mesajlar': 'Messages urgents',
  '"acil", "hemen" geçenleri öne çıkar':
      'Met en avant ceux contenant « urgent », « vite »',
  'acil': 'urgent',
  'hemen': 'vite',
  'önemli': 'important',
  'ara beni': 'appelle-moi',
  'Hazır kurallar': 'Règles prêtes',
  'Mesajlarda ara': 'Rechercher dans les messages',
  'Bütün uygulamalardaki mesajlarda arar. En az iki harf yazın.':
      'Recherche dans les messages de toutes les applis. Saisissez au moins deux lettres.',
  'Sonuç bulunamadı.': 'Aucun résultat.',
  '{name} açılamadı.': 'Impossible d\'ouvrir {name}.',
  'Servisler nasıl çalışır?': 'Comment fonctionnent les services ?',
  'Her servis kendi resmi web sitesiyle, uygulamanın içindeki tarayıcıda açılır. Giriş bilgileriniz yalnızca bu telefonda kalır; Mesa yalnızca o servisin sunucusuyla konuşur.\n\nArka planda bağlı servisler uygulama kapalıyken de yeni mesajları bildirir ve mesajlar Sohbetler\'e düşer. Bunun için telefonun pil ayarında Mesa\'ya "Kısıtlama yok" verilmelidir. Her açık servis pil ve bellek harcar.\n\nInstagram, X ve LinkedIn gibi bazı siteler açıkken mesaj bildirimi göndermez; onlarda okunmamış sayısı arttığında haber verilir.\n\n"Google ile giriş" bu sayfalarda çalışmaz; e-posta ve şifreyle girin.':
      'Chaque service s\'ouvre avec son site officiel dans le navigateur intégré à l\'appli. Vos identifiants restent uniquement sur ce téléphone ; Mesa ne communique qu\'avec le serveur de ce service.\n\nLes services connectés en arrière-plan signalent les nouveaux messages même quand l\'appli est fermée, et les messages arrivent dans Discussions. Pour cela, Mesa doit être réglé sur « Aucune restriction » dans les paramètres de batterie du téléphone. Chaque service ouvert consomme de la batterie et de la mémoire.\n\nCertains sites comme Instagram, X et LinkedIn n\'envoient pas de notifications de message tant qu\'ils sont ouverts ; pour eux, vous êtes prévenu quand le nombre de non-lus augmente.\n\n« Se connecter avec Google » ne fonctionne pas sur ces pages ; connectez-vous avec e-mail et mot de passe.',
  '{unread} okunmamış': '{unread} non lus',
  'Tüm uygulamalar tek yerde': 'Toutes les applis au même endroit',
  'Uygulamalar': 'Applis',
  'Web servisleri': 'Services web',
  '{name} ayarları': 'Paramètres de {name}',
  'Okunmamış var': 'Messages non lus',
  'Bildirim kapalı': 'Notifications désactivées',
  'Arka planda bağlı': 'Connecté en arrière-plan',
  'Yalnızca açıkken': 'Seulement quand il est ouvert',
  'Henüz web servisi yok': 'Aucun service web pour l\'instant',
  'Telefonda uygulaması olmayan servisleri resmi web sürümleriyle buraya ekleyin. Yeni mesajlar Sohbetler\'e ve bildirimlere düşer.':
      'Ajoutez ici, avec leur version web officielle, les services qui n\'ont pas d\'appli sur ce téléphone. Les nouveaux messages arrivent dans Discussions et dans les notifications.',
  'Başka bir site': 'Autre site',
  'Adresini yazarak, ör. vk.com/im':
      'En saisissant son adresse, p. ex. vk.com/im',
  'KakaoTalk, Viber, LINE ve Signal\'in web sürümü yok. Uygulamaları telefona kurulursa mesajları bildirimlerden otomatik toplanır.':
      'KakaoTalk, Viber, LINE et Signal n\'ont pas de version web. Si leurs applis sont installées sur le téléphone, leurs messages sont récupérés automatiquement depuis les notifications.',
  'Ekli · ikinci hesap eklenir': 'Ajouté · ajoute un deuxième compte',
  'Uygulaması kurulu, bildirimleri zaten geliyor':
      'Appli installée, ses notifications arrivent déjà',
  'https ile açılan geçerli bir site adresi yazın.':
      'Saisissez une adresse de site valide commençant par https.',
  'Ad': 'Nom',
  'Adres': 'Adresse',
  '{name} oturumu kapatılsın mı?': 'Se déconnecter de {name} ?',
  'Bu servisin giriş bilgileri ve site verileri telefondan silinir. Yeniden giriş yapmanız gerekir.':
      'Les identifiants et données du site de ce service seront supprimés du téléphone. Vous devrez vous reconnecter.',
  'Oturumu kapat': 'Se déconnecter',
  '{name} kaldırılsın mı?': 'Retirer {name} ?',
  'Oturum ve site verileri telefondan silinir. Sohbetler\'deki eski mesajlar kalır.':
      'La session et les données du site seront supprimées du téléphone. Les anciens messages dans Discussions restent.',
  'Kaldır': 'Retirer',
  'Arka planda bağlı kalsın': 'Rester connecté en arrière-plan',
  'Uygulama kapalıyken de yeni mesajlar bildirilir; pil kullanımı artar':
      'Les nouveaux messages sont signalés même appli fermée ; consomme plus de batterie',
  'Bildirimler': 'Notifications',
  'Yeni mesajlar Sohbetler\'e ve bildirimlere':
      'Nouveaux messages dans Discussions et notifications',
  'Videolar kendiliğinden oynasın': 'Lecture automatique des vidéos',
  'Kapalıyken videolar dokununca oynar; sayfa daha akıcı olur':
      'Désactivée, les vidéos se lisent quand on les touche ; la page est plus fluide',
  'Eski mesajlar silinsin mi?': 'Supprimer les anciens messages ?',
  '{days} öncesine ait mesajlar ve görselleri Mesa\'dan kalıcı olarak silinecek. Kaynak uygulamalardaki mesajlara dokunulmaz.':
      'Les messages et images de plus de {days} seront supprimés définitivement de Mesa. Les messages dans les applis d\'origine ne sont pas touchés.',
  'Seçilen uygulamalarda yanıt, Mesa yeniden başlasa da doğrudan gider':
      'Dans les applis choisies, les réponses partent directement même si Mesa redémarre',
  'Kendi bildirimi de kalsın': 'Garder aussi sa propre notification',
  'Seçtiğiniz uygulamanın bildirimi çubuktan kaldırılmaz. Bildirim orada durdukça, Mesa yeniden başlasa da (güncelleme, telefonun yeniden açılması) o sohbete yanıt ve planlı mesaj uygulamaya geçmeden gider. Aynı mesaj için iki bildirim görürsünüz; Mesa\'nınki sessiz gelir.':
      'La notification de l\'appli choisie n\'est pas retirée de la barre d\'état. Tant qu\'elle y reste, les réponses et messages programmés vers cette discussion partent directement, sans ouvrir l\'appli, même si Mesa redémarre (mise à jour, redémarrage du téléphone). Vous verrez deux notifications pour le même message ; celle de Mesa arrive en silence.',
  'Ana ekranda boş bir yere basılı tutun → Bileşenler (Widget) → Mesa\'yı sürükleyip bırakın.':
      'Appuyez longuement sur un espace vide de l\'écran d\'accueil → Widgets → faites glisser Mesa.',
  'Birleşik bildirimler': 'Notifications unifiées',
  'Uygulamaların ayrı bildirimleri yerine kişi fotoğraflı, yanıtlanabilen tek tip bildirim':
      'Un seul type de notification avec la photo du contact, à laquelle vous pouvez répondre, au lieu des notifications séparées de chaque appli',
  'Önemli mesajlarda bildirim': 'Notifier les messages importants',
  '"Önemli işaretle" kuralına uyunca, sessizdekiler dahil':
      'Quand la règle « Marquer comme important » s\'applique, y compris en sourdine',
  'Ana ekran': 'Écran d\'accueil',
  'Ana ekran bileşeni': 'Widget d\'écran d\'accueil',
  'Okunmamışlar ve yanıt bekleyenler, uygulamayı açmadan':
      'Non lus et réponses en attente, sans ouvrir l\'appli',
  'Bağlantılar': 'Connexions',
  'Doğrudan bağlantı: sessiz gruplar ve geçmiş':
      'Connexion directe : groupes en sourdine et historique',
  'Telegram\'da gizli okuma': 'Lecture discrète sur Telegram',
  'Okuduğunuzda "görüldü", yazarken "yazıyor" gitmez':
      'Pas de « vu » quand vous lisez, pas de « écrit… » quand vous écrivez',
  'Telegram kanallarını gösterme': 'Masquer les chaînes Telegram',
  'Kişiler ve gruplar gelmeye devam eder':
      'Les personnes et les groupes continuent d\'arriver',
  'Okunan uygulamalar': 'Applis suivies',
  'Gizlilik': 'Confidentialité',
  'Görmeden okuma': 'Lire sans être vu',
  'WhatsApp, Instagram ve diğerlerinde mesajı burada okumak karşı tarafa "görüldü" göndermez. Yanıt verirseniz gider.':
      'Lire ici un message de WhatsApp, Instagram et autres n\'envoie pas « vu » à l\'expéditeur. C\'est envoyé si vous répondez.',
  'Silinen mesajlar korunur': 'Les messages supprimés sont conservés',
  'Gönderen mesajı silse de metni burada "silindi" etiketiyle kalır.':
      'Même si l\'expéditeur supprime un message, son texte reste ici avec l\'étiquette « supprimé ».',
  'Mesajları sakla': 'Conserver les messages',
  '{retentionDays} sonra silinir': 'Supprimés après {retentionDays}',
  'Yazma': 'Écriture',
  '{count} yanıt': '{count, plural, one{# réponse} other{# réponses}}',
  'Telefonda ekran kilidi ya da parmak izi tanımlı değil.':
      'Aucun verrouillage d\'écran ni empreinte n\'est configuré sur ce téléphone.',
  'Uygulama kilidini açmak için doğrulayın':
      'Confirmez pour activer le verrouillage de l\'appli',
  'Uygulama kilidi': 'Verrouillage de l\'appli',
  'Parmak izi, yüz tanıma ya da ekran kilidi':
      'Empreinte, reconnaissance faciale ou verrouillage d\'écran',
  'Yeni hazır yanıt': 'Nouvelle réponse rapide',
  'Hazır yanıt yok.': 'Aucune réponse rapide.',
  'Düzelt': 'Corriger',
  'Sistem durumu · her şey hazır': 'État du système · tout est prêt',
  'Sistem durumu · {problems} ayar eksik':
      'État du système · {problems, plural, one{# réglage manquant} other{# réglages manquants}}',
  'Bildirim erişimi': 'Accès aux notifications',
  'Mesajlar yakalanıyor': 'Les messages sont capturés',
  'İzin var ama sistem servisi bağlamadı':
      'Autorisé, mais le système n\'a pas connecté le service',
  'Mesajları okumak için gerekli': 'Nécessaire pour lire les messages',
  'Bağla': 'Connecter',
  'İzin ver': 'Autoriser',
  'Bildirim izni': 'Autorisation des notifications',
  'Yeni mesajlar bildirilir': 'Les nouveaux messages sont notifiés',
  'Kapalıysa yeni mesaj bildirimi görmezsiniz':
      'Si c\'est désactivé, vous ne verrez pas les notifications de nouveaux messages',
  'Pil kısıtlaması yok': 'Aucune restriction de batterie',
  'Arka planda kapatılmaz': 'N\'est pas fermé en arrière-plan',
  'Telefon uygulamayı arka planda kapatıp mesajları geciktirebilir':
      'Le téléphone peut fermer l\'appli en arrière-plan et retarder les messages',
  'Otomatik başlatma (Xiaomi)': 'Démarrage automatique (Xiaomi)',
  'Açık olmalı; telefon yeniden başlayınca da çalışsın':
      'Doit être activé pour fonctionner aussi après un redémarrage',
  'Kontrol et': 'Vérifier',
  'Mikrofon': 'Micro',
  'Sesli mesaj kaydedilebilir': 'Les messages vocaux peuvent être enregistrés',
  'Yalnızca sesli mesaj için; ilk kayıtta sorulur':
      'Seulement pour les messages vocaux ; demandé au premier enregistrement',
  'Tüm mesajlar tek tip, buradan yanıtlanabilen bildirimle':
      'Tous les messages dans un seul type de notification, avec réponse directe',
  'Kapalıysa yeni mesajları fark etmezsiniz':
      'Si c\'est désactivé, vous ne remarquerez pas les nouveaux messages',
  'Pil kısıtlamasını kaldır': 'Lever la restriction de batterie',
  'Arka planda kapatılmasın, mesajlar gecikmesin':
      'Pour qu\'elle ne soit pas fermée en arrière-plan et que les messages ne soient pas retardés',
  'Telefon yeniden açılınca da çalışsın':
      'Pour qu\'elle fonctionne aussi après un redémarrage',
  'Son uygulamalarda kilitle': 'Verrouiller dans les applis récentes',
  'Son uygulamalarda karta basılı tutup kilide dokunun; kilitsizken kaydırınca kapanıyor':
      'Dans les applis récentes, appuyez longuement sur la carte et touchez le cadenas ; sans verrou, la balayer ferme l\'appli',
  'Yaptım': 'C\'est fait',
  'WhatsApp\'a geçmeden yanıt': 'Répondre sans passer par WhatsApp',
  'Uygulama yeniden başlasa da yanıtlar doğrudan gitsin':
      'Les réponses partent directement même si l\'appli redémarre',
  'Kurulumu tamamla · {done}/{count}':
      'Terminer la configuration · {done}/{count}',
  'Mesajlar eksiksiz ve gecikmeden gelsin':
      'Pour que les messages arrivent complets et sans retard',
  'Sonra': 'Plus tard',
  'Telegram\'ı bağla · isteğe bağlı': 'Connecter Telegram · facultatif',
  'Sessiz gruplar ve geçmiş de gelsin':
      'Recevoir aussi les groupes en sourdine et l\'historique',
  'Daha az göster': 'Afficher moins',
  '{pending} adım daha':
      '{pending, plural, one{encore # étape} other{encore # étapes}}',
  'İsteğe bağlı adımlar': 'Étapes facultatives',
  'Henüz kaydedilen mesaj yok': 'Aucun message enregistré pour l\'instant',
  'Bir mesaja basılı tutup "Kaydet"e dokunun. Adres, kod, tarih gibi önemli mesajlar hangi uygulamadan gelirse gelsin burada toplanır.':
      'Appuyez longuement sur un message et touchez « Enregistrer ». Les messages importants comme les adresses, codes et dates se retrouvent ici, quelle que soit l\'appli d\'origine.',
  'Fotoğraflar ve profil resimleri': 'Photos et photos de profil',
  'Telegram önbelleği': 'Cache Telegram',
  'Geçici dosyalar': 'Fichiers temporaires',
  'Önbellek temizlensin mi?': 'Vider le cache ?',
  'Telegram\'da 7 gündür açılmamış fotoğraf ve videolar, web servislerinin önbelleği ve geçici dosyalar silinir. Mesajlar, kişiler ve oturumlar silinmez; Telegram medyası açınca yeniden iner.':
      'Les photos et vidéos Telegram non ouvertes depuis 7 jours, le cache des services web et les fichiers temporaires sont supprimés. Les messages, personnes et sessions ne sont pas supprimés ; les médias Telegram se retéléchargent à l\'ouverture.',
  'Temizle': 'Vider',
  '{freed} yer açıldı.': '{freed} libérés.',
  'Temizlenecek önbellek yoktu.': 'Il n\'y avait pas de cache à vider.',
  'Eski mesajları silmek için: saklama süresi.':
      'Pour supprimer les anciens messages : durée de conservation.',
  'Önbelleği temizle': 'Vider le cache',
  'Günlere göre': 'Par jour',
  'En çok yazıştıkların': 'Avec qui vous échangez le plus',
  '{count} mesaj · {name}':
      '{count, plural, one{# message} other{# messages}} · {name}',
  'Son 7 gün': '7 derniers jours',
  '{total} mesaj': '{total, plural, one{# message} other{# messages}}',
  '{incoming} gelen': '{incoming} reçus',
  '{outgoing} giden': '{outgoing} envoyés',
  '{people} kişi': '{people, plural, one{# personne} other{# personnes}}',
  '%{percent}': '{percent} %',
  'En yoğun saatin {hour}:00': 'Votre heure la plus active est {hour}:00',
  'Gelen her 10 mesaja {ratio} yanıt':
      '{ratio} réponses pour 10 messages reçus',
  'Gönderenin silip sende kalan {deleted} mesaj':
      '{deleted, plural, one{# message supprimé par l\'expéditeur, conservé pour vous} other{# messages supprimés par l\'expéditeur, conservés pour vous}}',
  'Bilgiler': 'Faits marquants',
  'Çıkartmalar': 'Autocollants',
  'Bu bölümde çıkartma yok.': 'Pas d\'autocollant dans cette section.',
  'GIF ara (boşsa kaydedilenler)': 'Rechercher des GIF (vide : enregistrés)',
  'Kaydedilmiş GIF yok. Yukarıdan arayabilirsiniz.':
      'Aucun GIF enregistré. Vous pouvez chercher ci-dessus.',
  'GIF bulunamadı.': 'Aucun GIF trouvé.',
  'Telegram bağlantısı kapatılsın mı?': 'Déconnecter Telegram ?',
  'Bu cihazın oturumu Telegram\'dan çıkarılır. Daha önce alınan mesajlar Mesa\'da kalır.':
      'La session de cet appareil sera retirée de Telegram. Les messages déjà reçus restent dans Mesa.',
  'Çıkış yap': 'Se déconnecter',
  'Telegram bağlantısı': 'Connexion Telegram',
  'Bu derlemede Telegram uygulama kimliği yok. my.telegram.org → "API development tools" bölümünden api_id ve api_hash alınıp android/local.properties dosyasına telegram.apiId ve telegram.apiHash olarak yazılmalı, ardından uygulama yeniden derlenmeli.':
      'Cette version n\'a pas d\'identifiant d\'appli Telegram. Obtenez un api_id et un api_hash sur my.telegram.org → « API development tools », écrivez-les dans android/local.properties sous telegram.apiId et telegram.apiHash, puis recompilez l\'appli.',
  '+90 5xx xxx xx xx': '+33 6 xx xx xx xx',
  'Devam': 'Continuer',
  'Telegram hesabınız bağlı. Sessizdeki gruplar dahil yeni mesajlar gelen kutusuna düşer. Bir sohbeti açınca son mesajları da indirilir.':
      'Votre compte Telegram est connecté. Les nouveaux messages, y compris des groupes en sourdine, arrivent dans la boîte de réception. Ouvrir une discussion télécharge aussi ses derniers messages.',
  'Bu giriş adımı desteklenmiyor.':
      'Cette étape de connexion n\'est pas prise en charge.',
  'Telegram hesabınızı bağlayın': 'Connectez votre compte Telegram',
  'Mesa, Telegram\'ın resmi kütüphanesiyle hesabınıza doğrudan bağlanır. Böylece bildirim üretmeyen sessiz grupların mesajları da gelir.':
      'Mesa se connecte directement à votre compte avec la bibliothèque officielle de Telegram : les messages des groupes en sourdine, qui ne créent pas de notification, arrivent donc aussi.',
  'Telegram\'a bağlan': 'Se connecter à Telegram',
  'Çıkış yapılıyor…': 'Déconnexion…',
  'Telegram\'a bağlanılıyor…': 'Connexion à Telegram…',
  'Telefon numaranız': 'Votre numéro de téléphone',
  'Doğrulama kodu': 'Code de vérification',
  'E-posta kodu': 'Code e-mail',
  'İki adımlı doğrulama şifresi':
      'Mot de passe de la validation en deux étapes',
  'Telefon numarası (ülke koduyla)':
      'Numéro de téléphone (avec indicatif du pays)',
  'Kod': 'Code',
  '• Bağlantı yalnızca Telegram sunucularına gider; mesajlar yalnızca bu telefonda saklanır.\n• Okundu bilgisi gönderilmez, çevrimiçi görünmezsiniz.\n• Bu cihaz Telegram\'da "Etkin oturumlar" listesinde görünür.\n• Bağlıyken bildirim çubuğunda sessiz bir "Telegram\'a bağlı" bildirimi durur.':
      '• La connexion va uniquement vers les serveurs de Telegram ; les messages sont stockés uniquement sur ce téléphone.\n• Les confirmations de lecture ne sont pas envoyées et vous n\'apparaissez pas en ligne.\n• Cet appareil apparaît dans la liste « Sessions actives » de Telegram.\n• Tant qu\'il est connecté, une notification silencieuse « Connecté à Telegram » reste dans la barre d\'état.',
  'Bir sohbete basılı tutun: sabitleyin, sonraya erteleyin ya da aynı kişinin başka uygulamadaki sohbetiyle birleştirin.':
      'Appuyez longuement sur une discussion : épinglez-la, reportez-la ou fusionnez-la avec la discussion de la même personne dans une autre appli.',
  'Gönder düğmesine basılı tutun: mesajı istediğiniz saate planlayın.':
      'Appuyez longuement sur le bouton d\'envoi : programmez le message à l\'heure de votre choix.',
  'Bir mesaja basılı tutup "Kaydet": tüm uygulamalardan kaydettikleriniz üstteki 🔖 listesinde.':
      'Appuyez longuement sur un message et touchez « Enregistrer » : ce que vous enregistrez depuis toutes les applis est dans la liste 🔖 en haut.',
  'Sohbetin üstündeki galeri düğmesi: o kişiyle paylaşılan tüm fotoğraf ve videolar tek yerde.':
      'Le bouton galerie en haut d\'une discussion : toutes les photos et vidéos échangées avec cette personne au même endroit.',
  'Bildirimden yazmadan yanıtlayın: hazır yanıtlarınız bildirimin altında tek dokunuşla. Listeyi Ayarlar → Hazır yanıtlar\'dan değiştirin.':
      'Répondez depuis la notification sans écrire : vos réponses rapides sont à un geste sous la notification. Modifiez la liste dans Paramètres → Réponses rapides.',
  'Ana ekran bileşeni: okunmamışlar ve yanıt bekleyenler uygulamayı açmadan. Ayarlar → Ana ekran → Ekle.':
      'Widget d\'écran d\'accueil : non lus et réponses en attente sans ouvrir l\'appli. Paramètres → Écran d\'accueil → Ajouter.',
  'Haftalık özet: kimlerle en çok yazıştığınızı üstteki grafik düğmesinden görün.':
      'Résumé de la semaine : voyez avec qui vous échangez le plus grâce au bouton graphique en haut.',
  'Günün ipucu': 'Astuce du jour',
  'Tüm mesajların tek yerde': 'Tous vos messages au même endroit',
  'WhatsApp, Telegram, Instagram, Discord ve diğerleri tek gelen kutusunda; uygulamalar arasında gidip gelmeden.':
      'WhatsApp, Telegram, Instagram, Discord et d\'autres dans une seule boîte de réception, sans passer d\'une appli à l\'autre.',
  'Bir kişi, tek sohbet': 'Une personne, une discussion',
  'Aynı kişiyle WhatsApp\'tan, Instagram\'dan, Telegram\'dan yazıştıklarınız tek zaman çizgisinde; yanıtı istediğiniz uygulamadan verin.':
      'Vos échanges avec la même personne sur WhatsApp, Instagram et Telegram sur une seule chronologie ; répondez depuis l\'appli de votre choix.',
  'Görüldü göndermeden oku': 'Lire sans envoyer « vu »',
  'WhatsApp ve Instagram mesajlarını burada okumak karşı tarafa "görüldü" göndermez; Telegram\'da da isteğe bağlı.':
      'Lire ici les messages WhatsApp et Instagram n\'envoie pas « vu » ; sur Telegram, c\'est aussi au choix.',
  'Silinen mesajın yazısı kalır': 'Le texte des messages supprimés reste',
  'Gönderen "herkesten sil" dese de yazdığı metin burada "silindi" etiketiyle durur.':
      'Même si l\'expéditeur choisit « Supprimer pour tout le monde », ce qu\'il a écrit reste ici avec l\'étiquette « supprimé ».',
  'Yanıt bekleyenler en üstte; sohbeti sonraya ertele, mesajı istediğin saate planla.':
      'Les réponses en attente en haut ; reportez une discussion, programmez un message à l\'heure de votre choix.',
  'Telefonunda kalır': 'Reste sur votre téléphone',
  'Mesajlar yalnızca bu telefonda saklanır; hiçbir sunucuya gönderilmez.':
      'Les messages sont stockés uniquement sur ce téléphone ; ils ne sont jamais envoyés à un serveur.',
  'Bildirim erişimini aç': 'Activer l\'accès aux notifications',
  'Mesa mesajları uygulamaların bildirimlerinden okur. Açılan listede Mesa\'yı bulup izin verin.':
      'Mesa lit les messages dans les notifications des applis. Trouvez Mesa dans la liste qui s\'ouvre et autorisez-le.',
  'İzin verilemiyor mu?': 'Impossible de l\'activer ?',
  'Android, mağaza dışından kurulan uygulamalarda bu izni kısıtlar. Mesa\'nın anahtarına bir kez dokunun, sonra Uygulama bilgileri → ⋮ → Kısıtlanmış ayarlara izin ver\'i seçip tekrar deneyin.':
      'Android restreint cette autorisation pour les applis installées hors d\'une boutique. Touchez une fois l\'interrupteur de Mesa, puis ouvrez Infos sur l\'appli → ⋮ → Autoriser les paramètres restreints et réessayez.',
  'Uygulama bilgileri': 'Infos sur l\'appli',
};
