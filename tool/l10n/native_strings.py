"""res/values*/strings.xml üretir (values = İngilizce, values-tr = Türkçe, …).

Her girdi: ad → {dil: metin}; çoğul girdilerde metin {kategori: metin}.
"""
import os
import sys

sys.stdout.reconfigure(encoding="utf-8")
RES = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "android", "app", "src", "main", "res")) + "/"
LANGS = ["en", "tr", "es", "pt", "de", "fr", "ar", "ru"]

S = {}  # ad -> {dil: metin}
P = {}  # ad -> {dil: {kategori: metin}}


def s(name, **t):
    assert set(t) == set(LANGS), (name, set(LANGS) - set(t))
    S[name] = t


def p(name, **t):
    assert set(t) == set(LANGS), (name, set(LANGS) - set(t))
    P[name] = t


# ---- Bildirimler ----
s("notif_you", en="You", tr="Siz", es="Tú", pt="Você", de="Du", fr="Vous", ar="أنت", ru="Вы")
s("notif_reply_label", en="Write a reply", tr="Yanıt yaz", es="Escribe una respuesta", pt="Escreva uma resposta", de="Antwort schreiben", fr="Écrire une réponse", ar="اكتب ردًا", ru="Написать ответ")
s("notif_reply", en="Reply", tr="Yanıtla", es="Responder", pt="Responder", de="Antworten", fr="Répondre", ar="رد", ru="Ответить")
s("notif_mark_read", en="Mark as read", tr="Okundu", es="Marcar como leído", pt="Marcar como lida", de="Als gelesen markieren", fr="Marquer comme lu", ar="تعليم كمقروءة", ru="Прочитано")
p("notif_new", en={"one": "%d new", "other": "%d new"}, tr={"one": "%d yeni", "other": "%d yeni"},
  es={"one": "%d nuevo", "other": "%d nuevos"}, pt={"one": "%d nova", "other": "%d novas"},
  de={"one": "%d neue", "other": "%d neue"}, fr={"one": "%d nouveau", "other": "%d nouveaux"},
  ar={"zero": "%d جديدة", "one": "رسالة جديدة", "two": "رسالتان جديدتان", "few": "%d رسائل جديدة", "many": "%d رسالة جديدة", "other": "%d رسالة جديدة"},
  ru={"one": "%d новое", "few": "%d новых", "many": "%d новых", "other": "%d новых"})
s("channel_messages", en="Messages", tr="Mesajlar", es="Mensajes", pt="Mensagens", de="Nachrichten", fr="Messages", ar="الرسائل", ru="Сообщения")
s("channel_messages_desc", en="Messages from all apps", tr="Tüm uygulamalardan gelen mesajlar", es="Mensajes de todas las apps", pt="Mensagens de todos os apps", de="Nachrichten aus allen Apps", fr="Messages de toutes les applis", ar="رسائل من كل التطبيقات", ru="Сообщения из всех приложений")
s("channel_important", en="Important messages", tr="Önemli mesajlar", es="Mensajes importantes", pt="Mensagens importantes", de="Wichtige Nachrichten", fr="Messages importants", ar="الرسائل المهمة", ru="Важные сообщения")
s("channel_important_desc", en="Messages matching the \"Mark important\" rule", tr="\"Önemli işaretle\" kuralına uyan mesajlar", es="Mensajes que cumplen la regla \"Marcar como importante\"", pt="Mensagens que seguem a regra \"Marcar como importante\"", de="Nachrichten, auf die die Regel „Als wichtig markieren“ zutrifft", fr="Messages correspondant à la règle « Marquer comme important »", ar="الرسائل التي تنطبق عليها قاعدة \"وضع علامة مهم\"", ru="Сообщения, подходящие под правило «Отметить как важное»")
s("reply_failed_title", en="Reply not sent", tr="Yanıt gönderilemedi", es="No se envió la respuesta", pt="A resposta não foi enviada", de="Antwort nicht gesendet", fr="Réponse non envoyée", ar="لم يُرسل الرد", ru="Ответ не отправлен")
s("reply_failed_text", en="Open the chat in the source app and reply there.", tr="Sohbeti kaynak uygulamada açıp oradan yanıtlayın.", es="Abre el chat en la app de origen y responde desde allí.", pt="Abra a conversa no app de origem e responda por lá.", de="Öffne den Chat in der Quell-App und antworte dort.", fr="Ouvrez la discussion dans l'appli d'origine et répondez-y.", ar="افتح المحادثة في التطبيق المصدر ورد من هناك.", ru="Откройте чат в исходном приложении и ответьте там.")
s("channel_reminders", en="Reminders", tr="Hatırlatmalar", es="Recordatorios", pt="Lembretes", de="Erinnerungen", fr="Rappels", ar="التذكيرات", ru="Напоминания")
s("channel_reminders_desc", en="Remind later and scheduled messages", tr="Sonra hatırlat ve planlı mesajlar", es="Recordar más tarde y mensajes programados", pt="Lembrar mais tarde e mensagens agendadas", de="Später erinnern und geplante Nachrichten", fr="Rappels et messages programmés", ar="التذكير لاحقًا والرسائل المجدولة", ru="Напоминания и запланированные сообщения")
s("reminder_text", en="Don't forget to get back to them", tr="Dönüş yapmayı unutmayın", es="No olvides responder", pt="Não se esqueça de responder", de="Vergiss nicht zu antworten", fr="N'oubliez pas de répondre", ar="لا تنسَ الرد", ru="Не забудьте ответить")
s("scheduled_sent", en="Scheduled message sent", tr="Planlı mesaj gönderildi", es="Mensaje programado enviado", pt="Mensagem agendada enviada", de="Geplante Nachricht gesendet", fr="Message programmé envoyé", ar="أُرسلت الرسالة المجدولة", ru="Запланированное сообщение отправлено")
s("scheduled_due_title", en="Time to send the scheduled message: %1$s", tr="Planlı mesajın zamanı geldi: %1$s", es="Es hora de enviar el mensaje programado: %1$s", pt="Hora de enviar a mensagem agendada: %1$s", de="Zeit für die geplante Nachricht: %1$s", fr="C'est l'heure du message programmé : %1$s", ar="حان وقت الرسالة المجدولة: %1$s", ru="Пора отправить запланированное сообщение: %1$s")
s("scheduled_due_text", en="Tap to open %1$s with the message typed: %2$s", tr="Dokununca %1$s mesaj yazılmış olarak açılır: %2$s", es="Toca para abrir %1$s con el mensaje escrito: %2$s", pt="Toque para abrir o %1$s com a mensagem escrita: %2$s", de="Tippe, um %1$s mit der fertigen Nachricht zu öffnen: %2$s", fr="Touchez pour ouvrir %1$s avec le message rédigé : %2$s", ar="المس لفتح %1$s والرسالة مكتوبة: %2$s", ru="Нажмите, чтобы открыть %1$s с готовым сообщением: %2$s")
s("send", en="Send", tr="Gönder", es="Enviar", pt="Enviar", de="Senden", fr="Envoyer", ar="إرسال", ru="Отправить")
s("channel_connections", en="Connections", tr="Bağlantılar", es="Conexiones", pt="Conexões", de="Verbindungen", fr="Connexions", ar="الاتصالات", ru="Подключения")
s("channel_connections_desc", en="Persistent notification shown while Telegram and web services are connected", tr="Telegram ve web servisleri bağlıyken gösterilen kalıcı bildirim", es="Notificación fija que se muestra mientras Telegram y los servicios web están conectados", pt="Notificação fixa exibida enquanto o Telegram e os serviços web estão conectados", de="Dauerhafte Benachrichtigung, solange Telegram und Webdienste verbunden sind", fr="Notification permanente affichée tant que Telegram et les services web sont connectés", ar="إشعار دائم يظهر أثناء اتصال Telegram وخدمات الويب", ru="Постоянное уведомление, пока подключены Telegram и веб-сервисы")
s("connected_one", en="%1$s connected", tr="%1$s bağlı", es="%1$s conectado", pt="%1$s conectado", de="%1$s verbunden", fr="%1$s connecté", ar="%1$s متصل", ru="%1$s подключён")
p("connected_services", en={"one": "%d service connected", "other": "%d services connected"}, tr={"one": "%d servis bağlı", "other": "%d servis bağlı"},
  es={"one": "%d servicio conectado", "other": "%d servicios conectados"}, pt={"one": "%d serviço conectado", "other": "%d serviços conectados"},
  de={"one": "%d Dienst verbunden", "other": "%d Dienste verbunden"}, fr={"one": "%d service connecté", "other": "%d services connectés"},
  ar={"zero": "%d خدمات متصلة", "one": "خدمة واحدة متصلة", "two": "خدمتان متصلتان", "few": "%d خدمات متصلة", "many": "%d خدمة متصلة", "other": "%d خدمة متصلة"},
  ru={"one": "Подключён %d сервис", "few": "Подключено %d сервиса", "many": "Подключено %d сервисов", "other": "Подключено %d сервиса"})
s("connected_text", en="New messages are coming into Mesa", tr="Yeni mesajlar Mesa'ya alınıyor", es="Los mensajes nuevos llegan a Mesa", pt="As novas mensagens estão chegando ao Mesa", de="Neue Nachrichten kommen in Mesa an", fr="Les nouveaux messages arrivent dans Mesa", ar="تصل الرسائل الجديدة إلى Mesa", ru="Новые сообщения поступают в Mesa")

# ---- Web servisleri ----
p("web_unread", en={"one": "%d unread", "other": "%d unread"}, tr={"one": "%d okunmamış", "other": "%d okunmamış"},
  es={"one": "%d sin leer", "other": "%d sin leer"}, pt={"one": "%d não lida", "other": "%d não lidas"},
  de={"one": "%d ungelesen", "other": "%d ungelesen"}, fr={"one": "%d non lu", "other": "%d non lus"},
  ar={"zero": "%d غير مقروءة", "one": "رسالة غير مقروءة", "two": "رسالتان غير مقروءتين", "few": "%d رسائل غير مقروءة", "many": "%d رسالة غير مقروءة", "other": "%d رسالة غير مقروءة"},
  ru={"one": "%d непрочитанное", "few": "%d непрочитанных", "many": "%d непрочитанных", "other": "%d непрочитанных"})
s("web_new_unread", en="New unread messages", tr="Yeni okunmamış var", es="Hay mensajes nuevos sin leer", pt="Há novas mensagens não lidas", de="Neue ungelesene Nachrichten", fr="Nouveaux messages non lus", ar="توجد رسائل جديدة غير مقروءة", ru="Есть новые непрочитанные")
s("web_new_notification", en="New notification", tr="Yeni bildirim", es="Notificación nueva", pt="Nova notificação", de="Neue Benachrichtigung", fr="Nouvelle notification", ar="إشعار جديد", ru="Новое уведомление")
s("web_downloading", en="Downloading: %1$s", tr="İndiriliyor: %1$s", es="Descargando: %1$s", pt="Baixando: %1$s", de="Wird heruntergeladen: %1$s", fr="Téléchargement : %1$s", ar="جارٍ التنزيل: %1$s", ru="Загрузка: %1$s")
s("web_download_failed", en="Couldn't start the download.", tr="İndirme başlatılamadı.", es="No se pudo iniciar la descarga.", pt="Não foi possível iniciar o download.", de="Download konnte nicht gestartet werden.", fr="Impossible de lancer le téléchargement.", ar="تعذّر بدء التنزيل.", ru="Не удалось начать загрузку.")
s("web_cannot_download", en="This file can't be downloaded here.", tr="Bu dosya buradan indirilemiyor.", es="Este archivo no se puede descargar aquí.", pt="Este arquivo não pode ser baixado aqui.", de="Diese Datei kann hier nicht heruntergeladen werden.", fr="Ce fichier ne peut pas être téléchargé ici.", ar="لا يمكن تنزيل هذا الملف من هنا.", ru="Этот файл нельзя скачать здесь.")
s("lock_needs_screen_lock", en="Set up a screen lock on the phone to unlock", tr="Kilidi açmak için telefonda ekran kilidi gerekli", es="Para desbloquear, configura un bloqueo de pantalla en el teléfono", pt="Para desbloquear, configure um bloqueio de tela no celular", de="Zum Entsperren wird eine Displaysperre auf dem Telefon benötigt", fr="Pour déverrouiller, configurez un verrouillage d'écran sur le téléphone", ar="لفتح القفل يلزم قفل شاشة على الهاتف", ru="Чтобы разблокировать, настройте блокировку экрана на телефоне")
s("locked_title", en="Mesa is locked", tr="Mesa kilitli", es="Mesa está bloqueado", pt="O Mesa está bloqueado", de="Mesa ist gesperrt", fr="Mesa est verrouillé", ar="Mesa مقفل", ru="Mesa заблокирован")
s("verify_to_continue", en="Verify your identity to continue", tr="Devam etmek için kimliğinizi doğrulayın", es="Verifica tu identidad para continuar", pt="Confirme sua identidade para continuar", de="Bestätige deine Identität, um fortzufahren", fr="Confirmez votre identité pour continuer", ar="أكّد هويتك للمتابعة", ru="Подтвердите личность, чтобы продолжить")
s("unlock", en="Unlock", tr="Kilidi aç", es="Desbloquear", pt="Desbloquear", de="Entsperren", fr="Déverrouiller", ar="فتح القفل", ru="Разблокировать")
s("back", en="Back", tr="Geri", es="Atrás", pt="Voltar", de="Zurück", fr="Retour", ar="رجوع", ru="Назад")
s("menu_reload", en="Reload", tr="Yenile", es="Recargar", pt="Recarregar", de="Neu laden", fr="Actualiser", ar="إعادة التحميل", ru="Обновить")
s("menu_home", en="Back to home page", tr="Ana sayfaya dön", es="Volver a la página de inicio", pt="Voltar à página inicial", de="Zur Startseite", fr="Retour à l'accueil", ar="العودة إلى الصفحة الرئيسية", ru="На главную страницу")
s("menu_browser", en="Open in browser", tr="Tarayıcıda aç", es="Abrir en el navegador", pt="Abrir no navegador", de="Im Browser öffnen", fr="Ouvrir dans le navigateur", ar="فتح في المتصفح", ru="Открыть в браузере")
s("menu_desktop", en="Desktop view", tr="Masaüstü görünüm", es="Vista de escritorio", pt="Versão para computador", de="Desktopansicht", fr="Version ordinateur", ar="عرض سطح المكتب", ru="Версия для ПК")
s("menu_fit", en="Fit page to screen", tr="Sayfayı ekrana sığdır", es="Ajustar la página a la pantalla", pt="Ajustar a página à tela", de="Seite an Bildschirm anpassen", fr="Ajuster la page à l'écran", ar="ملاءمة الصفحة للشاشة", ru="Вместить страницу в экран")
s("menu_autoplay", en="Autoplay videos", tr="Videolar kendiliğinden oynasın", es="Reproducir vídeos automáticamente", pt="Reproduzir vídeos automaticamente", de="Videos automatisch abspielen", fr="Lecture automatique des vidéos", ar="تشغيل الفيديوهات تلقائيًا", ru="Автовоспроизведение видео")
s("menu_zoom", en="Text size", tr="Yazı boyutu", es="Tamaño del texto", pt="Tamanho do texto", de="Textgröße", fr="Taille du texte", ar="حجم النص", ru="Размер текста")
s("menu_logout", en="Sign out", tr="Oturumu kapat", es="Cerrar sesión", pt="Sair", de="Abmelden", fr="Se déconnecter", ar="تسجيل الخروج", ru="Выйти")
s("cancel", en="Cancel", tr="Vazgeç", es="Cancelar", pt="Cancelar", de="Abbrechen", fr="Annuler", ar="إلغاء", ru="Отмена")
s("logout_title", en="Sign out of %1$s?", tr="%1$s oturumu kapatılsın mı?", es="¿Cerrar sesión en %1$s?", pt="Sair do %1$s?", de="Von %1$s abmelden?", fr="Se déconnecter de %1$s ?", ar="هل تريد تسجيل الخروج من %1$s؟", ru="Выйти из %1$s?")
s("logout_message", en="This service's sign-in details and site data will be deleted from the phone. You'll need to sign in again.", tr="Bu servisin giriş bilgileri ve site verileri telefondan silinir. Yeniden giriş yapmanız gerekir.", es="Los datos de acceso y del sitio de este servicio se borrarán del teléfono. Tendrás que volver a iniciar sesión.", pt="Os dados de login e do site deste serviço serão apagados do celular. Você vai precisar entrar de novo.", de="Die Anmeldedaten und Websitedaten dieses Dienstes werden vom Telefon gelöscht. Du musst dich neu anmelden.", fr="Les identifiants et données du site de ce service seront supprimés du téléphone. Vous devrez vous reconnecter.", ar="ستُحذف بيانات تسجيل الدخول وبيانات الموقع لهذه الخدمة من الهاتف. ستحتاج إلى تسجيل الدخول مجددًا.", ru="Данные для входа и данные сайта этого сервиса будут удалены с телефона. Нужно будет войти заново.")

# ---- Ana ekran bileşeni ----
s("widget_label", en="Messages", tr="Mesajlar", es="Mensajes", pt="Mensagens", de="Nachrichten", fr="Messages", ar="الرسائل", ru="Сообщения")
s("widget_description", en="Unread and awaiting reply, without opening the app", tr="Okunmamışlar ve yanıt bekleyenler, uygulamayı açmadan", es="No leídos y pendientes de respuesta, sin abrir la app", pt="Não lidas e aguardando resposta, sem abrir o app", de="Ungelesene und wartende Antworten, ohne die App zu öffnen", fr="Non lus et réponses en attente, sans ouvrir l'appli", ar="غير المقروءة ومن ينتظر الرد، دون فتح التطبيق", ru="Непрочитанные и ожидающие ответа — без открытия приложения")
s("widget_yesterday", en="Yesterday", tr="Dün", es="Ayer", pt="Ontem", de="Gestern", fr="Hier", ar="أمس", ru="Вчера")
s("widget_locked", en="🔒 App is locked", tr="🔒 Uygulama kilitli", es="🔒 La app está bloqueada", pt="🔒 O app está bloqueado", de="🔒 App ist gesperrt", fr="🔒 L'appli est verrouillée", ar="🔒 التطبيق مقفل", ru="🔒 Приложение заблокировано")
p("widget_waiting", en={"one": "⏳ %d person awaiting a reply", "other": "⏳ %d people awaiting a reply"}, tr={"one": "⏳ %d kişi yanıt bekliyor", "other": "⏳ %d kişi yanıt bekliyor"},
  es={"one": "⏳ %d persona espera respuesta", "other": "⏳ %d personas esperan respuesta"}, pt={"one": "⏳ %d pessoa aguarda resposta", "other": "⏳ %d pessoas aguardam resposta"},
  de={"one": "⏳ %d Person wartet auf Antwort", "other": "⏳ %d Personen warten auf Antwort"}, fr={"one": "⏳ %d personne attend une réponse", "other": "⏳ %d personnes attendent une réponse"},
  ar={"zero": "⏳ لا أحد ينتظر الرد", "one": "⏳ شخص واحد ينتظر الرد", "two": "⏳ شخصان ينتظران الرد", "few": "⏳ %d أشخاص ينتظرون الرد", "many": "⏳ %d شخصًا ينتظرون الرد", "other": "⏳ %d شخص ينتظرون الرد"},
  ru={"one": "⏳ %d человек ждёт ответа", "few": "⏳ %d человека ждут ответа", "many": "⏳ %d человек ждут ответа", "other": "⏳ %d человека ждут ответа"})
s("widget_all_read", en="All read", tr="Hepsi okundu", es="Todo leído", pt="Tudo lido", de="Alles gelesen", fr="Tout est lu", ar="تمت قراءة الكل", ru="Всё прочитано")
s("widget_tagline", en="All your messages in one place", tr="Tüm mesajların tek yerde", es="Todos tus mensajes en un solo lugar", pt="Todas as suas mensagens em um só lugar", de="Alle deine Nachrichten an einem Ort", fr="Tous vos messages au même endroit", ar="كل رسائلك في مكان واحد", ru="Все сообщения в одном месте")
s("widget_open_to_see", en="Open the app to see messages", tr="Mesajları görmek için açın", es="Abre la app para ver los mensajes", pt="Abra o app para ver as mensagens", de="Öffne die App, um Nachrichten zu sehen", fr="Ouvrez l'appli pour voir les messages", ar="افتح التطبيق لرؤية الرسائل", ru="Откройте приложение, чтобы увидеть сообщения")
s("widget_empty", en="No messages yet", tr="Henüz mesaj yok", es="Aún no hay mensajes", pt="Ainda não há mensagens", de="Noch keine Nachrichten", fr="Aucun message pour l'instant", ar="لا توجد رسائل بعد", ru="Сообщений пока нет")

# ---- Telegram ----
s("tg_typing", en="typing…", tr="yazıyor…", es="escribiendo…", pt="digitando…", de="schreibt…", fr="écrit…", ar="يكتب…", ru="печатает…")
s("tg_recording_voice", en="recording a voice message…", tr="sesli mesaj kaydediyor…", es="grabando un audio…", pt="gravando áudio…", de="nimmt eine Sprachnachricht auf…", fr="enregistre un message vocal…", ar="يسجل رسالة صوتية…", ru="записывает голосовое…")
s("tg_sending_voice", en="sending a voice message…", tr="sesli mesaj gönderiyor…", es="enviando un audio…", pt="enviando áudio…", de="sendet eine Sprachnachricht…", fr="envoie un message vocal…", ar="يرسل رسالة صوتية…", ru="отправляет голосовое…")
s("tg_sending_photo", en="sending a photo…", tr="fotoğraf gönderiyor…", es="enviando una foto…", pt="enviando foto…", de="sendet ein Foto…", fr="envoie une photo…", ar="يرسل صورة…", ru="отправляет фото…")
s("tg_sending_video", en="sending a video…", tr="video gönderiyor…", es="enviando un vídeo…", pt="enviando vídeo…", de="sendet ein Video…", fr="envoie une vidéo…", ar="يرسل فيديو…", ru="отправляет видео…")
s("tg_recording_video_note", en="recording a video message…", tr="görüntülü mesaj kaydediyor…", es="grabando un videomensaje…", pt="gravando mensagem de vídeo…", de="nimmt eine Videonachricht auf…", fr="enregistre un message vidéo…", ar="يسجل رسالة فيديو…", ru="записывает видеосообщение…")
s("tg_sending_file", en="sending a file…", tr="dosya gönderiyor…", es="enviando un archivo…", pt="enviando arquivo…", de="sendet eine Datei…", fr="envoie un fichier…", ar="يرسل ملفًا…", ru="отправляет файл…")
s("tg_choosing_sticker", en="choosing a sticker…", tr="çıkartma seçiyor…", es="eligiendo un sticker…", pt="escolhendo figurinha…", de="wählt einen Sticker…", fr="choisit un autocollant…", ar="يختار ملصقًا…", ru="выбирает стикер…")
s("tg_hint_email", en="The verification code was sent to %1$s.", tr="Doğrulama kodu %1$s adresine gönderildi.", es="El código de verificación se envió a %1$s.", pt="O código de verificação foi enviado para %1$s.", de="Der Bestätigungscode wurde an %1$s gesendet.", fr="Le code de vérification a été envoyé à %1$s.", ar="أُرسل رمز التحقق إلى %1$s.", ru="Код подтверждения отправлен на %1$s.")
s("tg_hint_password", en="Password hint: %1$s", tr="Şifre ipucu: %1$s", es="Pista de la contraseña: %1$s", pt="Dica da senha: %1$s", de="Passworthinweis: %1$s", fr="Indice du mot de passe : %1$s", ar="تلميح كلمة المرور: %1$s", ru="Подсказка к паролю: %1$s")
s("tg_hint_unsupported", en="The sign-in step required for this account isn't supported yet (%1$s). Sign in from the Telegram app and try again.", tr="Bu hesap için istenen giriş adımı henüz desteklenmiyor (%1$s). Telegram uygulamasından giriş yapıp tekrar deneyin.", es="El paso de inicio de sesión que pide esta cuenta aún no es compatible (%1$s). Inicia sesión desde la app de Telegram y vuelve a intentarlo.", pt="A etapa de login exigida por esta conta ainda não é compatível (%1$s). Entre pelo app do Telegram e tente de novo.", de="Der für dieses Konto nötige Anmeldeschritt wird noch nicht unterstützt (%1$s). Melde dich in der Telegram-App an und versuch es erneut.", fr="L'étape de connexion demandée pour ce compte n'est pas encore prise en charge (%1$s). Connectez-vous depuis l'appli Telegram et réessayez.", ar="خطوة تسجيل الدخول المطلوبة لهذا الحساب غير مدعومة بعد (%1$s). سجّل الدخول من تطبيق Telegram ثم حاول مجددًا.", ru="Шаг входа, который требуется для этого аккаунта, пока не поддерживается (%1$s). Войдите в приложении Telegram и попробуйте снова.")
s("tg_code_app", en="The code was sent as a message to your Telegram app (your session on another device).", tr="Kod, Telegram uygulamanıza (başka bir cihazdaki oturumunuza) mesaj olarak gönderildi.", es="El código se envió como mensaje a tu app de Telegram (tu sesión en otro dispositivo).", pt="O código foi enviado como mensagem para o seu app do Telegram (sua sessão em outro aparelho).", de="Der Code wurde als Nachricht an deine Telegram-App gesendet (deine Sitzung auf einem anderen Gerät).", fr="Le code a été envoyé en message dans votre appli Telegram (votre session sur un autre appareil).", ar="أُرسل الرمز كرسالة إلى تطبيق Telegram لديك (جلستك على جهاز آخر).", ru="Код отправлен сообщением в ваше приложение Telegram (в сеанс на другом устройстве).")
s("tg_code_sms", en="The code was sent by SMS.", tr="Kod SMS ile gönderildi.", es="El código se envió por SMS.", pt="O código foi enviado por SMS.", de="Der Code wurde per SMS gesendet.", fr="Le code a été envoyé par SMS.", ar="أُرسل الرمز برسالة SMS.", ru="Код отправлен по SMS.")
s("tg_code_call", en="You'll get the code in a phone call.", tr="Kod sesli arama ile bildirilecek.", es="Recibirás el código en una llamada.", pt="Você vai receber o código por ligação.", de="Du bekommst den Code per Anruf.", fr="Vous recevrez le code par appel.", ar="ستتلقى الرمز في مكالمة هاتفية.", ru="Код сообщат в телефонном звонке.")
s("tg_code_other", en="Enter the verification code Telegram sent you.", tr="Telegram'ın gönderdiği doğrulama kodunu girin.", es="Escribe el código de verificación que te envió Telegram.", pt="Digite o código de verificação que o Telegram enviou.", de="Gib den Bestätigungscode ein, den Telegram dir geschickt hat.", fr="Saisissez le code de vérification envoyé par Telegram.", ar="أدخل رمز التحقق الذي أرسله Telegram.", ru="Введите код подтверждения, который прислал Telegram.")
s("tg_not_connected", en="The Telegram connection is not open.", tr="Telegram bağlantısı açık değil.", es="La conexión con Telegram no está abierta.", pt="A conexão com o Telegram não está aberta.", de="Die Telegram-Verbindung ist nicht offen.", fr="La connexion à Telegram n'est pas ouverte.", ar="الاتصال بـ Telegram غير مفتوح.", ru="Подключение к Telegram не открыто.")
s("tg_err_phone", en="Invalid phone number. Enter it with the country code: +1…", tr="Telefon numarası geçersiz. Ülke koduyla girin: +90…", es="Número de teléfono no válido. Escríbelo con el prefijo del país: +34…", pt="Número de telefone inválido. Digite com o código do país: +55…", de="Ungültige Telefonnummer. Gib sie mit Ländervorwahl ein: +49…", fr="Numéro de téléphone non valide. Saisissez-le avec l'indicatif du pays : +33…", ar="رقم الهاتف غير صالح. أدخله مع رمز البلد: +966…", ru="Неверный номер телефона. Введите его с кодом страны: +7…")
s("tg_err_code", en="Wrong code.", tr="Kod hatalı.", es="Código incorrecto.", pt="Código incorreto.", de="Falscher Code.", fr="Code incorrect.", ar="الرمز غير صحيح.", ru="Неверный код.")
s("tg_err_code_expired", en="The code has expired. Enter the number again.", tr="Kodun süresi doldu. Numarayı yeniden girin.", es="El código caducó. Vuelve a escribir el número.", pt="O código expirou. Digite o número de novo.", de="Der Code ist abgelaufen. Gib die Nummer erneut ein.", fr="Le code a expiré. Saisissez à nouveau le numéro.", ar="انتهت صلاحية الرمز. أدخل الرقم مجددًا.", ru="Срок действия кода истёк. Введите номер заново.")
s("tg_err_password", en="Wrong password.", tr="Şifre hatalı.", es="Contraseña incorrecta.", pt="Senha incorreta.", de="Falsches Passwort.", fr="Mot de passe incorrect.", ar="كلمة المرور غير صحيحة.", ru="Неверный пароль.")
s("tg_err_email_code", en="Wrong email code.", tr="E-posta kodu hatalı.", es="Código del correo incorrecto.", pt="Código do e-mail incorreto.", de="Falscher E-Mail-Code.", fr="Code e-mail incorrect.", ar="رمز البريد الإلكتروني غير صحيح.", ru="Неверный код из письма.")
s("tg_err_flood", en="Too many attempts. Wait a while and try again.", tr="Çok fazla deneme yapıldı. Bir süre bekleyip tekrar deneyin.", es="Demasiados intentos. Espera un poco y vuelve a intentarlo.", pt="Tentativas demais. Espere um pouco e tente de novo.", de="Zu viele Versuche. Warte eine Weile und versuch es erneut.", fr="Trop de tentatives. Patientez un moment et réessayez.", ar="محاولات كثيرة جدًا. انتظر قليلًا ثم حاول مجددًا.", ru="Слишком много попыток. Подождите немного и попробуйте снова.")
s("tg_recent_stickers", en="Recently used", tr="Son kullanılanlar", es="Usados recientemente", pt="Usadas recentemente", de="Zuletzt verwendet", fr="Récemment utilisés", ar="المستخدمة مؤخرًا", ru="Недавние")
s("tg_deleted_account", en="Deleted account", tr="Silinmiş hesap", es="Cuenta eliminada", pt="Conta excluída", de="Gelöschtes Konto", fr="Compte supprimé", ar="حساب محذوف", ru="Удалённый аккаунт")

# ---- Yedek ----
s("backup_not_backup", en="Not a Mesa backup", tr="Mesa yedeği değil", es="No es una copia de Mesa", pt="Não é um backup do Mesa", de="Keine Mesa-Sicherung", fr="Ce n'est pas une sauvegarde Mesa", ar="ليست نسخة احتياطية من Mesa", ru="Это не резервная копия Mesa")
s("backup_version", en="This backup can't be opened with this version", tr="Yedek bu sürümle açılamıyor", es="Esta copia no se puede abrir con esta versión", pt="Este backup não pode ser aberto nesta versão", de="Diese Sicherung lässt sich mit dieser Version nicht öffnen", fr="Cette sauvegarde ne peut pas être ouverte avec cette version", ar="لا يمكن فتح هذه النسخة بهذا الإصدار", ru="Эту копию нельзя открыть в этой версии")
s("backup_corrupted", en="The backup is corrupted", tr="Yedek bozuk", es="La copia está dañada", pt="O backup está corrompido", de="Die Sicherung ist beschädigt", fr="La sauvegarde est endommagée", ar="النسخة الاحتياطية تالفة", ru="Копия повреждена")
s("backup_truncated", en="The backup is incomplete (the end of the file is cut off)", tr="Yedek eksik (dosyanın sonu kesilmiş)", es="La copia está incompleta (falta el final del archivo)", pt="O backup está incompleto (o fim do arquivo foi cortado)", de="Die Sicherung ist unvollständig (das Dateiende fehlt)", fr="La sauvegarde est incomplète (la fin du fichier est coupée)", ar="النسخة الاحتياطية ناقصة (نهاية الملف مقطوعة)", ru="Копия неполная (конец файла обрезан)")
s("backup_tampered", en="The backup has been modified", tr="Yedek değiştirilmiş", es="La copia ha sido modificada", pt="O backup foi alterado", de="Die Sicherung wurde verändert", fr="La sauvegarde a été modifiée", ar="تم تعديل النسخة الاحتياطية", ru="Копия была изменена")
s("backup_no_db", en="The backup has no message database", tr="Yedekte mesaj veritabanı yok", es="La copia no tiene base de datos de mensajes", pt="O backup não tem banco de dados de mensagens", de="Die Sicherung enthält keine Nachrichtendatenbank", fr="La sauvegarde ne contient pas de base de messages", ar="لا تحتوي النسخة على قاعدة بيانات الرسائل", ru="В копии нет базы сообщений")
s("backup_db_open", en="The database in the backup couldn't be opened", tr="Yedekteki veritabanı açılamadı", es="No se pudo abrir la base de datos de la copia", pt="Não foi possível abrir o banco de dados do backup", de="Die Datenbank in der Sicherung ließ sich nicht öffnen", fr="Impossible d'ouvrir la base de données de la sauvegarde", ar="تعذّر فتح قاعدة البيانات في النسخة", ru="Не удалось открыть базу данных из копии")
s("backup_newer", en="The backup was made with a newer version of Mesa", tr="Yedek daha yeni bir Mesa sürümüyle alınmış", es="La copia se hizo con una versión más reciente de Mesa", pt="O backup foi feito com uma versão mais nova do Mesa", de="Die Sicherung stammt aus einer neueren Version von Mesa", fr="La sauvegarde provient d'une version plus récente de Mesa", ar="أُنشئت النسخة بإصدار أحدث من Mesa", ru="Копия создана в более новой версии Mesa")
s("file_write_failed", en="Couldn't write the file", tr="Dosya yazılamadı", es="No se pudo escribir el archivo", pt="Não foi possível gravar o arquivo", de="Datei konnte nicht geschrieben werden", fr="Impossible d'écrire le fichier", ar="تعذّرت كتابة الملف", ru="Не удалось записать файл")
s("file_open_failed", en="Couldn't open the file", tr="Dosya açılamadı", es="No se pudo abrir el archivo", pt="Não foi possível abrir o arquivo", de="Datei konnte nicht geöffnet werden", fr="Impossible d'ouvrir le fichier", ar="تعذّر فتح الملف", ru="Не удалось открыть файл")

# ---- Kayıt ----
s("person_default", en="Person", tr="Kişi", es="Persona", pt="Pessoa", de="Person", fr="Personne", ar="شخص", ru="Человек")

# ---- Kayıttaki Türkçe etiketlerin gösterimi ----
s("label_photo", en="📷 Photo", tr="📷 Fotoğraf", es="📷 Foto", pt="📷 Foto", de="📷 Foto", fr="📷 Photo", ar="📷 صورة", ru="📷 Фото")
s("label_video", en="🎥 Video", tr="🎥 Video", es="🎥 Vídeo", pt="🎥 Vídeo", de="🎥 Video", fr="🎥 Vidéo", ar="🎥 فيديو", ru="🎥 Видео")
s("label_audio_file", en="🎵 Audio file", tr="🎵 Ses dosyası", es="🎵 Archivo de audio", pt="🎵 Arquivo de áudio", de="🎵 Audiodatei", fr="🎵 Fichier audio", ar="🎵 ملف صوتي", ru="🎵 Аудиофайл")
s("label_voice", en="🎤 Voice message", tr="🎤 Sesli mesaj", es="🎤 Mensaje de voz", pt="🎤 Mensagem de voz", de="🎤 Sprachnachricht", fr="🎤 Message vocal", ar="🎤 رسالة صوتية", ru="🎤 Голосовое сообщение")
s("label_audio", en="🎤 Audio", tr="🎤 Ses", es="🎤 Audio", pt="🎤 Áudio", de="🎤 Audio", fr="🎤 Audio", ar="🎤 صوت", ru="🎤 Аудио")
s("label_video_note", en="⏺ Video message", tr="⏺ Görüntülü mesaj", es="⏺ Videomensaje", pt="⏺ Mensagem de vídeo", de="⏺ Videonachricht", fr="⏺ Message vidéo", ar="⏺ رسالة فيديو", ru="⏺ Видеосообщение")
s("label_location", en="📍 Location", tr="📍 Konum", es="📍 Ubicación", pt="📍 Localização", de="📍 Standort", fr="📍 Position", ar="📍 الموقع", ru="📍 Местоположение")
s("label_file", en="📄 File", tr="📄 Dosya", es="📄 Archivo", pt="📄 Arquivo", de="📄 Datei", fr="📄 Fichier", ar="📄 ملف", ru="📄 Файл")
s("label_contact", en="👤 Contact", tr="👤 Kişi", es="👤 Contacto", pt="👤 Contato", de="👤 Kontakt", fr="👤 Contact", ar="👤 جهة اتصال", ru="👤 Контакт")
s("label_poll", en="📊 Poll", tr="📊 Anket", es="📊 Encuesta", pt="📊 Enquete", de="📊 Umfrage", fr="📊 Sondage", ar="📊 استطلاع", ru="📊 Опрос")
s("label_sticker", en="Sticker", tr="Çıkartma", es="Sticker", pt="Figurinha", de="Sticker", fr="Autocollant", ar="ملصق", ru="Стикер")


def esc(text):
    out = text.replace("\\", "\\\\").replace("'", "\\'").replace('"', '\\"')
    out = out.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    if out.startswith(("@", "?")):
        out = "\\" + out
    return out


for lang in LANGS:
    folder = RES + ("values" if lang == "en" else "values-" + lang)
    os.makedirs(folder, exist_ok=True)
    lines = ['<?xml version="1.0" encoding="utf-8"?>',
             "<!-- Üretildi: Türkçe values-tr, İngilizce varsayılan (desteklenmeyen telefon dili). -->",
             "<resources>"]
    for name, t in S.items():
        lines.append(f'    <string name="{name}">{esc(t[lang])}</string>')
    for name, t in P.items():
        lines.append(f'    <plurals name="{name}">')
        for q, v in t[lang].items():
            lines.append(f'        <item quantity="{q}">{esc(v)}</item>')
        lines.append("    </plurals>")
    lines.append("</resources>")
    open(folder + "/strings.xml", "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")
print(len(S), "metin,", len(P), "çoğul;", len(LANGS), "dil")
