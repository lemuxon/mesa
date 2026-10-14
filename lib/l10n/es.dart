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
};
