// Türkçe metin → çeviri. Anahtarlar test/l10n_test.dart ile denetlenir
// (yeni metin: tr() ekleyin, buraya ve diğer dillere çevirisini yazın).
const es = <String, String>{
  'Pazartesi': 'Lunes',
  'Salı': 'Martes',
  'Çarşamba': 'Miércoles',
  'Perşembe': 'Jueves',
  'Cuma': 'Viernes',
  'Cumartesi': 'Sábado',
  'Pazar': 'Domingo',
  'Bugün': 'Hoy',
  'Dün': 'Ayer',
  '{day} Ocak': '{day} de enero',
  '{day} Şubat': '{day} de febrero',
  '{day} Mart': '{day} de marzo',
  '{day} Nisan': '{day} de abril',
  '{day} Mayıs': '{day} de mayo',
  '{day} Haziran': '{day} de junio',
  '{day} Temmuz': '{day} de julio',
  '{day} Ağustos': '{day} de agosto',
  '{day} Eylül': '{day} de septiembre',
  '{day} Ekim': '{day} de octubre',
  '{day} Kasım': '{day} de noviembre',
  '{day} Aralık': '{day} de diciembre',
  '{day}.{month}.{year}': '{day}/{month}/{year}',
  'bugün {clock}': 'hoy {clock}',
  'yarın {clock}': 'mañana {clock}',
  'şimdi': 'ahora',
  '{n} dk': '{n} min',
  '{n} sa': '{n} h',
  '{n} g': '{n} d',
  'B': 'B',
  'KB': 'KB',
  'MB': 'MB',
  'GB': 'GB',
  'Çıkartma': 'Sticker',
  '📷 Fotoğraf': '📷 Foto',
  'Otomatik yanıt': 'Respuesta automática',
  'Sessize al': 'Silenciar',
  'Önemli işaretle': 'Marcar como importante',
  '15 dakika': '15 minutos',
  '1 saat': '1 hora',
  '6 saat': '6 horas',
  '1 gün': '1 día',
  'Pzt': 'Lun',
  'Sal': 'Mar',
  'Çar': 'Mié',
  'Per': 'Jue',
  'Cum': 'Vie',
  'Cmt': 'Sáb',
  'Paz': 'Dom',
  'hafta içi': 'entre semana',
  'hafta sonu': 'fines de semana',
  'Tüm uygulamalar': 'Todas las apps',
  'Kimden: "{sender}"': 'De: "{sender}"',
  'İçerik: {words}': 'Contiene: {words}',
  'gruplar dahil': 'grupos incluidos',
  'Süresiz': 'Siempre',
  '7 gün': '7 días',
  '30 gün': '30 días',
  '90 gün': '90 días',
  '1 yıl': '1 año',
  'Tamam 👍': 'Vale 👍',
  'Şu an müsait değilim, sonra yazarım.':
      'Ahora no estoy disponible, te escribo luego.',
  'Yoldayım, birazdan oradayım.': 'Voy en camino, llego pronto.',
  'Teşekkürler!': '¡Gracias!',
  '{step} bir giriş adımı değil': '{step} no es un paso de inicio de sesión',
  '🎥 Video': '🎥 Vídeo',
  '🎵 Ses dosyası': '🎵 Archivo de audio',
  '🎤 Sesli mesaj': '🎤 Mensaje de voz',
  '🎤 Ses': '🎤 Audio',
  '⏺ Görüntülü mesaj': '⏺ Videomensaje',
  '📍 Konum': '📍 Ubicación',
  '📄 Dosya': '📄 Archivo',
  '👤 Kişi': '👤 Contacto',
  '📊 Anket': '📊 Encuesta',
  'Arşiv': 'Archivados',
  'Arşivde sohbet yok.\nGelen kutusunda bir sohbete uzun basıp "Arşivle"yi seçebilirsiniz.':
      'No hay chats archivados.\nMantén pulsado un chat en la bandeja de entrada y elige "Archivar".',
  'Yedekleniyor… Fotoğraflar çoksa biraz sürebilir.':
      'Creando copia… Puede tardar un poco si hay muchas fotos.',
  'Yedek kaydedildi: {messages} mesaj, {files} fotoğraf ({bytes}).':
      'Copia guardada: {messages, plural, one{# mensaje} other{# mensajes}}, {files, plural, one{# foto} other{# fotos}} ({bytes}).',
  'Yedek alınamadı: {error}': 'No se pudo crear la copia: {error}',
  'bilinmeyen hata': 'error desconocido',
  'Yedekten geri yüklensin mi?': '¿Restaurar desde la copia?',
  'Bu telefondaki Mesa mesajları, kişileri ve kuralları yedektekilerle değiştirilir. Telegram ve web servisi girişleri yedekte yoktur; gerekirse yeniden giriş yaparsınız.':
      'Los mensajes, personas y reglas de Mesa en este teléfono se sustituirán por los de la copia. Los inicios de sesión de Telegram y de los servicios web no están en la copia; vuelve a iniciar sesión si hace falta.',
  'Vazgeç': 'Cancelar',
  'Dosya seç': 'Elegir archivo',
  'Geri yükleniyor…': 'Restaurando…',
  'Geri yüklendi: {messages} mesaj, {files} fotoğraf.':
      'Restaurado: {messages, plural, one{# mensaje} other{# mensajes}}, {files, plural, one{# foto} other{# fotos}}.',
  'Şifre yanlış. Yedeği alırken girdiğiniz şifreyi deneyin.':
      'Contraseña incorrecta. Prueba la contraseña que pusiste al crear la copia.',
  'Dosya açılamadı: {error}': 'No se pudo abrir el archivo: {error}',
  'yedek bozuk': 'la copia está dañada',
  'Geri yüklenemedi: {error}': 'No se pudo restaurar: {error}',
  'Yedek': 'Copia de seguridad',
  'Yedekle': 'Crear copia',
  'Mesajlar, kişiler, kurallar ve fotoğraflar; şifreli dosya. Henüz yedek alınmadı.':
      'Mensajes, personas, reglas y fotos; archivo cifrado. Aún no hay copias.',
  'Mesajlar, kişiler, kurallar ve fotoğraflar; şifreli dosya. Son yedek: {when}':
      'Mensajes, personas, reglas y fotos; archivo cifrado. Última copia: {when}',
  'Yedekten geri yükle': 'Restaurar desde la copia',
  'Yeni telefonda ya da sıfırlamadan sonra':
      'En un teléfono nuevo o tras un restablecimiento',
  'En az 8 karakter olmalı.': 'Debe tener al menos 8 caracteres.',
  'Şifreler aynı değil.': 'Las contraseñas no coinciden.',
  'Yedek şifresi': 'Contraseña de la copia',
  'Yedeğin şifresi': 'Contraseña de la copia',
  'Bu şifreyi unutursanız yedek açılamaz; kimse kurtaramaz. Bir yere not edin.':
      'Si olvidas esta contraseña, la copia no se podrá abrir; nadie podrá recuperarla. Apúntala en algún sitio.',
  'Şifre': 'Contraseña',
  'Göster': 'Mostrar',
  'Gizle': 'Ocultar',
  'Şifre (tekrar)': 'Contraseña (repetir)',
  'Aç': 'Abrir',
  'Açıldı. Bu sohbetten yeni mesaj gelince yanıtlarınız {appName} açılmadan, doğrudan gider.':
      'Activado. Cuando llegue un mensaje nuevo en este chat, tus respuestas irán directamente, sin abrir {appName}.',
  'Mesajınız bu sohbete de kaydedildi.':
      'Tu mensaje también se guardó en este chat.',
  'Gönderilmedi': 'No enviado',
  'Tekrar gönder': 'Volver a enviar',
  'Mesaj gönderilemedi': 'No se pudo enviar el mensaje',
  'Sil': 'Eliminar',
  'Karşı tarafa hiç gitmedi': 'Nunca llegó a la otra persona',
  'Kaydedilenlerden çıkar': 'Quitar de guardados',
  'Kaydet': 'Guardar',
  'Tüm uygulamalardan kaydedilenler tek listede':
      'Los mensajes guardados de todas las apps en una lista',
  'Kopyala': 'Copiar',
  'Kaydedilenlerden çıkarıldı.': 'Quitado de guardados.',
  'Kaydedildi ⭐': 'Guardado ⭐',
  'Kopyalandı.': 'Copiado.',
  'Yeniden gönderiliyor…': 'Reenviando…',
  'Gönderilemedi. Bağlantıyı kontrol edin.':
      'No se pudo enviar. Comprueba la conexión.',
  'Ne zaman gönderilsin?': '¿Cuándo enviarlo?',
  '⏰ {when} Telegram\'dan gönderilecek.': '⏰ Se enviará por Telegram {when}.',
  '⏰ {when} kendiliğinden gönderilecek.':
      '⏰ Se enviará automáticamente {when}.',
  '⏰ {when} bildirim gelecek: dokununca {appName} mesaj yazılmış olarak açılır, ➤ ile gönderirsiniz. {viaAppNote}':
      '⏰ Recibirás una notificación {when}: al tocarla se abre {appName} con el mensaje escrito y lo envías con ➤. {viaAppNote}',
  'O zamana kadar bu sohbetten yeni mesaj gelirse kendiliğinden gider.':
      'Si antes llega un mensaje nuevo en este chat, se enviará automáticamente.',
  'Planlı mesajlar': 'Mensajes programados',
  'İptal et': 'Cancelarlo',
  '{appName} bu sohbet için şu an doğrudan gönderme yolu vermiyor: zamanı gelince bildirime dokunup {appName} içinde gönderirsiniz. {viaAppNote}':
      '{appName} ahora no ofrece una forma de enviar directamente a este chat: cuando llegue la hora, toca la notificación y envíalo en {appName}. {viaAppNote}',
  'Telegram bağlantısı açık değil.':
      'La conexión con Telegram no está abierta.',
  '{appName} açılamadı.': 'No se pudo abrir {appName}.',
  'Gönderiliyor…': 'Enviando…',
  '{kind} gönderiliyor…': 'Enviando {kind}…',
  '{appName} açıldı; göndermek için orada ➤ düğmesine dokunun.':
      'Se abrió {appName}; toca allí el botón ➤ para enviar.',
  '{appName} dışarıdan {kind} kabul etmiyor.':
      '{appName} no acepta {kind} desde otras apps.',
  'Gönderilemedi.': 'No se pudo enviar.',
  'Fotoğraf': 'Foto',
  'Video': 'Vídeo',
  'Sesli mesaj': 'Mensaje de voz',
  'Dosya': 'Archivo',
  'Planlı mesaj': 'Mensaje programado',
  'Zaman seç': 'Elegir hora',
  'Gönderilecek mesaj': 'Mensaje a enviar',
  'Sesli mesaj için mikrofon izni gerekli.':
      'Se necesita permiso de micrófono para los mensajes de voz.',
  'Kayıt başlatılamadı.': 'No se pudo empezar a grabar.',
  'Kayıt çok kısa.': 'La grabación es demasiado corta.',
  'Uygulama açılamadı.': 'No se pudo abrir la app.',
  'Siz': 'Tú',
  'Hazır yanıtlar': 'Respuestas rápidas',
  'Gizli okuma açık: Telegram\'da "görüldü" ve "yazıyor" gitmez.':
      'Lectura oculta activada: Telegram no enviará "visto" ni "escribiendo".',
  'Burada okumak {name}\'ta "görüldü" göndermez. Yanıt verirseniz gider.':
      'Leer aquí no envía "visto" en {name}. Se envía si respondes.',
  'Görüldü gönderilmez': 'No se envía "visto"',
  'Medya': 'Multimedia',
  '{name} uygulamasında aç': 'Abrir en {name}',
  'Bu sohbette henüz mesaj yok.': 'Aún no hay mensajes en este chat.',
  '{count} planlı mesaj · ilki {when}':
      '{count, plural, one{# mensaje programado} other{# mensajes programados}} · el primero {when}',
  'Mesajınız {name}\'ta hazır açılır; orada ➤ ile gönderin.':
      'Tu mensaje se abre listo en {name}; envíalo allí con ➤.',
  'Klavye': 'Teclado',
  'Emoji': 'Emoji',
  '{appName} ile yaz': 'Escribir en {appName}',
  'Mesaj yaz': 'Escribe un mensaje',
  'Çıkartma ve GIF': 'Stickers y GIF',
  'Fotoğraf, video, dosya': 'Foto, vídeo, archivo',
  'Zamanla': 'Programar',
  'Kamera': 'Cámara',
  'Sesli mesajı gönder': 'Enviar mensaje de voz',
  'Gönder (basılı tutun: zamanla)': 'Enviar (mantén pulsado para programar)',
  'Web servislerine yanıt, servisin kendi sayfasından yazılır.':
      'Las respuestas a servicios web se escriben en la propia página del servicio.',
  '{name} telefonda kurulu değil.':
      '{name} no está instalado en este teléfono.',
  '{name} sayfasında yanıtla': 'Responder en la página de {name}',
  'çevrimiçi': 'en línea',
  'son görülme {seen}': 'últ. vez {seen}',
  'bugün {time}': 'hoy a las {time}',
  'dün {time}': 'ayer a las {time}',
  'Kaydı sil': 'Borrar grabación',
  '◀ İptal için kaydırın': '◀ Desliza para cancelar',
  'Sesli mesaj: dokunun ya da basılı tutun':
      'Mensaje de voz: toca o mantén pulsado',
  'Galeri': 'Galería',
  'Açıklama ekle': 'Añadir un comentario',
  '{appName} hazır açılır; orada gönderin':
      'Se abre listo en {appName}; envíalo allí',
  'Gönder': 'Enviar',
  'Gönderilemedi': 'No enviado',
  'Gönderiliyor': 'Enviando',
  'Görüldü': 'Visto',
  'Gönderildi': 'Enviado',
  'Burada okumak {appName}\'ta "görüldü" göndermez. Yanıt verirseniz gider.':
      'Leer aquí no envía "visto" en {appName}. Se envía si respondes.',
  'Anladım': 'Entendido',
  'Oynat': 'Reproducir',
  'Sesli mesaj indirilemedi.': 'No se pudo descargar el mensaje de voz.',
  'Duraklat': 'Pausa',
  'Dinle': 'Escuchar',
  '{appName}\'ta aç': 'Abrir en {appName}',
  'Yanıt:': 'Respuesta:',
  'Yükleniyor %{percent}': 'Subiendo {percent} %',
  'Şu an gönderince {appName} açılıyor. Açarsanız bu sohbetten mesaj geldiğinde yanıtlarınız doğrudan gider.':
      'Ahora, al enviar se abre {appName}. Actívalo y, cuando llegue un mensaje de este chat, tus respuestas irán directamente.',
  'Kapat': 'Cerrar',
  'Hatırlatma': 'Recordatorio',
  'Sabitlendi': 'Fijado',
  'Önemli': 'Importante',
  'Sabitlemeyi kaldır': 'Dejar de fijar',
  'Sabitle': 'Fijar',
  'Sonra hatırlat': 'Recordármelo más tarde',
  'Arşivden çıkar': 'Desarchivar',
  'Arşivle': 'Archivar',
  'Kişiyle birleştir': 'Unir con persona',
  'Aynı kişinin başka uygulamadaki sohbetiyle tek yerde':
      'El chat de esta persona en otra app, en un solo lugar',
  '{name} kişisinden ayır': 'Separar de {name}',
  'Kişi': 'Persona',
  'Ne zaman hatırlatılsın?': '¿Cuándo te lo recordamos?',
  '⏰ {when} hatırlatılacak': '⏰ Te lo recordaremos {when}',
  '{target}: {name} ve {name2} sohbetleri birleşti':
      '{target}: se unieron los chats de {name} y {name2}',
  '"{title}" silinsin mi?': '¿Eliminar "{title}"?',
  'Sohbet ve mesajları yalnızca Mesa\'dan silinir; {name} uygulamasındaki sohbete dokunulmaz.':
      'El chat y sus mensajes solo se eliminan de Mesa; el chat en {name} no se toca.',
  '{title} ile birleştir': 'Unir con {title}',
  'Aynı kişinin başka uygulamadaki sohbetini seçin. Mesajlar tek yerde görünür; istediğiniz zaman ayırabilirsiniz.':
      'Elige el chat de esta persona en otra app. Los mensajes aparecerán en un solo lugar; puedes separarlos cuando quieras.',
  'Ara': 'Buscar',
  'Adını değiştir': 'Cambiar nombre',
  '{name} sohbetini ayır': 'Separar el chat de {name}',
  'Kişinin adı': 'Nombre de la persona',
  '1 saat sonra': 'Dentro de 1 hora',
  '3 saat sonra': 'Dentro de 3 horas',
  'Bu akşam': 'Esta tarde',
  'Yarın sabah': 'Mañana por la mañana',
  'Tarih ve saat seç': 'Elegir fecha y hora',
  'Yanıt bekliyor · {count}': 'Esperan respuesta · {count}',
  'Ertelenen sohbetler': 'Chats pospuestos',
  'Şimdi göster': 'Mostrar ahora',
  'Sohbetler': 'Chats',
  'Servisler': 'Servicios',
  'Kurallar': 'Reglas',
  'Ayarlar': 'Ajustes',
  'Yanıt gerekmez': 'No hace falta responder',
  'Yeni mesaj gelene kadar listeden kalkar':
      'Sale de la lista hasta que llegue un mensaje nuevo',
  'Birleşik bildirimler açık. Yeni mesajlar artık Mesa bildirimiyle gelecek.':
      'Las notificaciones unificadas están activadas. Los mensajes nuevos llegarán como notificaciones de Mesa.',
  'Mesajlar': 'Mensajes',
  'Hepsi okundu': 'Todo leído',
  '{unreadTotal} okunmamış': '{unreadTotal} sin leer',
  'Haftalık özet': 'Resumen semanal',
  'Kaydedilenler': 'Guardados',
  'Diğer': 'Más',
  'Tümünü okundu say': 'Marcar todo como leído',
  'Arşiv ({archivedCount})': 'Archivados ({archivedCount})',
  'Tümü': 'Todos',
  'Ekle': 'Añadir',
  'Servis ekle': 'Añadir servicio',
  '{count} ertelenmiş sohbet':
      '{count, plural, one{# chat pospuesto} other{# chats pospuestos}}',
  'Zamanı gelince hatırlatılacak':
      'Te lo recordaremos cuando llegue el momento',
  '{name} artık tek satırda: {name2} ve {name3} mesajları birlikte.':
      '{name} ahora es una sola fila: mensajes de {name2} y {name3} juntos.',
  'Tüm mesajlarda ara': 'Buscar en todos los mensajes',
  'Henüz mesaj yok': 'Aún no hay mensajes',
  'WhatsApp, Instagram, Discord gibi uygulamalardan yeni mesaj geldikçe burada toplanır; eski mesajlar görünmez. Telegram\'ı Ayarlar\'dan bağlarsanız geçmişi de gelir.':
      'Los mensajes nuevos de apps como WhatsApp, Instagram y Discord se reúnen aquí a medida que llegan; los antiguos no aparecen. Si conectas Telegram en Ajustes, también llega su historial.',
  'Bildirimleri birleştir': 'Unificar notificaciones',
  'Her uygulamanın ayrı bildirimi yerine tek tip Mesa bildirimleri: kişi fotoğrafı, doğrudan yanıt ve kurallarınla birlikte.':
      'Un único tipo de notificación de Mesa en lugar de una por cada app: con foto del contacto, respuesta directa y tus reglas.',
  'Bildirim servisi çalışmıyor': 'El servicio de notificaciones no funciona',
  'Yeni mesajlar şu an yakalanmıyor. Xiaomi uygulamayı arka planda engelliyor: Otomatik başlatma iznini açın ve uygulama ayarlarında pil tasarrufunu "Kısıtlama yok" yapın. Ardından "Yeniden bağla"ya dokunun.':
      'Ahora no se capturan los mensajes nuevos. Xiaomi bloquea la app en segundo plano: activa el permiso de Inicio automático y pon el ahorro de batería en "Sin restricciones" en los ajustes de la app. Después toca "Volver a conectar".',
  'Yeni mesajlar şu an yakalanmıyor. Telefon uygulamayı arka planda kapatmış olabilir: uygulama ayarlarında pil kısıtlamasını kaldırın, ardından "Yeniden bağla"ya dokunun.':
      'Ahora no se capturan los mensajes nuevos. Puede que el teléfono haya cerrado la app en segundo plano: quita la restricción de batería en los ajustes de la app y luego toca "Volver a conectar".',
  'Otomatik başlatma': 'Inicio automático',
  'Uygulama ayarları': 'Ajustes de la app',
  'Yeniden bağla': 'Volver a conectar',
  'Aynı kişi mi?': '¿La misma persona?',
  'Telefon numaraları aynı. Birleştirirseniz mesajları tek satırda, tek zaman çizgisinde görürsünüz.':
      'Los números de teléfono coinciden. Si los unes, verás los mensajes en una sola fila y en una sola línea de tiempo.',
  'Adları aynı. Birleştirirseniz mesajları tek satırda, tek zaman çizgisinde görürsünüz.':
      'Los nombres coinciden. Si los unes, verás los mensajes en una sola fila y en una sola línea de tiempo.',
  'Farklı kişiler': 'Personas distintas',
  'Birleştir': 'Unir',
  'Uygulamanın dili': 'Idioma de la app',
  'Telefonun dili': 'Idioma del teléfono',
  'Dil': 'Idioma',
  'Telefonun dili ({language})': 'Idioma del teléfono ({language})',
  'Mesa\'yı açmak için kimliğinizi doğrulayın':
      'Verifica tu identidad para abrir Mesa',
  'Mesa kilitli': 'Mesa está bloqueado',
  'Kilidi aç': 'Desbloquear',
  'Fotoğraflar': 'Fotos',
  'Videolar': 'Vídeos',
  'Ocak': 'Enero',
  'Şubat': 'Febrero',
  'Mart': 'Marzo',
  'Nisan': 'Abril',
  'Mayıs': 'Mayo',
  'Haziran': 'Junio',
  'Temmuz': 'Julio',
  'Ağustos': 'Agosto',
  'Eylül': 'Septiembre',
  'Ekim': 'Octubre',
  'Kasım': 'Noviembre',
  'Aralık': 'Diciembre',
  'Henüz fotoğraf ya da video yok': 'Aún no hay fotos ni vídeos',
  'Bildiriminde önizlemesi gelen fotoğraflar ve Telegram medyası burada toplanır.':
      'Aquí se reúnen las fotos con vista previa en las notificaciones y los archivos de Telegram.',
  'Tam boyut': 'Tamaño completo',
  'Medya açılamadı.': 'No se pudo abrir el archivo.',
  'Görsel açılamadı.': 'No se pudo abrir la imagen.',
  'İndiriliyor…': 'Descargando…',
  'Açılıyor…': 'Abriendo…',
  'İndiriliyor… %{percent}': 'Descargando… {percent} %',
  'Sesi kapat': 'Silenciar',
  'Sesi aç': 'Activar sonido',
  'Tam ekrandan çık': 'Salir de pantalla completa',
  'Tam ekran': 'Pantalla completa',
  'Başlangıç saati': 'Hora de inicio',
  'Bitiş saati': 'Hora de fin',
  'En az bir gün seçin.': 'Elige al menos un día.',
  'Kural silinsin mi?': '¿Eliminar la regla?',
  '"{name}" kalıcı olarak silinecek.': '"{name}" se eliminará para siempre.',
  'Yeni kural': 'Nueva regla',
  'Kuralı düzenle': 'Editar regla',
  'Kural adı': 'Nombre de la regla',
  'Ne yapılsın?': '¿Qué debe hacerse?',
  'Mesaja, geldiği uygulama üzerinden otomatik cevap verilir.':
      'El mensaje recibe una respuesta automática a través de la app de la que llegó.',
  'Mesajlar kaydedilir ama okunmamış sayılmaz.':
      'Los mensajes se guardan pero no cuentan como no leídos.',
  'Sohbet, açılana kadar listenin en üstünde yıldızla durur.':
      'El chat se queda arriba de la lista con una estrella hasta que lo abras.',
  'Yanıt metni': 'Texto de la respuesta',
  'Şu an müsait değilim, sonra yazacağım.':
      'Ahora no estoy disponible, te escribiré luego.',
  'Otomatik yanıt için bir metin yazın':
      'Escribe un texto para la respuesta automática',
  'Aynı sohbete tekrar yanıt için bekle':
      'Esperar antes de volver a responder al mismo chat',
  'Hangi mesajlarda?': '¿En qué mensajes?',
  'Uygulama seçilmedi: tüm uygulamalar': 'Ninguna app elegida: todas las apps',
  'Yalnızca seçilen uygulamalar': 'Solo las apps elegidas',
  'Kimden (isteğe bağlı)': 'De (opcional)',
  'Sohbet ya da kişi adında geçen ifade':
      'Texto en el nombre del chat o de la persona',
  'Anahtar kelimeler (isteğe bağlı)': 'Palabras clave (opcional)',
  'acil, toplantı, fatura': 'urgente, reunión, factura',
  'Virgülle ayırın; herhangi biri geçerse kural çalışır':
      'Sepáralas con comas; la regla se activa si aparece cualquiera',
  'Grup sohbetlerinde de çalışsın': 'También en chats de grupo',
  'Gruptaki herkes otomatik yanıtı görür.':
      'Todos en el grupo ven la respuesta automática.',
  'Ne zaman?': '¿Cuándo?',
  'Yalnızca belirli saatlerde': 'Solo a ciertas horas',
  'Gün boyu': 'Todo el día',
  'Başlangıç {from}': 'Inicio {from}',
  'Bitiş {to}': 'Fin {to}',
  'Gece yarısını aşar: {from}–{to} (ertesi gün)':
      'Pasa la medianoche: {from}–{to} (día siguiente)',
  'Koşul yok: bu kural her yeni mesaja yanıt verir (bekleme süresi ve saatlik sınırla).':
      'Sin condiciones: esta regla responde a cada mensaje nuevo (con el tiempo de espera y el límite por hora).',
  'Kurallar nasıl çalışır?': '¿Cómo funcionan las reglas?',
  'Kurallar uygulama kapalıyken de, yeni mesaj gelir gelmez çalışır.\n\nOtomatik yanıt güvenliği: aynı anda gelen mesajlara tek yanıt; aynı sohbete bekleme süresi dolmadan tekrar yanıt yok; tüm sohbetlerde saatte en fazla 20 yanıt.\n\nYanıt, kaynak uygulamanın bildirimi üzerinden (Telegram\'da doğrudan) gider; bildirim yoksa gönderilmez.':
      'Las reglas se aplican en cuanto llega un mensaje nuevo, incluso con la app cerrada.\n\nSeguridad de las respuestas automáticas: una sola respuesta a los mensajes que llegan juntos; no se vuelve a responder al mismo chat antes de que acabe el tiempo de espera; como mucho 20 respuestas por hora entre todos los chats.\n\nLa respuesta sale por la notificación de la app de origen (directamente en Telegram); si no hay notificación, no se envía.',
  'Otomatik yanıt, sessize alma, önemli işaretleme':
      'Respuesta automática, silenciar, marcar como importante',
  '{active} etkin kural':
      '{active, plural, one{# regla activa} other{# reglas activas}}',
  'Kural ekle': 'Añadir regla',
  'Kurallarınız': 'Tus reglas',
  'Son 7 günde {recentFires} kez çalıştı':
      'Se aplicó {recentFires, plural, one{una vez} other{# veces}} en los últimos 7 días',
  'Henüz kural yok': 'Aún no hay reglas',
  'Yukarıdaki hazır kurallardan birine dokunun ya da kendiniz ekleyin.':
      'Toca una de las reglas predefinidas de arriba o crea la tuya.',
  'WhatsApp\'ta "acil" geçen mesajları önemli işaretle':
      'Marcar como importantes los mensajes de WhatsApp que contengan "urgente"',
  'İş grubunu sessize al': 'Silenciar el grupo del trabajo',
  'Gece 23:00–08:00 arası "Sabah yazarım" diye yanıtla':
      'Responder "Te escribo por la mañana" entre las 23:00 y las 08:00',
  'Gece modu': 'Modo noche',
  '23:00–08:00 otomatik yanıt': 'Respuesta automática de 23:00 a 08:00',
  'Gece otomatik yanıt': 'Respuesta automática nocturna',
  'Şu an uyuyorum, sabah dönerim 🌙':
      'Ahora estoy durmiendo, te respondo por la mañana 🌙',
  'Meşgulüm': 'Ocupado',
  'Herkese kısa yanıt': 'Respuesta breve para todos',
  'Şu an müsait değilim, birazdan yazarım.':
      'Ahora no estoy disponible, te escribo enseguida.',
  'Mesai dışı': 'Fuera de horario',
  'Hafta içi 18:00–09:00': 'Entre semana 18:00–09:00',
  'Mesai dışı yanıt': 'Respuesta fuera de horario',
  'Mesai saatleri dışındayım, yarın dönüş yapacağım.':
      'Estoy fuera del horario laboral, te respondo mañana.',
  'Acil mesajlar': 'Mensajes urgentes',
  '"acil", "hemen" geçenleri öne çıkar':
      'Destaca los que contienen "urgente", "ya"',
  'acil': 'urgente',
  'hemen': 'ya',
  'önemli': 'importante',
  'ara beni': 'llámame',
  'Hazır kurallar': 'Reglas predefinidas',
  'Mesajlarda ara': 'Buscar en los mensajes',
  'Bütün uygulamalardaki mesajlarda arar. En az iki harf yazın.':
      'Busca en los mensajes de todas las apps. Escribe al menos dos letras.',
  'Sonuç bulunamadı.': 'No hay resultados.',
  '{name} açılamadı.': 'No se pudo abrir {name}.',
  'Servisler nasıl çalışır?': '¿Cómo funcionan los servicios?',
  'Her servis kendi resmi web sitesiyle, uygulamanın içindeki tarayıcıda açılır. Giriş bilgileriniz yalnızca bu telefonda kalır; Mesa yalnızca o servisin sunucusuyla konuşur.\n\nArka planda bağlı servisler uygulama kapalıyken de yeni mesajları bildirir ve mesajlar Sohbetler\'e düşer. Bunun için telefonun pil ayarında Mesa\'ya "Kısıtlama yok" verilmelidir. Her açık servis pil ve bellek harcar.\n\nInstagram, X ve LinkedIn gibi bazı siteler açıkken mesaj bildirimi göndermez; onlarda okunmamış sayısı arttığında haber verilir.\n\n"Google ile giriş" bu sayfalarda çalışmaz; e-posta ve şifreyle girin.':
      'Cada servicio se abre con su propia web oficial en el navegador de la app. Tus datos de acceso solo se quedan en este teléfono; Mesa solo habla con el servidor de ese servicio.\n\nLos servicios conectados en segundo plano avisan de los mensajes nuevos incluso con la app cerrada, y los mensajes llegan a Chats. Para ello, Mesa debe tener "Sin restricciones" en los ajustes de batería del teléfono. Cada servicio abierto consume batería y memoria.\n\nAlgunos sitios como Instagram, X y LinkedIn no envían notificaciones de mensajes mientras están abiertos; con ellos se avisa cuando sube el número de no leídos.\n\n"Iniciar sesión con Google" no funciona en estas páginas; entra con correo y contraseña.',
  '{unread} okunmamış': '{unread} sin leer',
  'Tüm uygulamalar tek yerde': 'Todas las apps en un solo lugar',
  'Uygulamalar': 'Apps',
  'Web servisleri': 'Servicios web',
  '{name} ayarları': 'Ajustes de {name}',
  'Okunmamış var': 'Hay mensajes sin leer',
  'Bildirim kapalı': 'Notificaciones desactivadas',
  'Arka planda bağlı': 'Conectado en segundo plano',
  'Yalnızca açıkken': 'Solo mientras está abierto',
  'Henüz web servisi yok': 'Aún no hay servicios web',
  'Telefonda uygulaması olmayan servisleri resmi web sürümleriyle buraya ekleyin. Yeni mesajlar Sohbetler\'e ve bildirimlere düşer.':
      'Añade aquí, con sus versiones web oficiales, los servicios que no tienen app en este teléfono. Los mensajes nuevos llegan a Chats y a las notificaciones.',
  'Başka bir site': 'Otro sitio',
  'Adresini yazarak, ör. vk.com/im':
      'Escribiendo su dirección, p. ej. vk.com/im',
  'KakaoTalk, Viber, LINE ve Signal\'in web sürümü yok. Uygulamaları telefona kurulursa mesajları bildirimlerden otomatik toplanır.':
      'KakaoTalk, Viber, LINE y Signal no tienen versión web. Si sus apps están instaladas en el teléfono, sus mensajes se recogen automáticamente de las notificaciones.',
  'Ekli · ikinci hesap eklenir': 'Añadido · se añade una segunda cuenta',
  'Uygulaması kurulu, bildirimleri zaten geliyor':
      'La app está instalada, sus notificaciones ya llegan',
  'https ile açılan geçerli bir site adresi yazın.':
      'Escribe una dirección válida que empiece por https.',
  'Ad': 'Nombre',
  'Adres': 'Dirección',
  '{name} oturumu kapatılsın mı?': '¿Cerrar sesión en {name}?',
  'Bu servisin giriş bilgileri ve site verileri telefondan silinir. Yeniden giriş yapmanız gerekir.':
      'Los datos de acceso y del sitio de este servicio se borrarán del teléfono. Tendrás que volver a iniciar sesión.',
  'Oturumu kapat': 'Cerrar sesión',
  '{name} kaldırılsın mı?': '¿Quitar {name}?',
  'Oturum ve site verileri telefondan silinir. Sohbetler\'deki eski mesajlar kalır.':
      'La sesión y los datos del sitio se borrarán del teléfono. Los mensajes antiguos de Chats se mantienen.',
  'Kaldır': 'Quitar',
  'Arka planda bağlı kalsın': 'Mantener conectado en segundo plano',
  'Uygulama kapalıyken de yeni mesajlar bildirilir; pil kullanımı artar':
      'Avisa de los mensajes nuevos aunque la app esté cerrada; gasta más batería',
  'Bildirimler': 'Notificaciones',
  'Yeni mesajlar Sohbetler\'e ve bildirimlere':
      'Mensajes nuevos a Chats y a las notificaciones',
  'Videolar kendiliğinden oynasın': 'Reproducir vídeos automáticamente',
  'Kapalıyken videolar dokununca oynar; sayfa daha akıcı olur':
      'Desactivado, los vídeos se reproducen al tocarlos; la página va más fluida',
  'Eski mesajlar silinsin mi?': '¿Eliminar los mensajes antiguos?',
  '{days} öncesine ait mesajlar ve görselleri Mesa\'dan kalıcı olarak silinecek. Kaynak uygulamalardaki mesajlara dokunulmaz.':
      'Los mensajes e imágenes de hace más de {days} se eliminarán para siempre de Mesa. Los mensajes de las apps de origen no se tocan.',
  'Seçilen uygulamalarda yanıt, Mesa yeniden başlasa da doğrudan gider':
      'En las apps elegidas, las respuestas van directamente aunque Mesa se reinicie',
  'Kendi bildirimi de kalsın': 'Mantener también su propia notificación',
  'Seçtiğiniz uygulamanın bildirimi çubuktan kaldırılmaz. Bildirim orada durdukça, Mesa yeniden başlasa da (güncelleme, telefonun yeniden açılması) o sohbete yanıt ve planlı mesaj uygulamaya geçmeden gider. Aynı mesaj için iki bildirim görürsünüz; Mesa\'nınki sessiz gelir.':
      'La notificación de la app elegida no se quita de la barra. Mientras siga ahí, las respuestas y los mensajes programados a ese chat van directamente, sin pasar por la app, aunque Mesa se reinicie (una actualización, un reinicio del teléfono). Verás dos notificaciones del mismo mensaje; la de Mesa llega en silencio.',
  'Ana ekranda boş bir yere basılı tutun → Bileşenler (Widget) → Mesa\'yı sürükleyip bırakın.':
      'Mantén pulsado un espacio vacío de la pantalla de inicio → Widgets → arrastra y suelta Mesa.',
  'Birleşik bildirimler': 'Notificaciones unificadas',
  'Uygulamaların ayrı bildirimleri yerine kişi fotoğraflı, yanıtlanabilen tek tip bildirim':
      'Un único tipo de notificación con la foto del contacto a la que puedes responder, en lugar de las notificaciones separadas de cada app',
  'Önemli mesajlarda bildirim': 'Avisar de mensajes importantes',
  '"Önemli işaretle" kuralına uyunca, sessizdekiler dahil':
      'Cuando se cumple la regla "Marcar como importante", incluidos los silenciados',
  'Ana ekran': 'Pantalla de inicio',
  'Ana ekran bileşeni': 'Widget de pantalla de inicio',
  'Okunmamışlar ve yanıt bekleyenler, uygulamayı açmadan':
      'No leídos y pendientes de respuesta, sin abrir la app',
  'Bağlantılar': 'Conexiones',
  'Doğrudan bağlantı: sessiz gruplar ve geçmiş':
      'Conexión directa: grupos silenciados e historial',
  'Telegram\'da gizli okuma': 'Lectura oculta en Telegram',
  'Okuduğunuzda "görüldü", yazarken "yazıyor" gitmez':
      'Sin "visto" al leer ni "escribiendo" al escribir',
  'Telegram kanallarını gösterme': 'Ocultar canales de Telegram',
  'Kişiler ve gruplar gelmeye devam eder':
      'Las personas y los grupos siguen llegando',
  'Okunan uygulamalar': 'Apps de las que se recogen mensajes',
  'Gizlilik': 'Privacidad',
  'Görmeden okuma': 'Leer sin que lo vean',
  'WhatsApp, Instagram ve diğerlerinde mesajı burada okumak karşı tarafa "görüldü" göndermez. Yanıt verirseniz gider.':
      'Leer aquí un mensaje de WhatsApp, Instagram y otras no envía "visto" a quien lo mandó. Se envía si respondes.',
  'Silinen mesajlar korunur': 'Se conservan los mensajes eliminados',
  'Gönderen mesajı silse de metni burada "silindi" etiketiyle kalır.':
      'Aunque quien lo envió borre el mensaje, su texto se queda aquí con la etiqueta "eliminado".',
  'Mesajları sakla': 'Conservar mensajes',
  '{retentionDays} sonra silinir': 'Se eliminan pasados {retentionDays}',
  'Yazma': 'Escritura',
  '{count} yanıt': '{count, plural, one{# respuesta} other{# respuestas}}',
  'Telefonda ekran kilidi ya da parmak izi tanımlı değil.':
      'No hay bloqueo de pantalla ni huella configurados en este teléfono.',
  'Uygulama kilidini açmak için doğrulayın':
      'Verifica para activar el bloqueo de la app',
  'Uygulama kilidi': 'Bloqueo de la app',
  'Parmak izi, yüz tanıma ya da ekran kilidi':
      'Huella, reconocimiento facial o bloqueo de pantalla',
  'Yeni hazır yanıt': 'Nueva respuesta rápida',
  'Hazır yanıt yok.': 'No hay respuestas rápidas.',
  'Düzelt': 'Arreglar',
  'Sistem durumu · her şey hazır': 'Estado del sistema · todo listo',
  'Sistem durumu · {problems} ayar eksik':
      'Estado del sistema · {problems, plural, one{falta # ajuste} other{faltan # ajustes}}',
  'Bildirim erişimi': 'Acceso a notificaciones',
  'Mesajlar yakalanıyor': 'Los mensajes se están capturando',
  'İzin var ama sistem servisi bağlamadı':
      'Hay permiso, pero el sistema no conectó el servicio',
  'Mesajları okumak için gerekli': 'Necesario para leer los mensajes',
  'Bağla': 'Conectar',
  'İzin ver': 'Permitir',
  'Bildirim izni': 'Permiso de notificaciones',
  'Yeni mesajlar bildirilir': 'Se avisa de los mensajes nuevos',
  'Kapalıysa yeni mesaj bildirimi görmezsiniz':
      'Si está desactivado, no verás avisos de mensajes nuevos',
  'Pil kısıtlaması yok': 'Sin restricción de batería',
  'Arka planda kapatılmaz': 'No se cierra en segundo plano',
  'Telefon uygulamayı arka planda kapatıp mesajları geciktirebilir':
      'El teléfono puede cerrar la app en segundo plano y retrasar los mensajes',
  'Otomatik başlatma (Xiaomi)': 'Inicio automático (Xiaomi)',
  'Açık olmalı; telefon yeniden başlayınca da çalışsın':
      'Debe estar activado para que funcione también tras reiniciar el teléfono',
  'Kontrol et': 'Comprobar',
  'Mikrofon': 'Micrófono',
  'Sesli mesaj kaydedilebilir': 'Se pueden grabar mensajes de voz',
  'Yalnızca sesli mesaj için; ilk kayıtta sorulur':
      'Solo para mensajes de voz; se pide en la primera grabación',
  'Tüm mesajlar tek tip, buradan yanıtlanabilen bildirimle':
      'Todos los mensajes con un único tipo de notificación que puedes responder desde aquí',
  'Kapalıysa yeni mesajları fark etmezsiniz':
      'Si está desactivado, no te enterarás de los mensajes nuevos',
  'Pil kısıtlamasını kaldır': 'Quitar la restricción de batería',
  'Arka planda kapatılmasın, mesajlar gecikmesin':
      'Para que no se cierre en segundo plano y los mensajes no se retrasen',
  'Telefon yeniden açılınca da çalışsın':
      'Para que funcione también tras reiniciar el teléfono',
  'Son uygulamalarda kilitle': 'Bloquear en apps recientes',
  'Son uygulamalarda karta basılı tutup kilide dokunun; kilitsizken kaydırınca kapanıyor':
      'En apps recientes, mantén pulsada la tarjeta y toca el candado; sin bloqueo, al deslizarla se cierra',
  'Yaptım': 'Hecho',
  'WhatsApp\'a geçmeden yanıt': 'Responder sin pasar a WhatsApp',
  'Uygulama yeniden başlasa da yanıtlar doğrudan gitsin':
      'Que las respuestas vayan directamente aunque la app se reinicie',
  'Kurulumu tamamla · {done}/{count}':
      'Completar configuración · {done}/{count}',
  'Mesajlar eksiksiz ve gecikmeden gelsin':
      'Para que los mensajes lleguen completos y sin retraso',
  'Sonra': 'Más tarde',
  'Telegram\'ı bağla · isteğe bağlı': 'Conectar Telegram · opcional',
  'Sessiz gruplar ve geçmiş de gelsin':
      'Que lleguen también los grupos silenciados y el historial',
  'Daha az göster': 'Mostrar menos',
  '{pending} adım daha':
      '{pending, plural, one{falta # paso} other{faltan # pasos}}',
  'İsteğe bağlı adımlar': 'Pasos opcionales',
  'Henüz kaydedilen mesaj yok': 'Aún no hay mensajes guardados',
  'Bir mesaja basılı tutup "Kaydet"e dokunun. Adres, kod, tarih gibi önemli mesajlar hangi uygulamadan gelirse gelsin burada toplanır.':
      'Mantén pulsado un mensaje y toca "Guardar". Los mensajes importantes, como direcciones, códigos y fechas, se reúnen aquí vengan de la app que vengan.',
  'Fotoğraflar ve profil resimleri': 'Fotos y fotos de perfil',
  'Telegram önbelleği': 'Caché de Telegram',
  'Geçici dosyalar': 'Archivos temporales',
  'Önbellek temizlensin mi?': '¿Borrar la caché?',
  'Telegram\'da 7 gündür açılmamış fotoğraf ve videolar, web servislerinin önbelleği ve geçici dosyalar silinir. Mesajlar, kişiler ve oturumlar silinmez; Telegram medyası açınca yeniden iner.':
      'Se borran las fotos y vídeos de Telegram que no se abren desde hace 7 días, la caché de los servicios web y los archivos temporales. No se borran mensajes, personas ni sesiones; los archivos de Telegram se vuelven a descargar al abrirlos.',
  'Temizle': 'Borrar',
  '{freed} yer açıldı.': 'Se liberaron {freed}.',
  'Temizlenecek önbellek yoktu.': 'No había caché que borrar.',
  'Eski mesajları silmek için: saklama süresi.':
      'Para borrar mensajes antiguos: período de conservación.',
  'Önbelleği temizle': 'Borrar caché',
  'Günlere göre': 'Por día',
  'En çok yazıştıkların': 'Con quién más hablas',
  '{count} mesaj · {name}':
      '{count, plural, one{# mensaje} other{# mensajes}} · {name}',
  'Son 7 gün': 'Últimos 7 días',
  '{total} mesaj': '{total, plural, one{# mensaje} other{# mensajes}}',
  '{incoming} gelen': '{incoming} recibidos',
  '{outgoing} giden': '{outgoing} enviados',
  '{people} kişi': '{people, plural, one{# persona} other{# personas}}',
  '%{percent}': '{percent} %',
  'En yoğun saatin {hour}:00': 'Tu hora con más actividad son las {hour}:00',
  'Gelen her 10 mesaja {ratio} yanıt':
      '{ratio} respuestas por cada 10 mensajes recibidos',
  'Gönderenin silip sende kalan {deleted} mesaj':
      '{deleted, plural, one{# mensaje borrado por quien lo envió y guardado para ti} other{# mensajes borrados por quien los envió y guardados para ti}}',
  'Bilgiler': 'Datos',
  'Çıkartmalar': 'Stickers',
  'Bu bölümde çıkartma yok.': 'No hay stickers en esta sección.',
  'GIF ara (boşsa kaydedilenler)': 'Buscar GIF (vacío: guardados)',
  'Kaydedilmiş GIF yok. Yukarıdan arayabilirsiniz.':
      'No hay GIF guardados. Puedes buscar arriba.',
  'GIF bulunamadı.': 'No se encontraron GIF.',
  'Telegram bağlantısı kapatılsın mı?': '¿Desconectar Telegram?',
  'Bu cihazın oturumu Telegram\'dan çıkarılır. Daha önce alınan mesajlar Mesa\'da kalır.':
      'La sesión de este dispositivo se quitará de Telegram. Los mensajes recibidos antes se quedan en Mesa.',
  'Çıkış yap': 'Cerrar sesión',
  'Telegram bağlantısı': 'Conexión con Telegram',
  'Bu derlemede Telegram uygulama kimliği yok. my.telegram.org → "API development tools" bölümünden api_id ve api_hash alınıp android/local.properties dosyasına telegram.apiId ve telegram.apiHash olarak yazılmalı, ardından uygulama yeniden derlenmeli.':
      'Esta compilación no tiene un ID de app de Telegram. Obtén un api_id y un api_hash en my.telegram.org → "API development tools", escríbelos en android/local.properties como telegram.apiId y telegram.apiHash y vuelve a compilar la app.',
  '+90 5xx xxx xx xx': '+34 6xx xxx xxx',
  'Devam': 'Continuar',
  'Telegram hesabınız bağlı. Sessizdeki gruplar dahil yeni mesajlar gelen kutusuna düşer. Bir sohbeti açınca son mesajları da indirilir.':
      'Tu cuenta de Telegram está conectada. Los mensajes nuevos, incluidos los de grupos silenciados, llegan a la bandeja de entrada. Al abrir un chat también se descargan sus últimos mensajes.',
  'Bu giriş adımı desteklenmiyor.':
      'Este paso de inicio de sesión no es compatible.',
  'Telegram hesabınızı bağlayın': 'Conecta tu cuenta de Telegram',
  'Mesa, Telegram\'ın resmi kütüphanesiyle hesabınıza doğrudan bağlanır. Böylece bildirim üretmeyen sessiz grupların mesajları da gelir.':
      'Mesa se conecta directamente a tu cuenta con la biblioteca oficial de Telegram, así que también llegan los mensajes de los grupos silenciados que no generan notificaciones.',
  'Telegram\'a bağlan': 'Conectar con Telegram',
  'Çıkış yapılıyor…': 'Cerrando sesión…',
  'Telegram\'a bağlanılıyor…': 'Conectando con Telegram…',
  'Telefon numaranız': 'Tu número de teléfono',
  'Doğrulama kodu': 'Código de verificación',
  'E-posta kodu': 'Código del correo',
  'İki adımlı doğrulama şifresi': 'Contraseña de verificación en dos pasos',
  'Telefon numarası (ülke koduyla)':
      'Número de teléfono (con prefijo del país)',
  'Kod': 'Código',
  '• Bağlantı yalnızca Telegram sunucularına gider; mesajlar yalnızca bu telefonda saklanır.\n• Okundu bilgisi gönderilmez, çevrimiçi görünmezsiniz.\n• Bu cihaz Telegram\'da "Etkin oturumlar" listesinde görünür.\n• Bağlıyken bildirim çubuğunda sessiz bir "Telegram\'a bağlı" bildirimi durur.':
      '• La conexión solo va a los servidores de Telegram; los mensajes solo se guardan en este teléfono.\n• No se envían confirmaciones de lectura ni apareces en línea.\n• Este dispositivo aparece en la lista "Sesiones activas" de Telegram.\n• Mientras está conectado, queda en la barra una notificación silenciosa "Conectado a Telegram".',
  'Bir sohbete basılı tutun: sabitleyin, sonraya erteleyin ya da aynı kişinin başka uygulamadaki sohbetiyle birleştirin.':
      'Mantén pulsado un chat: fíjalo, posponlo o únelo con el chat de la misma persona en otra app.',
  'Gönder düğmesine basılı tutun: mesajı istediğiniz saate planlayın.':
      'Mantén pulsado el botón de enviar: programa el mensaje para la hora que quieras.',
  'Bir mesaja basılı tutup "Kaydet": tüm uygulamalardan kaydettikleriniz üstteki 🔖 listesinde.':
      'Mantén pulsado un mensaje y toca "Guardar": lo que guardes de todas las apps está en la lista 🔖 de arriba.',
  'Sohbetin üstündeki galeri düğmesi: o kişiyle paylaşılan tüm fotoğraf ve videolar tek yerde.':
      'El botón de galería arriba en un chat: todas las fotos y vídeos compartidos con esa persona en un solo lugar.',
  'Bildirimden yazmadan yanıtlayın: hazır yanıtlarınız bildirimin altında tek dokunuşla. Listeyi Ayarlar → Hazır yanıtlar\'dan değiştirin.':
      'Responde desde la notificación sin escribir: tus respuestas rápidas están a un toque bajo la notificación. Cambia la lista en Ajustes → Respuestas rápidas.',
  'Ana ekran bileşeni: okunmamışlar ve yanıt bekleyenler uygulamayı açmadan. Ayarlar → Ana ekran → Ekle.':
      'Widget de pantalla de inicio: no leídos y quién espera respuesta sin abrir la app. Ajustes → Pantalla de inicio → Añadir.',
  'Haftalık özet: kimlerle en çok yazıştığınızı üstteki grafik düğmesinden görün.':
      'Resumen semanal: mira con quién hablas más con el botón del gráfico de arriba.',
  'Günün ipucu': 'Consejo del día',
  'Tüm mesajların tek yerde': 'Todos tus mensajes en un solo lugar',
  'WhatsApp, Telegram, Instagram, Discord ve diğerleri tek gelen kutusunda; uygulamalar arasında gidip gelmeden.':
      'WhatsApp, Telegram, Instagram, Discord y otros en una sola bandeja de entrada, sin saltar entre apps.',
  'Bir kişi, tek sohbet': 'Una persona, un chat',
  'Aynı kişiyle WhatsApp\'tan, Instagram\'dan, Telegram\'dan yazıştıklarınız tek zaman çizgisinde; yanıtı istediğiniz uygulamadan verin.':
      'Lo que escribes con la misma persona en WhatsApp, Instagram y Telegram en una sola línea de tiempo; responde desde la app que prefieras.',
  'Görüldü göndermeden oku': 'Lee sin enviar "visto"',
  'WhatsApp ve Instagram mesajlarını burada okumak karşı tarafa "görüldü" göndermez; Telegram\'da da isteğe bağlı.':
      'Leer aquí los mensajes de WhatsApp e Instagram no envía "visto"; en Telegram también es opcional.',
  'Silinen mesajın yazısı kalır':
      'El texto de los mensajes eliminados se queda',
  'Gönderen "herkesten sil" dese de yazdığı metin burada "silindi" etiketiyle durur.':
      'Aunque quien lo envió elija "eliminar para todos", lo que escribió se queda aquí con la etiqueta "eliminado".',
  'Yanıt bekleyenler en üstte; sohbeti sonraya ertele, mesajı istediğin saate planla.':
      'Los que esperan respuesta, arriba; pospón un chat, programa un mensaje para la hora que quieras.',
  'Telefonunda kalır': 'Se queda en tu teléfono',
  'Mesajlar yalnızca bu telefonda saklanır; hiçbir sunucuya gönderilmez.':
      'Los mensajes solo se guardan en este teléfono; nunca se envían a ningún servidor.',
  'Bildirim erişimini aç': 'Activar el acceso a notificaciones',
  'Mesa mesajları uygulamaların bildirimlerinden okur. Açılan listede Mesa\'yı bulup izin verin.':
      'Mesa lee los mensajes de las notificaciones de las apps. Busca Mesa en la lista que se abre y dale permiso.',
  'İzin verilemiyor mu?': '¿No puedes activarlo?',
  'Android, mağaza dışından kurulan uygulamalarda bu izni kısıtlar. Mesa\'nın anahtarına bir kez dokunun, sonra Uygulama bilgileri → ⋮ → Kısıtlanmış ayarlara izin ver\'i seçip tekrar deneyin.':
      'Android restringe este permiso en las apps instaladas fuera de una tienda. Toca una vez el interruptor de Mesa, luego abre Información de la app → ⋮ → Permitir ajustes restringidos y vuelve a intentarlo.',
  'Uygulama bilgileri': 'Información de la app',
  // Güvenli bağlantı (1.1)
  'Anahtar (secret)': 'Clave (secret)',
  'Açık · {provider}': 'Activado · {provider}',
  'Açılan pencerede "Tamam"a dokunarak VPN iznini verin.':
      'Toca "Aceptar" en la ventana que se abre para permitir la VPN.',
  'Bağlantıdan ekle': 'Añadir desde enlace',
  'Başka bir VPN açık. Android aynı anda tek VPN\'e izin verir; şifreli DNS açılınca o kapanır.':
      'Hay otra VPN activada. Android solo permite una VPN a la vez; al activar el DNS seguro se desactivará.',
  'Başka bir VPN açıldığı için şifreli DNS kapandı.':
      'El DNS seguro se desactivó porque se activó otra VPN.',
  'Bildirim panelini aşağı çekip düzenle simgesine dokunun ve "Şifreli DNS" kutucuğunu ekleyin; tek dokunuşla açıp kapatırsınız.':
      'Desliza hacia abajo el panel de notificaciones, toca el icono de editar y añade el mosaico "DNS seguro" para activarlo y desactivarlo con un toque.',
  'Bir hata oluştu.': 'Algo salió mal.',
  'Bu bir Telegram proxy bağlantısı değil.':
      'Esto no es un enlace de proxy de Telegram.',
  'Bu telefonun tarayıcı bileşeni bunu desteklemiyor.':
      'El componente de navegador de este teléfono no lo admite.',
  'Bütün telefonda reklamları ve izleyicileri engeller':
      'Bloquea anuncios y rastreadores en todo el teléfono',
  'Bütün telefonda şifreli DNS': 'DNS seguro en todo el teléfono',
  'Dene': 'Probar',
  'Discord, Slack gibi web servisleri DNS ve SNI engellerine takılmadan açılır. VPN gerekmez, kendi VPN\'inizle de çakışmaz.':
      'Servicios web como Discord y Slack se abren sin quedar atrapados en bloqueos de DNS y SNI. No necesita VPN y no interfiere con tu propia VPN.',
  'Elle ekle': 'Añadir manualmente',
  'En hızlı seçeneklerden biri; gizlilik odaklı':
      'Una de las opciones más rápidas; centrada en la privacidad',
  'Engellenen servislere erişin ve DNS sorgularınızı gizleyin. Sunucu yok, hesap yok.':
      'Accede a servicios bloqueados y oculta tus consultas DNS. Sin servidores ni cuenta.',
  'Engellenen servislere erişin, DNS sorgularınızı gizleyin, reklamları engelleyin':
      'Accede a servicios bloqueados, oculta tus consultas DNS, bloquea anuncios',
  'Erişim kalkanı': 'Escudo de acceso',
  'Erişim kalkanı açıldı. Web servislerini yeniden açınca devreye girer.':
      'El escudo de acceso está activado. Se aplica al volver a abrir los servicios web.',
  'Geçerli bir MTProto anahtarı girin.': 'Introduce una clave MTProto válida.',
  'Google\'ın genel DNS\'i': 'DNS público de Google',
  'Güvenli bağlantı': 'Conexión segura',
  'Her zaman açık': 'Siempre activado',
  'Hızlı ayarlar kutucuğu': 'Mosaico de ajustes rápidos',
  'Hızı ölç': 'Medir velocidad',
  'Kapalı': 'Desactivado',
  'Kullanıcı adı (isteğe bağlı)': 'Usuario (opcional)',
  'Kullanılıyor': 'En uso',
  'Ortalama {ms} ms · {cached} önbellekten · {failed} başarısız':
      'Promedio {ms} ms · {cached} desde caché · {failed} fallidas',
  'Parola (isteğe bağlı)': 'Contraseña (opcional)',
  'Port': 'Puerto',
  'Proxy bağlantısı': 'Enlace de proxy',
  'Proxy ekle': 'Añadir proxy',
  'Proxy eklemek için önce Telegram bağlantısını başlatın.':
      'Para añadir un proxy, primero inicia la conexión con Telegram.',
  'Proxy eklendi ve Telegram için açıldı.':
      'Proxy añadido y activado para Telegram.',
  'Sunucu': 'Servidor',
  'Sunucu ve port (1–65535) gerekli.':
      'Se necesitan servidor y puerto (1–65535).',
  'Telefon açılınca kendiliğinden başlasın: sistemin VPN ayarlarında Mesa için "Her zaman açık VPN"i seçin.':
      'Para que se inicie solo al encender el teléfono, elige "VPN siempre activada" para Mesa en los ajustes de VPN del sistema.',
  'Telefonun "Özel DNS" ayarı bir sunucuya sabitlenmiş; o ayar kapatılmadan şifreli DNS etkisiz kalabilir.':
      'El ajuste "DNS privado" del teléfono está fijado a un servidor; el DNS seguro puede no tener efecto hasta que lo desactives.',
  'Telegram proxy': 'Proxy de Telegram',
  'Telegram\'a doğrudan erişim': 'Acceso directo a Telegram',
  'Ulaşılamıyor': 'Inaccesible',
  'VPN izni verilmedi. Açmak için yeniden deneyin.':
      'No se concedió el permiso de VPN. Vuelve a intentarlo para activarlo.',
  'Web servisleri için erişim kalkanı': 'Escudo de acceso para servicios web',
  'Zararlı siteleri engeller; kâr amacı gütmeyen kuruluş':
      'Bloquea sitios maliciosos; gestionado por una organización sin ánimo de lucro',
  'Zararlı sitelerle birlikte yetişkin içeriği de engeller':
      'Bloquea el contenido para adultos además de los sitios maliciosos',
  'Zararlı ve oltalama sitelerini engeller':
      'Bloquea sitios maliciosos y de phishing',
  '{connections} bağlantı · {splits} engel aşma':
      '{connections} conexiones · {splits} bloqueos evitados',
  '{count, plural, one{# sorgu} other{# sorgu}}':
      '{count, plural, one{# consulta} other{# consultas}}',
  'Ölçülüyor…': 'Midiendo…',
  'Şifreli DNS': 'DNS seguro',
  'Şifreli DNS ve erişim kalkanı': 'DNS seguro y escudo de acceso',
  'Şifreli DNS, operatörün DNS engellerini aşar ve hangi sitelere girdiğinizi operatörden gizler. IP adresinizi gizlemez; tam bir VPN değildir. DNS sorguları seçtiğiniz sağlayıcıya gider, Mesa\'nın sunucusu yoktur.':
      'El DNS seguro evita los bloqueos de DNS de tu operador y le oculta qué sitios visitas. No oculta tu dirección IP; no es una VPN completa. Las consultas DNS van al proveedor que elijas; Mesa no tiene servidores.',
  // 2. aşama: tam VPN, odak modu, otomatik yedek, balonlar (1.2)
  '3 saat': '3 horas',
  'Acil durum': 'Emergencias',
  'Aynı kişi 5 dakika içinde 3 kez yazarsa bildirim gelir.':
      'Si la misma persona escribe 3 veces en 5 minutos, recibes una notificación.',
  'Açık': 'Activado',
  'Açık · siz kapatana kadar': 'Activado · hasta que lo desactives',
  'Açık · {time} saatine kadar': 'Activado · hasta las {time}',
  'Bağlantı yoksa interneti kes': 'Bloquear internet sin la VPN',
  'Bağlanıyor… sunucudan henüz yanıt yok':
      'Conectando… el servidor aún no responde',
  'Bağlı': 'Conectado',
  'Başlangıç': 'Inicio',
  'Ben kapatana kadar': 'Hasta que lo desactive',
  'Bildirim panelindeki "Odak modu" kutucuğuyla da tek dokunuşla açıp kapatabilirsiniz.':
      'También puedes activarlo y desactivarlo con un toque desde el mosaico "Modo concentración" del panel de notificaciones.',
  'Bildirimdeki sohbet ekranın üstünde yüzen balonda açılır; uygulamayı açmadan yanıtlayın':
      'El chat de la notificación se abre en una burbuja flotante; responde sin abrir la app',
  'Birleşik bildirimler kapalı: WhatsApp gibi uygulamaların kendi bildirimleri yine ses çıkarabilir. Odak modunun her şeyi susturması için birleşik bildirimleri açın.':
      'Las notificaciones unificadas están desactivadas: apps como WhatsApp aún pueden sonar con sus propias notificaciones. Actívalas para que el modo concentración lo silencie todo.',
  'Bitiş': 'Fin',
  'Bu yapılandırma bu telefonda açılamıyor; silip yeniden içe aktarın.':
      'Esta configuración no se puede abrir en este teléfono; elimínala e impórtala de nuevo.',
  'Bütün trafiğiniz kendi WireGuard sunucunuz ya da bir VPN sağlayıcısı üzerinden geçer; IP adresiniz değişir.':
      'Todo tu tráfico pasa por tu propio servidor WireGuard o un proveedor de VPN; tu dirección IP cambia.',
  'Dosya okunamadı.': 'No se pudo leer el archivo.',
  'Dosyadan içe aktar': 'Importar desde archivo',
  'Eklenecek sohbet yok.': 'No hay chats para añadir.',
  'Her gün': 'Cada día',
  'Her gün belirli saatlerde': 'A horas fijas cada día',
  'Her hafta': 'Cada semana',
  'Israrla yazana izin ver': 'Dejar pasar mensajes insistentes',
  'Kayıtlı parola açılamadı; otomatik yedeği yeniden açın.':
      'No se pudo abrir la contraseña guardada; vuelve a activar la copia automática.',
  'Klasör seç': 'Elegir carpeta',
  'Klasöre yazılamadı; klasörü yeniden seçin.':
      'No se pudo escribir en la carpeta; vuelve a elegirla.',
  'Odak modu': 'Modo concentración',
  'Odak modu açık': 'Modo concentración activado',
  'Odaktayken yalnızca VIP kişiler, "Önemli işaretle" kuralına uyan mesajlar ve acil durumlar bildirim verir. Diğer mesajlar Mesa\'da sessizce birikir; odak bitince kısa bir özet gelir.':
      'Durante la concentración solo te notifican los VIP, los mensajes que cumplen la regla "Marcar como importante" y las emergencias. Los demás se acumulan en silencio en Mesa; al terminar recibes un resumen.',
  'Otomatik yedek': 'Copia automática',
  'Otomatik yedek açıldı; ilk yedek şimdi alınıyor.':
      'Copia automática activada; se está haciendo la primera ahora.',
  'Panodan yapıştır': 'Pegar del portapapeles',
  'Sabah 08:00\'e kadar': 'Hasta las 08:00 de la mañana',
  'Seçtiğiniz klasöre düzenli olarak şifreli yedek alınır; en yeni 5 otomatik yedek saklanır. Otomatik çalışabilmesi için parola bu telefonda, telefonun güvenli donanım anahtarıyla şifrelenip saklanır.':
      'Se guardan copias cifradas con regularidad en la carpeta que elijas; se conservan las 5 copias automáticas más recientes. Para que funcione sola, la contraseña se guarda en este teléfono, cifrada con la clave de hardware segura del teléfono.',
  'Seçtiğiniz klasöre düzenli, şifreli yedek':
      'Copias cifradas periódicas en la carpeta que elijas',
  'Sistemin VPN ayarlarında Mesa için "Her zaman açık VPN" ve "VPN olmadan bağlantıları engelle"yi açın.':
      'En los ajustes de VPN del sistema, activa "VPN siempre activada" y "Bloquear conexiones sin VPN" para Mesa.',
  'Sohbet balonları': 'Burbujas de chat',
  'Sohbet bulunamadı.': 'No se encontró el chat.',
  'Sunucudan uzun süredir yanıt yok': 'El servidor no responde desde hace rato',
  'Sunucunun adresi çözülemedi. İnternet bağlantınızı kontrol edin.':
      'No se pudo resolver la dirección del servidor. Revisa tu conexión a internet.',
  'Tam VPN (WireGuard)': 'VPN completa (WireGuard)',
  'Tünel açılamadı ({code}).': 'No se pudo iniciar el túnel ({code}).',
  'VIP ekle': 'Añadir VIP',
  'VIP kişiler': 'VIP',
  'VIP kişiler dışında sessizlik; zamanlanabilir, bitince özet':
      'Silencio salvo para los VIP; se puede programar, resumen al terminar',
  'VIP kişiler odaktayken de size ulaşır: aile, yakın arkadaşlar, iş için önemli biri.':
      'Los VIP pueden contactarte incluso en concentración: familia, amigos cercanos, alguien importante del trabajo.',
  'WireGuard yapılandırması': 'Configuración de WireGuard',
  'WireGuard yapılandırması eklendi.': 'Configuración de WireGuard añadida.',
  'Yalnızca VIP kişiler bildirim verir': 'Solo los VIP te notifican',
  'Yapılandırma dosyasını kendi sunucunuzdan ya da WireGuard dosyası veren bir sağlayıcıdan (ör. Proton VPN\'in ücretsiz planı) alabilirsiniz.':
      'Puedes obtener el archivo de configuración de tu propio servidor o de un proveedor que ofrezca archivos WireGuard (por ejemplo, el plan gratuito de Proton VPN).',
  'Yapılandırma okunamadı. Dosyanın bir WireGuard (.conf) dosyası olduğundan emin olun.':
      'No se pudo leer la configuración. Asegúrate de que sea un archivo WireGuard (.conf).',
  'Yapılandırmada sunucu ([Peer]) yok.':
      'La configuración no tiene servidor ([Peer]).',
  'Yedek yazılamadı; yer kalmamış olabilir.':
      'No se pudo escribir la copia; puede que no quede espacio.',
  'Zamanlama': 'Programación',
  'son: {when}': 'última: {when}',
  'yalnızca bazı adresler': 'solo algunas direcciones',
  '{count, plural, one{# mesaj susturuldu} other{# mesaj susturuldu}}':
      '{count, plural, one{# mensaje silenciado} other{# mensajes silenciados}}',
  'Çıkar': 'Quitar',
  'İçe aktar': 'Importar',
  'Şimdi yedekle': 'Hacer copia ahora',
  '↓ {rx} · ↑ {tx}': '↓ {rx} · ↑ {tx}',
  // 1.2.1: WhatsApp'ta yazılan yanıtlar
  'Ayarı aç': 'Abrir ajuste',
  'WhatsApp\'ta yazdıklarım': 'Lo que escribo en WhatsApp',
  'WhatsApp\'ta yazdıklarınız da görünsün':
      'Mostrar también lo que escribes en WhatsApp',
  'WhatsApp\'tan yazdığınız yanıtlar burada görünmüyor. Görünsün mü?':
      'Las respuestas que escribes en WhatsApp no aparecen aquí. ¿Mostrarlas?',
  // 1.2.1: otomatik gönderim
  'Bu servis şunları yapar:\n• WhatsApp\'ta açık sohbete gelen ve sizin yazdığınız yeni mesajlar Mesa\'daki aynı sohbete eklenir; sohbet Mesa\'da yoksa açılır.\n• WhatsApp\'ta açtığınız sohbet burada da okunmuş sayılır.\n• Mesa\'dan yazdığınız mesaj, Mesa\'dan çıkmadan WhatsApp üzerinden gönderilir.\n\nAçılan sayfada "İndirilen uygulamalar"a girip "Mesa: WhatsApp yanıtlarım"ı açın. Yalnızca WhatsApp okunur ve hiçbir şey telefondan çıkmaz.\n\nAyar soluk görünüyorsa: Uygulama bilgisi → ⋮ → Kısıtlanmış ayarlara izin ver.':
      'Este servicio:\n• Añade al mismo chat en Mesa los mensajes nuevos del chat de WhatsApp que tienes abierto, recibidos y escritos por ti, y crea el chat en Mesa si no existe.\n• Marca aquí como leídos los chats que abres en WhatsApp.\n• Envía por WhatsApp los mensajes que escribes en Mesa sin salir de Mesa.\n\nEn la página siguiente, entra en "Apps descargadas" y activa "Mesa: mis respuestas de WhatsApp". Solo se lee WhatsApp y nada sale de tu teléfono.\n\nSi el ajuste aparece atenuado: Información de la app → ⋮ → Permitir ajustes restringidos.',
  'WhatsApp\'ta yazdıklarınız ve orada açıkken gelenler de Mesa\'da görünür; Mesa\'dan yazdıklarınız WhatsApp\'ta kendiliğinden gönderilir':
      'Lo que escribes en WhatsApp y lo que llega mientras un chat está abierto allí también aparece en Mesa; los mensajes que escribes en Mesa se envían solos en WhatsApp',
  'Mesajınız {name} üzerinden, Mesa\'dan çıkmadan gönderilir.':
      'Tu mensaje se envía a través de {name} sin salir de Mesa.',
  'Otomatik gönder': 'Envío automático',
  'WhatsApp\'ta gönderilemedi; mesajınız yazma alanında.':
      'No se pudo enviar en WhatsApp; tu mensaje está en el cuadro de texto.',
  // Mesajdan işe tek dokunuş
  'Açılamadı.': 'No se pudo abrir.',
  'Bağlantıyı aç': 'Abrir enlace',
  'E-postayı kopyala': 'Copiar correo',
  'Haritada aç': 'Abrir en el mapa',
  'Hatırlat': 'Recordarme',
  'Hatırlatma kurulamadı.': 'No se pudo crear el recordatorio.',
  'IBAN\'ı kopyala': 'Copiar IBAN',
  'Kodu kopyala': 'Copiar código',
  'Kopyalandı': 'Copiado',
  'Takvim uygulaması bulunamadı.': 'No se encontró ninguna app de calendario.',
  'Takvime ekle': 'Añadir al calendario',
  'Telefonla ara': 'Llamar',
  '{time} için hatırlatma kuruldu': 'Recordatorio creado para las {time}',
  // Sesli mesajı yazıya çevirme
  'Başka bir sesli mesaj çevriliyor; az sonra yeniden deneyin.':
      'Se está transcribiendo otro mensaje de voz; inténtalo de nuevo en un momento.',
  'Bu dilin konuşma paketi indiriliyor; biraz sonra yeniden deneyin.':
      'Se está descargando el paquete de voz de este idioma; inténtalo de nuevo en breve.',
  'Bu sesli mesajın dosyası telefonda bulunamadı. WhatsApp\'ta bir kez açıp indirin, sonra yeniden deneyin.':
      'El archivo de este mensaje de voz no está en el teléfono. Ábrelo una vez en WhatsApp para descargarlo y vuelve a intentarlo.',
  'Bu telefon sesli mesajı yazıya çeviremiyor (Android 13 gerekli).':
      'Este teléfono no puede transcribir mensajes de voz (requiere Android 13).',
  'Bu, WhatsApp\'ın sesli mesaj klasörü değil. "WhatsApp Voice Notes" klasörünü seçin.':
      'Esa no es la carpeta de mensajes de voz de WhatsApp. Elige la carpeta "WhatsApp Voice Notes".',
  'Klasörü seç': 'Elegir carpeta',
  'Sesli mesaj yazıya çevrilemedi.':
      'No se pudo transcribir el mensaje de voz.',
  'Sesli mesajda anlaşılır konuşma bulunamadı.':
      'No se encontró habla clara en el mensaje de voz.',
  'WhatsApp ses klasörü seçilmedi.':
      'No se eligió la carpeta de voz de WhatsApp.',
  'WhatsApp sesli mesajları': 'Mensajes de voz de WhatsApp',
  'WhatsApp sesli mesajları bildirime koymuyor, telefondaki kendi klasöründe saklıyor. Yazıya çevirmek için Mesa\'nın o klasörü okuması gerekiyor.\n\nAçılan sayfada "Bu klasörü kullan"a, sonra "İzin ver"e dokunun. Ses telefondan çıkmaz; yazıya çevirme telefonda yapılır.':
      'WhatsApp no pone los mensajes de voz en sus notificaciones; los guarda en su propia carpeta del teléfono. Para transcribirlos, Mesa necesita leer esa carpeta.\n\nEn la página siguiente, toca "Usar esta carpeta" y luego "Permitir". El audio no sale de tu teléfono; la transcripción se hace en el teléfono.',
  'Yazıya çevir': 'Transcribir',
  'Yazıya çevirmek için Android mikrofon izni istiyor; mikrofon kullanılmaz.':
      'Android pide permiso de micrófono para transcribir; el micrófono no se usa.',
  'Yazıya çevrildi': 'Transcrito',
  'Yazıya çevriliyor…': 'Transcribiendo…',
  // Mesaj çevirisi
  'Başka dildeki mesajlar bu paketlerle telefonda çevrilir; mesajlar hiçbir yere gönderilmez. Sildiğiniz paket gerekince yeniden sorulur.': 'Los mensajes en otros idiomas se traducen en el teléfono con estos paquetes; los mensajes no se envían a ningún sitio. Si borras un paquete, se te volverá a ofrecer cuando haga falta.',
  'Başka dildeki mesajlar telefonda çevrilir; indirilen paketler burada': 'Los mensajes en otros idiomas se traducen en el teléfono; aquí están los paquetes descargados',
  'Bu dil ({language}) telefonda çevrilemiyor.': 'Este idioma ({language}) no se puede traducir en el teléfono.',
  'Bu mesaj zaten sizin dilinizde.': 'Este mensaje ya está en tu idioma.',
  'Bu mesajda çevrilecek yazı yok.': 'Este mensaje no tiene texto que traducir.',
  'Dil paketi indirilemedi. İnternet bağlantınızı kontrol edip yeniden deneyin.': 'No se pudo descargar el paquete de idioma. Comprueba tu conexión a internet e inténtalo de nuevo.',
  'Dil paketi indiriliyor…': 'Descargando paquete de idioma…',
  'Dil paketi silinemedi.': 'No se pudo borrar el paquete de idioma.',
  'Dil paketleri indirilsin mi?': '¿Descargar paquetes de idioma?',
  'Henüz dil paketi indirilmedi. Bir mesajın altındaki "Çevir"e dokununca gereken paket sorulur.': 'Aún no hay paquetes de idioma descargados. Al tocar "Traducir" debajo de un mensaje, se te pedirá el paquete necesario.',
  'Mesaj çevrilemedi.': 'No se pudo traducir el mensaje.',
  'Mesajın dili anlaşılamadı.': 'No se pudo identificar el idioma del mensaje.',
  'Telefonda çevrilir; mesaj hiçbir yere gönderilmez': 'Se traduce en el teléfono; el mensaje no se envía a ningún sitio',
  '{language} dil paketi indirilsin mi?': '¿Descargar el paquete de {language}?',
  'Çevir': 'Traducir',
  'Çeviri': 'Traducción',
  'Çeviri dil paketleri': 'Paquetes de idioma para traducir',
  'Çeviri telefonda yapılır; mesajlarınız hiçbir yere gönderilmez. Bunun için Google\'ın çeviri paketi bir kez indirilir (dil başına yaklaşık 30 MB), sonra internetsiz çalışır.': 'La traducción se hace en el teléfono; tus mensajes no se envían a ningún sitio. Para ello se descarga una vez el paquete de traducción de Google (unos 30 MB por idioma) y después funciona sin internet.',
  'Çeviri · aslı {language}': 'Traducido del {language}',
  'Çeviriyi gizle': 'Ocultar traducción',
  'Çevriliyor…': 'Traduciendo…',
  'İndir ve çevir': 'Descargar y traducir',
  'İndirilecek: {languages}': 'Se descargará: {languages}',
  // Yapay zekâ asistanı
  'API anahtarı': 'Clave de API',
  'Anahtar girilmedi': 'No se ha introducido ninguna clave',
  'Anahtar kaydedildi; asistan hazır.': 'Clave guardada; el asistente está listo.',
  'Anahtar kaydedildi; internet olmadığı için doğrulanamadı.': 'Clave guardada; no se pudo comprobar porque no hay internet.',
  'Anahtar kaydedilemedi.': 'No se pudo guardar la clave.',
  'Anahtar kayıtlı': 'Clave guardada',
  'Anahtar nasıl alınır?': '¿Cómo consigo una clave?',
  'Anahtar silinsin mi?': '¿Borrar la clave?',
  'Anahtarı değiştir': 'Cambiar clave',
  'Anahtarı gir': 'Introducir clave',
  'Anahtarı sil': 'Borrar clave',
  'Anthropic bu anahtarı kabul etmedi. Doğru kopyaladığınızdan emin olun.': 'Anthropic no aceptó esta clave. Asegúrate de haberla copiado bien.',
  'Anthropic hesabınızda kredi kalmadı ya da harcama sınırına ulaşıldı. console.anthropic.com\'dan bakabilirsiniz.': 'Tu cuenta de Anthropic se quedó sin crédito o alcanzó su límite de gasto. Puedes revisarlo en console.anthropic.com.',
  'Anthropic, API ile gönderilen verileri yapay zekâsını eğitmek için kullanmadığını belirtiyor. Ücret, kullandıkça Anthropic hesabınızdaki krediden düşer.': 'Anthropic afirma que no usa los datos enviados a través de la API para entrenar su IA. El coste se descuenta del crédito de tu cuenta de Anthropic según lo uses.',
  'Asistan yanıt veremedi; yeniden deneyin.': 'El asistente no pudo responder; inténtalo de nuevo.',
  'Asistan, yeniden anahtar girene kadar çalışmaz. Anahtar Anthropic hesabınızda kalır; tamamen iptal etmek için console.anthropic.com\'dan silin.': 'El asistente no funcionará hasta que vuelvas a introducir una clave. La clave sigue en tu cuenta de Anthropic; para anularla del todo, bórrala en console.anthropic.com.',
  'Bu API anahtarının bu işe izni yok.': 'Esta clave de API no tiene permiso para esto.',
  'Bu bir Claude API anahtarına benzemiyor; anahtarlar "sk-ant-" ile başlar.': 'Esto no parece una clave de API de Claude; las claves empiezan por "sk-ant-".',
  'Claude API anahtarı': 'Clave de API de Claude',
  'Claude API anahtarı geçersiz ya da silinmiş. Ayarlar\'dan yeniden girin.': 'La clave de API de Claude no es válida o se eliminó. Vuelve a introducirla en Ajustes.',
  'Claude bu isteği yanıtlamadı.': 'Claude no respondió a esta solicitud.',
  'Claude düşünüyor…': 'Claude está pensando…',
  'Claude ile düzelt': 'Mejorar con Claude',
  'Claude ile sohbet özeti, sohbete soru, yanıt önerisi ve mesaj düzeltme': 'Resúmenes de chats, preguntas sobre un chat, sugerencias de respuesta y corrección de mensajes con Claude',
  'Claude şu an çok yoğun; biraz sonra yeniden deneyin.': 'Claude está muy ocupado ahora; inténtalo de nuevo en un rato.',
  'Claude\'a ulaşılamadı. İnternet bağlantınızı kontrol edin.': 'No se pudo conectar con Claude. Comprueba tu conexión a internet.',
  'Daha kibar yap': 'Hacerlo más amable',
  'Daha kısa yap': 'Hacerlo más corto',
  'Dengeli · uzun bir özet yaklaşık 1,5 sent': 'Equilibrado · un resumen largo cuesta unos 1,5 centavos',
  'Dil, sohbetin son mesajlarından anlaşılır; onlar da gönderilir.': 'El idioma se deduce de los últimos mensajes del chat, que también se envían.',
  'Düzeltiliyor…': 'Mejorando…',
  'En akıllısı · uzun bir özet yaklaşık 3 sent': 'El más inteligente · un resumen largo cuesta unos 3 centavos',
  'En hızlısı ve en ucuzu · uzun bir özet 0,1 sentten az': 'El más rápido y barato · un resumen largo cuesta menos de 0,1 centavos',
  'Karşı tarafın diline çevir': 'Traducir a su idioma',
  'Kullan': 'Usar',
  'Model': 'Modelo',
  'Ne gönderilir?': '¿Qué se envía?',
  'Seçili model hesabınızda kullanılamıyor; Ayarlar\'dan başka bir model seçin.': 'El modelo seleccionado no está disponible en tu cuenta; elige otro en Ajustes.',
  'Sohbet asistana gönderilemeyecek kadar uzun.': 'El chat es demasiado largo para enviarlo al asistente.',
  'Sohbete sor': 'Preguntar sobre el chat',
  'Sohbetleri özetler, sohbete sorduğunuz soruyu yanıtlar, yanıt önerir ve yazdığınızı düzeltir. Anthropic\'in yapay zekâsı Claude ile, sizin API anahtarınızla çalışır.': 'Resume chats, responde a tus preguntas sobre un chat, sugiere respuestas y mejora lo que escribes. Usa la IA de Anthropic, Claude, con tu propia clave de API.',
  'Sor': 'Preguntar',
  'Telefonda şifreli saklanır; Mesa\'nın yedeklerine girmez.': 'Se guarda cifrada en el teléfono; no se incluye en las copias de seguridad de Mesa.',
  'Verileriniz ve ücret': 'Tus datos y el coste',
  'Yalnızca siz dokununca': 'Solo cuando tocas',
  'Yanıt öner': 'Sugerir respuestas',
  'Yapay zekâ': 'IA',
  'Yapay zekâ asistanı': 'Asistente de IA',
  'Yapıştır': 'Pegar',
  'Yazdığınız metin Claude\'a gönderilir; siz onaylamadan değişmez.': 'Lo que escribiste se envía a Claude; nada cambia hasta que lo apruebes.',
  'Yazım hatalarını düzelt': 'Corregir la ortografía',
  'Yeniden dene': 'Reintentar',
  'console.anthropic.com\'da hesap açın, kredi yükleyin, "API Keys" bölümünden bir anahtar oluşturup buraya yapıştırın. Anahtarı kimseyle paylaşmayın.': 'Crea una cuenta en console.anthropic.com, añade crédito, crea una clave en "API Keys" y pégala aquí. No compartas la clave con nadie.',
  '{model} · Yapay zekâ yanılabilir': '{model} · La IA puede equivocarse',
  '{title} sohbetinin özeti': 'Resumen del chat: {title}',
  'Çok sık istek gönderildi; biraz bekleyip yeniden deneyin.': 'Demasiadas solicitudes; espera un momento e inténtalo de nuevo.',
  'Önce Ayarlar → Yapay zekâ asistanı bölümünden Claude API anahtarınızı girin.': 'Primero introduce tu clave de API de Claude en Ajustes → Asistente de IA.',
  'Önerilen metin': 'Texto sugerido',
  'Öneriler hazırlanıyor…': 'Preparando sugerencias…',
  'Önerileri kapat': 'Cerrar sugerencias',
  'Örn. Ne zaman buluşuyorduk?': 'Ej.: ¿Cuándo quedamos?',
  'Özet ve soruda sohbetin son mesajları, yanıt önerisinde son 30 mesaj, düzeltmede yalnızca yazdığınız metin (çeviride son 10 mesaj da) gönderen adlarıyla Anthropic\'e gider. Kendiliğinden hiçbir şey gönderilmez; asistan sizin yerinize mesaj atmaz.': 'En resúmenes y preguntas, los mensajes recientes del chat; en sugerencias, los últimos 30 mensajes; al corregir, solo lo que escribiste (y los últimos 10 mensajes al traducir) se envían a Anthropic con los nombres de los remitentes. Nada se envía por sí solo y el asistente nunca envía mensajes por ti.',
  'Özetle': 'Resumir',
  // Bilgisayardan Mesa
  '"Bağlan"a tıklayın; telefonunuzdaki bildirimde aynı kodu görüyorsanız "İzin ver"e dokunun.': 'Haz clic en "Conectar"; si la notificación del teléfono muestra el mismo código, toca "Permitir".',
  'Aynı Wi-Fi\'deki bilgisayarın tarayıcısından okuyun ve yanıtlayın': 'Lee y responde desde el navegador de un ordenador en la misma Wi-Fi',
  'Açık; bilgisayar bağlanabilir': 'Activado; un ordenador puede conectarse',
  'Bağlantı': 'Conexión',
  'Bağlantıyı kes': 'Desconectar',
  'Bağlı bilgisayarlar': 'Ordenadores conectados',
  'Bilgisayarda açılacak adres': 'Dirección para abrir en el ordenador',
  'Bilgisayardan Mesa': 'Mesa en el ordenador',
  'Bilgisayarın tarayıcısında yukarıdaki adresi açın.': 'Abre la dirección de arriba en el navegador del ordenador.',
  'Bilgisayarınız telefonla aynı Wi-Fi\'ye bağlı olsun.': 'Asegúrate de que el ordenador esté en la misma Wi-Fi que el teléfono.',
  'Henüz bağlı bilgisayar yok': 'Aún no hay ordenadores conectados',
  'Mesajlarınızı aynı Wi-Fi\'deki bir bilgisayarın tarayıcısından okuyup yanıtlayın. Bağlantı şifrelidir ve internete çıkmaz; telefon açık ve Wi-Fi\'de olmalı.': 'Lee y responde tus mensajes desde el navegador de un ordenador en la misma Wi-Fi. La conexión está cifrada y no sale a internet; el teléfono debe estar encendido y en la Wi-Fi.',
  'Ortak bir bilgisayarda işiniz bitince tarayıcıda "Çıkış yap"a tıklayın ya da buradan bağlantıyı kesin. 30 gün kullanılmayan bağlantı kendiliğinden kapanır.': 'En un ordenador compartido, haz clic en "Cerrar sesión" en el navegador al terminar, o desconéctalo aquí. Una conexión sin usar durante 30 días se cierra sola.',
  'Son kullanım: {when}': 'Último uso: {when}',
  'Tarayıcı bir güvenlik uyarısı gösterirse "Gelişmiş"e, ardından "ilerle" ya da "devam et" yazan bağlantıya tıklayın. Sertifikayı telefonunuz oluşturduğu için tarayıcı onu tanımıyor; bağlantı yine de şifreli.': 'Si el navegador muestra una advertencia de seguridad, haz clic en "Configuración avanzada" y luego en el enlace "Acceder" o "Continuar". El navegador no reconoce el certificado porque lo creó tu teléfono; la conexión sigue cifrada.',
  'Telefon bir Wi-Fi ağına bağlı değil': 'El teléfono no está conectado a una red Wi-Fi',
  'Wi-Fi\'ye bağlanınca adres burada görünür.': 'La dirección aparecerá aquí cuando te conectes a la Wi-Fi.',
};
