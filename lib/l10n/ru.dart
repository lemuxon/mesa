// Türkçe metin → çeviri. Anahtarlar test/l10n_test.dart ile denetlenir
// (yeni metin: tr() ekleyin, buraya ve diğer dillere çevirisini yazın).
const ru = <String, String>{
  'Pazartesi': 'Понедельник',
  'Salı': 'Вторник',
  'Çarşamba': 'Среда',
  'Perşembe': 'Четверг',
  'Cuma': 'Пятница',
  'Cumartesi': 'Суббота',
  'Pazar': 'Воскресенье',
  'Bugün': 'Сегодня',
  'Dün': 'Вчера',
  '{day} Ocak': '{day} января',
  '{day} Şubat': '{day} февраля',
  '{day} Mart': '{day} марта',
  '{day} Nisan': '{day} апреля',
  '{day} Mayıs': '{day} мая',
  '{day} Haziran': '{day} июня',
  '{day} Temmuz': '{day} июля',
  '{day} Ağustos': '{day} августа',
  '{day} Eylül': '{day} сентября',
  '{day} Ekim': '{day} октября',
  '{day} Kasım': '{day} ноября',
  '{day} Aralık': '{day} декабря',
  '{day}.{month}.{year}': '{day}.{month}.{year}',
  'bugün {clock}': 'сегодня {clock}',
  'yarın {clock}': 'завтра {clock}',
  'şimdi': 'сейчас',
  '{n} dk': '{n} мин',
  '{n} sa': '{n} ч',
  '{n} g': '{n} д',
  'B': 'Б',
  'KB': 'КБ',
  'MB': 'МБ',
  'GB': 'ГБ',
  'Çıkartma': 'Стикер',
  '📷 Fotoğraf': '📷 Фото',
  'Otomatik yanıt': 'Автоответ',
  'Sessize al': 'Без звука',
  'Önemli işaretle': 'Отметить как важное',
  '15 dakika': '15 минут',
  '1 saat': '1 час',
  '6 saat': '6 часов',
  '1 gün': '1 день',
  'Pzt': 'Пн',
  'Sal': 'Вт',
  'Çar': 'Ср',
  'Per': 'Чт',
  'Cum': 'Пт',
  'Cmt': 'Сб',
  'Paz': 'Вс',
  'hafta içi': 'по будням',
  'hafta sonu': 'по выходным',
  'Tüm uygulamalar': 'Все приложения',
  'Kimden: "{sender}"': 'От: «{sender}»',
  'İçerik: {words}': 'Содержит: {words}',
  'gruplar dahil': 'включая группы',
  'Süresiz': 'Бессрочно',
  '7 gün': '7 дней',
  '30 gün': '30 дней',
  '90 gün': '90 дней',
  '1 yıl': '1 год',
  'Tamam 👍': 'Хорошо 👍',
  'Şu an müsait değilim, sonra yazarım.':
      'Сейчас не могу говорить, напишу позже.',
  'Yoldayım, birazdan oradayım.': 'Я в пути, скоро буду.',
  'Teşekkürler!': 'Спасибо!',
  '{step} bir giriş adımı değil': '{step} — не шаг входа',
  '🎥 Video': '🎥 Видео',
  '🎵 Ses dosyası': '🎵 Аудиофайл',
  '🎤 Sesli mesaj': '🎤 Голосовое сообщение',
  '🎤 Ses': '🎤 Аудио',
  '⏺ Görüntülü mesaj': '⏺ Видеосообщение',
  '📍 Konum': '📍 Местоположение',
  '📄 Dosya': '📄 Файл',
  '👤 Kişi': '👤 Контакт',
  '📊 Anket': '📊 Опрос',
  'Arşiv': 'Архив',
  'Arşivde sohbet yok.\nGelen kutusunda bir sohbete uzun basıp "Arşivle"yi seçebilirsiniz.':
      'В архиве нет чатов.\nУдерживайте чат во входящих и выберите «В архив».',
  'Yedekleniyor… Fotoğraflar çoksa biraz sürebilir.':
      'Создание копии… Если фото много, это займёт некоторое время.',
  'Yedek kaydedildi: {messages} mesaj, {files} fotoğraf ({bytes}).':
      'Копия сохранена: {messages, plural, one{# сообщение} few{# сообщения} many{# сообщений} other{# сообщения}}, {files, plural, one{# фото} few{# фото} many{# фото} other{# фото}} ({bytes}).',
  'Yedek alınamadı: {error}': 'Не удалось создать копию: {error}',
  'bilinmeyen hata': 'неизвестная ошибка',
  'Yedekten geri yüklensin mi?': 'Восстановить из копии?',
  'Bu telefondaki Mesa mesajları, kişileri ve kuralları yedektekilerle değiştirilir. Telegram ve web servisi girişleri yedekte yoktur; gerekirse yeniden giriş yaparsınız.':
      'Сообщения, люди и правила Mesa на этом телефоне будут заменены данными из копии. Входы в Telegram и веб-сервисы в копию не входят; при необходимости войдите заново.',
  'Vazgeç': 'Отмена',
  'Dosya seç': 'Выбрать файл',
  'Geri yükleniyor…': 'Восстановление…',
  'Geri yüklendi: {messages} mesaj, {files} fotoğraf.':
      'Восстановлено: {messages, plural, one{# сообщение} few{# сообщения} many{# сообщений} other{# сообщения}}, {files, plural, one{# фото} few{# фото} many{# фото} other{# фото}}.',
  'Şifre yanlış. Yedeği alırken girdiğiniz şifreyi deneyin.':
      'Неверный пароль. Попробуйте пароль, который вы ввели при создании копии.',
  'Dosya açılamadı: {error}': 'Не удалось открыть файл: {error}',
  'yedek bozuk': 'копия повреждена',
  'Geri yüklenemedi: {error}': 'Не удалось восстановить: {error}',
  'Yedek': 'Резервная копия',
  'Yedekle': 'Создать копию',
  'Mesajlar, kişiler, kurallar ve fotoğraflar; şifreli dosya. Henüz yedek alınmadı.':
      'Сообщения, люди, правила и фото; зашифрованный файл. Копий пока нет.',
  'Mesajlar, kişiler, kurallar ve fotoğraflar; şifreli dosya. Son yedek: {when}':
      'Сообщения, люди, правила и фото; зашифрованный файл. Последняя копия: {when}',
  'Yedekten geri yükle': 'Восстановить из копии',
  'Yeni telefonda ya da sıfırlamadan sonra':
      'На новом телефоне или после сброса',
  'En az 8 karakter olmalı.': 'Не меньше 8 символов.',
  'Şifreler aynı değil.': 'Пароли не совпадают.',
  'Yedek şifresi': 'Пароль копии',
  'Yedeğin şifresi': 'Пароль копии',
  'Bu şifreyi unutursanız yedek açılamaz; kimse kurtaramaz. Bir yere not edin.':
      'Если вы забудете этот пароль, копию нельзя будет открыть, и никто не сможет её восстановить. Запишите его.',
  'Şifre': 'Пароль',
  'Göster': 'Показать',
  'Gizle': 'Скрыть',
  'Şifre (tekrar)': 'Пароль (ещё раз)',
  'Aç': 'Открыть',
  'Açıldı. Bu sohbetten yeni mesaj gelince yanıtlarınız {appName} açılmadan, doğrudan gider.':
      'Включено. Как только в этом чате появится новое сообщение, ваши ответы будут уходить сразу, без открытия {appName}.',
  'Mesajınız bu sohbete de kaydedildi.':
      'Ваше сообщение сохранено и в этом чате.',
  'Gönderilmedi': 'Не отправлено',
  'Tekrar gönder': 'Отправить снова',
  'Mesaj gönderilemedi': 'Сообщение не отправлено',
  'Sil': 'Удалить',
  'Karşı tarafa hiç gitmedi': 'Оно так и не дошло до собеседника',
  'Kaydedilenlerden çıkar': 'Убрать из сохранённых',
  'Kaydet': 'Сохранить',
  'Tüm uygulamalardan kaydedilenler tek listede':
      'Сохранённые сообщения из всех приложений в одном списке',
  'Kopyala': 'Копировать',
  'Kaydedilenlerden çıkarıldı.': 'Убрано из сохранённых.',
  'Kaydedildi ⭐': 'Сохранено ⭐',
  'Kopyalandı.': 'Скопировано.',
  'Yeniden gönderiliyor…': 'Повторная отправка…',
  'Gönderilemedi. Bağlantıyı kontrol edin.':
      'Не удалось отправить. Проверьте подключение.',
  'Ne zaman gönderilsin?': 'Когда отправить?',
  '⏰ {when} Telegram\'dan gönderilecek.':
      '⏰ Будет отправлено через Telegram {when}.',
  '⏰ {when} kendiliğinden gönderilecek.':
      '⏰ Будет отправлено автоматически {when}.',
  '⏰ {when} bildirim gelecek: dokununca {appName} mesaj yazılmış olarak açılır, ➤ ile gönderirsiniz. {viaAppNote}':
      '⏰ {when} придёт уведомление: нажмите на него, и {appName} откроется с готовым сообщением — отправьте его кнопкой ➤. {viaAppNote}',
  'O zamana kadar bu sohbetten yeni mesaj gelirse kendiliğinden gider.':
      'Если до этого в чате появится новое сообщение, оно отправится автоматически.',
  'Planlı mesajlar': 'Запланированные сообщения',
  'İptal et': 'Отменить',
  '{appName} bu sohbet için şu an doğrudan gönderme yolu vermiyor: zamanı gelince bildirime dokunup {appName} içinde gönderirsiniz. {viaAppNote}':
      '{appName} сейчас не позволяет отправлять в этот чат напрямую: в нужное время нажмите на уведомление и отправьте в {appName}. {viaAppNote}',
  'Telegram bağlantısı açık değil.': 'Подключение к Telegram не открыто.',
  '{appName} açılamadı.': 'Не удалось открыть {appName}.',
  'Gönderiliyor…': 'Отправка…',
  '{kind} gönderiliyor…': 'Отправка: {kind}…',
  '{appName} açıldı; göndermek için orada ➤ düğmesine dokunun.':
      '{appName} открыт; нажмите там ➤, чтобы отправить.',
  '{appName} dışarıdan {kind} kabul etmiyor.':
      '{appName} не принимает {kind} из других приложений.',
  'Gönderilemedi.': 'Не удалось отправить.',
  'Fotoğraf': 'Фото',
  'Video': 'Видео',
  'Sesli mesaj': 'Голосовое сообщение',
  'Dosya': 'Файл',
  'Planlı mesaj': 'Запланированное сообщение',
  'Zaman seç': 'Выбрать время',
  'Gönderilecek mesaj': 'Сообщение для отправки',
  'Sesli mesaj için mikrofon izni gerekli.':
      'Для голосовых сообщений нужен доступ к микрофону.',
  'Kayıt başlatılamadı.': 'Не удалось начать запись.',
  'Kayıt çok kısa.': 'Запись слишком короткая.',
  'Uygulama açılamadı.': 'Не удалось открыть приложение.',
  'Siz': 'Вы',
  'Hazır yanıtlar': 'Быстрые ответы',
  'Gizli okuma açık: Telegram\'da "görüldü" ve "yazıyor" gitmez.':
      'Скрытое чтение включено: Telegram не отправит «прочитано» и «печатает».',
  'Burada okumak {name}\'ta "görüldü" göndermez. Yanıt verirseniz gider.':
      'Чтение здесь не отправляет «прочитано» в {name}. Оно уйдёт, если вы ответите.',
  'Görüldü gönderilmez': '«Прочитано» не отправляется',
  'Medya': 'Медиа',
  '{name} uygulamasında aç': 'Открыть в {name}',
  'Bu sohbette henüz mesaj yok.': 'В этом чате пока нет сообщений.',
  '{count} planlı mesaj · ilki {when}':
      '{count, plural, one{# запланированное сообщение} few{# запланированных сообщения} many{# запланированных сообщений} other{# запланированного сообщения}} · первое {when}',
  'Mesajınız {name}\'ta hazır açılır; orada ➤ ile gönderin.':
      'Ваше сообщение откроется готовым в {name}; отправьте его там кнопкой ➤.',
  'Klavye': 'Клавиатура',
  'Emoji': 'Эмодзи',
  '{appName} ile yaz': 'Написать в {appName}',
  'Mesaj yaz': 'Сообщение',
  'Çıkartma ve GIF': 'Стикеры и GIF',
  'Fotoğraf, video, dosya': 'Фото, видео, файл',
  'Zamanla': 'Запланировать',
  'Kamera': 'Камера',
  'Sesli mesajı gönder': 'Отправить голосовое',
  'Gönder (basılı tutun: zamanla)': 'Отправить (удерживайте: запланировать)',
  'Web servislerine yanıt, servisin kendi sayfasından yazılır.':
      'Ответы веб-сервисам пишутся на странице самого сервиса.',
  '{name} telefonda kurulu değil.': '{name} не установлен на этом телефоне.',
  '{name} sayfasında yanıtla': 'Ответить на странице {name}',
  'çevrimiçi': 'в сети',
  'son görülme {seen}': 'был(а) {seen}',
  'bugün {time}': 'сегодня в {time}',
  'dün {time}': 'вчера в {time}',
  'Kaydı sil': 'Удалить запись',
  '◀ İptal için kaydırın': '◀ Проведите для отмены',
  'Sesli mesaj: dokunun ya da basılı tutun':
      'Голосовое сообщение: нажмите или удерживайте',
  'Galeri': 'Галерея',
  'Açıklama ekle': 'Добавить подпись',
  '{appName} hazır açılır; orada gönderin':
      'Откроется готовым в {appName}; отправьте там',
  'Gönder': 'Отправить',
  'Gönderilemedi': 'Не отправлено',
  'Gönderiliyor': 'Отправляется',
  'Görüldü': 'Прочитано',
  'Gönderildi': 'Отправлено',
  'Burada okumak {appName}\'ta "görüldü" göndermez. Yanıt verirseniz gider.':
      'Чтение здесь не отправляет «прочитано» в {appName}. Оно уйдёт, если вы ответите.',
  'Anladım': 'Понятно',
  'Oynat': 'Воспроизвести',
  'Sesli mesaj indirilemedi.': 'Не удалось загрузить голосовое сообщение.',
  'Duraklat': 'Пауза',
  'Dinle': 'Слушать',
  '{appName}\'ta aç': 'Открыть в {appName}',
  'Yanıt:': 'Ответ:',
  'Yükleniyor %{percent}': 'Загрузка {percent} %',
  'Şu an gönderince {appName} açılıyor. Açarsanız bu sohbetten mesaj geldiğinde yanıtlarınız doğrudan gider.':
      'Сейчас при отправке открывается {appName}. Включите эту функцию, и, когда из этого чата придёт сообщение, ваши ответы будут уходить сразу.',
  'Kapat': 'Закрыть',
  'Hatırlatma': 'Напоминание',
  'Sabitlendi': 'Закреплено',
  'Önemli': 'Важное',
  'Sabitlemeyi kaldır': 'Открепить',
  'Sabitle': 'Закрепить',
  'Sonra hatırlat': 'Напомнить позже',
  'Arşivden çıkar': 'Вернуть из архива',
  'Arşivle': 'В архив',
  'Kişiyle birleştir': 'Объединить с человеком',
  'Aynı kişinin başka uygulamadaki sohbetiyle tek yerde':
      'Чат этого человека в другом приложении — в одном месте',
  '{name} kişisinden ayır': 'Отделить от {name}',
  'Kişi': 'Человек',
  'Ne zaman hatırlatılsın?': 'Когда напомнить?',
  '⏰ {when} hatırlatılacak': '⏰ Напомним {when}',
  '{target}: {name} ve {name2} sohbetleri birleşti':
      '{target}: чаты {name} и {name2} объединены',
  '"{title}" silinsin mi?': 'Удалить «{title}»?',
  'Sohbet ve mesajları yalnızca Mesa\'dan silinir; {name} uygulamasındaki sohbete dokunulmaz.':
      'Чат и его сообщения удаляются только из Mesa; чат в {name} не затрагивается.',
  '{title} ile birleştir': 'Объединить с {title}',
  'Aynı kişinin başka uygulamadaki sohbetini seçin. Mesajlar tek yerde görünür; istediğiniz zaman ayırabilirsiniz.':
      'Выберите чат этого человека в другом приложении. Сообщения будут в одном месте; разделить их можно в любой момент.',
  'Ara': 'Поиск',
  'Adını değiştir': 'Переименовать',
  '{name} sohbetini ayır': 'Отделить чат {name}',
  'Kişinin adı': 'Имя человека',
  '1 saat sonra': 'Через 1 час',
  '3 saat sonra': 'Через 3 часа',
  'Bu akşam': 'Сегодня вечером',
  'Yarın sabah': 'Завтра утром',
  'Tarih ve saat seç': 'Выбрать дату и время',
  'Yanıt bekliyor · {count}': 'Ждут ответа · {count}',
  'Ertelenen sohbetler': 'Отложенные чаты',
  'Şimdi göster': 'Показать сейчас',
  'Sohbetler': 'Чаты',
  'Servisler': 'Сервисы',
  'Kurallar': 'Правила',
  'Ayarlar': 'Настройки',
  'Yanıt gerekmez': 'Ответ не нужен',
  'Yeni mesaj gelene kadar listeden kalkar':
      'Скрыть из списка до нового сообщения',
  'Birleşik bildirimler açık. Yeni mesajlar artık Mesa bildirimiyle gelecek.':
      'Единые уведомления включены. Новые сообщения теперь будут приходить как уведомления Mesa.',
  'Mesajlar': 'Сообщения',
  'Hepsi okundu': 'Всё прочитано',
  '{unreadTotal} okunmamış': 'Непрочитанных: {unreadTotal}',
  'Haftalık özet': 'Итоги недели',
  'Kaydedilenler': 'Сохранённое',
  'Diğer': 'Ещё',
  'Tümünü okundu say': 'Отметить все как прочитанные',
  'Arşiv ({archivedCount})': 'Архив ({archivedCount})',
  'Tümü': 'Все',
  'Ekle': 'Добавить',
  'Servis ekle': 'Добавить сервис',
  '{count} ertelenmiş sohbet':
      '{count, plural, one{# отложенный чат} few{# отложенных чата} many{# отложенных чатов} other{# отложенного чата}}',
  'Zamanı gelince hatırlatılacak': 'Напомним в нужное время',
  '{name} artık tek satırda: {name2} ve {name3} mesajları birlikte.':
      '{name} теперь одной строкой: сообщения из {name2} и {name3} вместе.',
  'Tüm mesajlarda ara': 'Поиск по всем сообщениям',
  'Henüz mesaj yok': 'Сообщений пока нет',
  'WhatsApp, Instagram, Discord gibi uygulamalardan yeni mesaj geldikçe burada toplanır; eski mesajlar görünmez. Telegram\'ı Ayarlar\'dan bağlarsanız geçmişi de gelir.':
      'Новые сообщения из приложений вроде WhatsApp, Instagram и Discord собираются здесь по мере поступления; старые не отображаются. Подключите Telegram в настройках, чтобы получить и его историю.',
  'Bildirimleri birleştir': 'Объединить уведомления',
  'Her uygulamanın ayrı bildirimi yerine tek tip Mesa bildirimleri: kişi fotoğrafı, doğrudan yanıt ve kurallarınla birlikte.':
      'Одно уведомление Mesa вместо отдельных от каждого приложения: с фото контакта, прямым ответом и вашими правилами.',
  'Bildirim servisi çalışmıyor': 'Служба уведомлений не работает',
  'Yeni mesajlar şu an yakalanmıyor. Xiaomi uygulamayı arka planda engelliyor: Otomatik başlatma iznini açın ve uygulama ayarlarında pil tasarrufunu "Kısıtlama yok" yapın. Ardından "Yeniden bağla"ya dokunun.':
      'Новые сообщения сейчас не перехватываются. Xiaomi блокирует приложение в фоне: включите разрешение «Автозапуск» и в настройках приложения установите для экономии заряда «Нет ограничений». Затем нажмите «Переподключить».',
  'Yeni mesajlar şu an yakalanmıyor. Telefon uygulamayı arka planda kapatmış olabilir: uygulama ayarlarında pil kısıtlamasını kaldırın, ardından "Yeniden bağla"ya dokunun.':
      'Новые сообщения сейчас не перехватываются. Возможно, телефон закрыл приложение в фоне: снимите ограничение батареи в настройках приложения, затем нажмите «Переподключить».',
  'Otomatik başlatma': 'Автозапуск',
  'Uygulama ayarları': 'Настройки приложения',
  'Yeniden bağla': 'Переподключить',
  'Aynı kişi mi?': 'Один и тот же человек?',
  'Telefon numaraları aynı. Birleştirirseniz mesajları tek satırda, tek zaman çizgisinde görürsünüz.':
      'Номера телефонов совпадают. Объединив, вы увидите сообщения одной строкой и в одной ленте.',
  'Adları aynı. Birleştirirseniz mesajları tek satırda, tek zaman çizgisinde görürsünüz.':
      'Имена совпадают. Объединив, вы увидите сообщения одной строкой и в одной ленте.',
  'Farklı kişiler': 'Разные люди',
  'Birleştir': 'Объединить',
  'Uygulamanın dili': 'Язык приложения',
  'Telefonun dili': 'Язык телефона',
  'Dil': 'Язык',
  'Telefonun dili ({language})': 'Язык телефона ({language})',
  'Mesa\'yı açmak için kimliğinizi doğrulayın':
      'Подтвердите личность, чтобы открыть Mesa',
  'Mesa kilitli': 'Mesa заблокирован',
  'Kilidi aç': 'Разблокировать',
  'Fotoğraflar': 'Фото',
  'Videolar': 'Видео',
  'Ocak': 'Январь',
  'Şubat': 'Февраль',
  'Mart': 'Март',
  'Nisan': 'Апрель',
  'Mayıs': 'Май',
  'Haziran': 'Июнь',
  'Temmuz': 'Июль',
  'Ağustos': 'Август',
  'Eylül': 'Сентябрь',
  'Ekim': 'Октябрь',
  'Kasım': 'Ноябрь',
  'Aralık': 'Декабрь',
  'Henüz fotoğraf ya da video yok': 'Фото и видео пока нет',
  'Bildiriminde önizlemesi gelen fotoğraflar ve Telegram medyası burada toplanır.':
      'Здесь собираются фото с превью в уведомлениях и медиа из Telegram.',
  'Tam boyut': 'Исходный размер',
  'Medya açılamadı.': 'Не удалось открыть медиафайл.',
  'Görsel açılamadı.': 'Не удалось открыть изображение.',
  'İndiriliyor…': 'Загрузка…',
  'Açılıyor…': 'Открытие…',
  'İndiriliyor… %{percent}': 'Загрузка… {percent} %',
  'Sesi kapat': 'Выключить звук',
  'Sesi aç': 'Включить звук',
  'Tam ekrandan çık': 'Выйти из полноэкранного режима',
  'Tam ekran': 'Во весь экран',
  'Başlangıç saati': 'Время начала',
  'Bitiş saati': 'Время окончания',
  'En az bir gün seçin.': 'Выберите хотя бы один день.',
  'Kural silinsin mi?': 'Удалить правило?',
  '"{name}" kalıcı olarak silinecek.': '«{name}» будет удалено навсегда.',
  'Yeni kural': 'Новое правило',
  'Kuralı düzenle': 'Изменить правило',
  'Kural adı': 'Название правила',
  'Ne yapılsın?': 'Что сделать?',
  'Mesaja, geldiği uygulama üzerinden otomatik cevap verilir.':
      'На сообщение автоматически ответят через приложение, из которого оно пришло.',
  'Mesajlar kaydedilir ama okunmamış sayılmaz.':
      'Сообщения сохраняются, но не считаются непрочитанными.',
  'Sohbet, açılana kadar listenin en üstünde yıldızla durur.':
      'Чат остаётся вверху списка со звездой, пока вы его не откроете.',
  'Yanıt metni': 'Текст ответа',
  'Şu an müsait değilim, sonra yazacağım.':
      'Сейчас не могу говорить, напишу позже.',
  'Otomatik yanıt için bir metin yazın': 'Введите текст автоответа',
  'Aynı sohbete tekrar yanıt için bekle':
      'Пауза перед повторным ответом в тот же чат',
  'Hangi mesajlarda?': 'Для каких сообщений?',
  'Uygulama seçilmedi: tüm uygulamalar':
      'Приложение не выбрано: все приложения',
  'Yalnızca seçilen uygulamalar': 'Только выбранные приложения',
  'Kimden (isteğe bağlı)': 'От кого (необязательно)',
  'Sohbet ya da kişi adında geçen ifade':
      'Текст в названии чата или имени человека',
  'Anahtar kelimeler (isteğe bağlı)': 'Ключевые слова (необязательно)',
  'acil, toplantı, fatura': 'срочно, встреча, счёт',
  'Virgülle ayırın; herhangi biri geçerse kural çalışır':
      'Через запятую; правило сработает, если встретится любое из них',
  'Grup sohbetlerinde de çalışsın': 'Работать и в групповых чатах',
  'Gruptaki herkes otomatik yanıtı görür.':
      'Автоответ увидят все участники группы.',
  'Ne zaman?': 'Когда?',
  'Yalnızca belirli saatlerde': 'Только в определённые часы',
  'Gün boyu': 'Весь день',
  'Başlangıç {from}': 'Начало {from}',
  'Bitiş {to}': 'Конец {to}',
  'Gece yarısını aşar: {from}–{to} (ertesi gün)':
      'После полуночи: {from}–{to} (следующего дня)',
  'Koşul yok: bu kural her yeni mesaja yanıt verir (bekleme süresi ve saatlik sınırla).':
      'Без условий: это правило отвечает на каждое новое сообщение (с паузой и лимитом в час).',
  'Kurallar nasıl çalışır?': 'Как работают правила?',
  'Kurallar uygulama kapalıyken de, yeni mesaj gelir gelmez çalışır.\n\nOtomatik yanıt güvenliği: aynı anda gelen mesajlara tek yanıt; aynı sohbete bekleme süresi dolmadan tekrar yanıt yok; tüm sohbetlerde saatte en fazla 20 yanıt.\n\nYanıt, kaynak uygulamanın bildirimi üzerinden (Telegram\'da doğrudan) gider; bildirim yoksa gönderilmez.':
      'Правила срабатывают сразу при получении нового сообщения, даже когда приложение закрыто.\n\nЗащита автоответов: на сообщения, пришедшие одновременно, — один ответ; повторно в тот же чат до окончания паузы не отвечаем; не больше 20 ответов в час на все чаты.\n\nОтвет уходит через уведомление исходного приложения (в Telegram — напрямую); без уведомления он не отправляется.',
  'Otomatik yanıt, sessize alma, önemli işaretleme':
      'Автоответ, без звука, отметка «важное»',
  '{active} etkin kural':
      '{active, plural, one{# активное правило} few{# активных правила} many{# активных правил} other{# активного правила}}',
  'Kural ekle': 'Добавить правило',
  'Kurallarınız': 'Ваши правила',
  'Son 7 günde {recentFires} kez çalıştı':
      'Сработало {recentFires, plural, one{# раз} few{# раза} many{# раз} other{# раза}} за последние 7 дней',
  'Henüz kural yok': 'Правил пока нет',
  'Yukarıdaki hazır kurallardan birine dokunun ya da kendiniz ekleyin.':
      'Нажмите на одно из готовых правил выше или добавьте своё.',
  'WhatsApp\'ta "acil" geçen mesajları önemli işaretle':
      'Отмечать как важные сообщения WhatsApp со словом «срочно»',
  'İş grubunu sessize al': 'Отключить звук рабочей группы',
  'Gece 23:00–08:00 arası "Sabah yazarım" diye yanıtla':
      'С 23:00 до 08:00 отвечать «Напишу утром»',
  'Gece modu': 'Ночной режим',
  '23:00–08:00 otomatik yanıt': 'Автоответ с 23:00 до 08:00',
  'Gece otomatik yanıt': 'Ночной автоответ',
  'Şu an uyuyorum, sabah dönerim 🌙': 'Я сейчас сплю, отвечу утром 🌙',
  'Meşgulüm': 'Занят(а)',
  'Herkese kısa yanıt': 'Короткий ответ всем',
  'Şu an müsait değilim, birazdan yazarım.':
      'Сейчас не могу говорить, скоро напишу.',
  'Mesai dışı': 'Нерабочее время',
  'Hafta içi 18:00–09:00': 'Будни 18:00–09:00',
  'Mesai dışı yanıt': 'Ответ в нерабочее время',
  'Mesai saatleri dışındayım, yarın dönüş yapacağım.':
      'Сейчас нерабочее время, отвечу завтра.',
  'Acil mesajlar': 'Срочные сообщения',
  '"acil", "hemen" geçenleri öne çıkar':
      'Выделяет сообщения со словами «срочно», «немедленно»',
  'acil': 'срочно',
  'hemen': 'немедленно',
  'önemli': 'важно',
  'ara beni': 'позвони мне',
  'Hazır kurallar': 'Готовые правила',
  'Mesajlarda ara': 'Поиск по сообщениям',
  'Bütün uygulamalardaki mesajlarda arar. En az iki harf yazın.':
      'Ищет по сообщениям во всех приложениях. Введите хотя бы две буквы.',
  'Sonuç bulunamadı.': 'Ничего не найдено.',
  '{name} açılamadı.': 'Не удалось открыть {name}.',
  'Servisler nasıl çalışır?': 'Как работают сервисы?',
  'Her servis kendi resmi web sitesiyle, uygulamanın içindeki tarayıcıda açılır. Giriş bilgileriniz yalnızca bu telefonda kalır; Mesa yalnızca o servisin sunucusuyla konuşur.\n\nArka planda bağlı servisler uygulama kapalıyken de yeni mesajları bildirir ve mesajlar Sohbetler\'e düşer. Bunun için telefonun pil ayarında Mesa\'ya "Kısıtlama yok" verilmelidir. Her açık servis pil ve bellek harcar.\n\nInstagram, X ve LinkedIn gibi bazı siteler açıkken mesaj bildirimi göndermez; onlarda okunmamış sayısı arttığında haber verilir.\n\n"Google ile giriş" bu sayfalarda çalışmaz; e-posta ve şifreyle girin.':
      'Каждый сервис открывается на своём официальном сайте во встроенном браузере приложения. Данные для входа остаются только на этом телефоне; Mesa общается только с сервером этого сервиса.\n\nСервисы, подключённые в фоне, сообщают о новых сообщениях, даже когда приложение закрыто, и сообщения попадают в «Чаты». Для этого в настройках батареи телефона для Mesa нужно выбрать «Нет ограничений». Каждый открытый сервис расходует батарею и память.\n\nНекоторые сайты, например Instagram, X и LinkedIn, не присылают уведомления о сообщениях, пока открыты; для них мы сообщаем, когда растёт число непрочитанных.\n\n«Войти через Google» на этих страницах не работает; входите по электронной почте и паролю.',
  '{unread} okunmamış': 'Непрочитанных: {unread}',
  'Tüm uygulamalar tek yerde': 'Все приложения в одном месте',
  'Uygulamalar': 'Приложения',
  'Web servisleri': 'Веб-сервисы',
  '{name} ayarları': 'Настройки {name}',
  'Okunmamış var': 'Есть непрочитанные',
  'Bildirim kapalı': 'Уведомления выключены',
  'Arka planda bağlı': 'Подключено в фоне',
  'Yalnızca açıkken': 'Только пока открыто',
  'Henüz web servisi yok': 'Веб-сервисов пока нет',
  'Telefonda uygulaması olmayan servisleri resmi web sürümleriyle buraya ekleyin. Yeni mesajlar Sohbetler\'e ve bildirimlere düşer.':
      'Добавьте сюда официальные веб-версии сервисов, у которых нет приложения на этом телефоне. Новые сообщения попадают в «Чаты» и уведомления.',
  'Başka bir site': 'Другой сайт',
  'Adresini yazarak, ör. vk.com/im': 'По адресу, например vk.com/im',
  'KakaoTalk, Viber, LINE ve Signal\'in web sürümü yok. Uygulamaları telefona kurulursa mesajları bildirimlerden otomatik toplanır.':
      'У KakaoTalk, Viber, LINE и Signal нет веб-версии. Если их приложения установлены на телефоне, сообщения собираются из уведомлений автоматически.',
  'Ekli · ikinci hesap eklenir': 'Добавлено · добавится второй аккаунт',
  'Uygulaması kurulu, bildirimleri zaten geliyor':
      'Приложение установлено, его уведомления уже приходят',
  'https ile açılan geçerli bir site adresi yazın.':
      'Введите корректный адрес сайта, начинающийся с https.',
  'Ad': 'Название',
  'Adres': 'Адрес',
  '{name} oturumu kapatılsın mı?': 'Выйти из {name}?',
  'Bu servisin giriş bilgileri ve site verileri telefondan silinir. Yeniden giriş yapmanız gerekir.':
      'Данные для входа и данные сайта этого сервиса будут удалены с телефона. Нужно будет войти заново.',
  'Oturumu kapat': 'Выйти',
  '{name} kaldırılsın mı?': 'Удалить {name}?',
  'Oturum ve site verileri telefondan silinir. Sohbetler\'deki eski mesajlar kalır.':
      'Сеанс и данные сайта будут удалены с телефона. Старые сообщения в «Чатах» останутся.',
  'Kaldır': 'Удалить',
  'Arka planda bağlı kalsın': 'Оставаться подключённым в фоне',
  'Uygulama kapalıyken de yeni mesajlar bildirilir; pil kullanımı artar':
      'О новых сообщениях сообщается, даже когда приложение закрыто; расход батареи выше',
  'Bildirimler': 'Уведомления',
  'Yeni mesajlar Sohbetler\'e ve bildirimlere':
      'Новые сообщения в «Чаты» и уведомления',
  'Videolar kendiliğinden oynasın': 'Автовоспроизведение видео',
  'Kapalıyken videolar dokununca oynar; sayfa daha akıcı olur':
      'Если выключено, видео воспроизводится по нажатию; страница работает плавнее',
  'Eski mesajlar silinsin mi?': 'Удалить старые сообщения?',
  '{days} öncesine ait mesajlar ve görselleri Mesa\'dan kalıcı olarak silinecek. Kaynak uygulamalardaki mesajlara dokunulmaz.':
      'Сообщения и изображения старше {days} будут навсегда удалены из Mesa. Сообщения в исходных приложениях не затрагиваются.',
  'Seçilen uygulamalarda yanıt, Mesa yeniden başlasa da doğrudan gider':
      'В выбранных приложениях ответы уходят напрямую, даже если Mesa перезапустится',
  'Kendi bildirimi de kalsın': 'Сохранять и собственное уведомление',
  'Seçtiğiniz uygulamanın bildirimi çubuktan kaldırılmaz. Bildirim orada durdukça, Mesa yeniden başlasa da (güncelleme, telefonun yeniden açılması) o sohbete yanıt ve planlı mesaj uygulamaya geçmeden gider. Aynı mesaj için iki bildirim görürsünüz; Mesa\'nınki sessiz gelir.':
      'Уведомление выбранного приложения не убирается из строки состояния. Пока оно там, ответы и запланированные сообщения в этот чат уходят напрямую, без открытия приложения, даже если Mesa перезапустится (обновление, перезагрузка телефона). Вы увидите два уведомления об одном сообщении; уведомление Mesa приходит без звука.',
  'Ana ekranda boş bir yere basılı tutun → Bileşenler (Widget) → Mesa\'yı sürükleyip bırakın.':
      'Удерживайте пустое место на главном экране → Виджеты → перетащите Mesa.',
  'Birleşik bildirimler': 'Единые уведомления',
  'Uygulamaların ayrı bildirimleri yerine kişi fotoğraflı, yanıtlanabilen tek tip bildirim':
      'Единое уведомление с фото контакта, на которое можно ответить, вместо отдельных уведомлений каждого приложения',
  'Önemli mesajlarda bildirim': 'Уведомлять о важных сообщениях',
  '"Önemli işaretle" kuralına uyunca, sessizdekiler dahil':
      'Когда срабатывает правило «Отметить как важное», включая беззвучные чаты',
  'Ana ekran': 'Главный экран',
  'Ana ekran bileşeni': 'Виджет на главном экране',
  'Okunmamışlar ve yanıt bekleyenler, uygulamayı açmadan':
      'Непрочитанные и ожидающие ответа — без открытия приложения',
  'Bağlantılar': 'Подключения',
  'Doğrudan bağlantı: sessiz gruplar ve geçmiş':
      'Прямое подключение: беззвучные группы и история',
  'Telegram\'da gizli okuma': 'Скрытое чтение в Telegram',
  'Okuduğunuzda "görüldü", yazarken "yazıyor" gitmez':
      'Без «прочитано» при чтении и без «печатает» при наборе',
  'Telegram kanallarını gösterme': 'Скрывать каналы Telegram',
  'Kişiler ve gruplar gelmeye devam eder': 'Люди и группы продолжают приходить',
  'Okunan uygulamalar': 'Отслеживаемые приложения',
  'Gizlilik': 'Конфиденциальность',
  'Görmeden okuma': 'Читать незаметно',
  'WhatsApp, Instagram ve diğerlerinde mesajı burada okumak karşı tarafa "görüldü" göndermez. Yanıt verirseniz gider.':
      'Чтение здесь сообщения из WhatsApp, Instagram и других не отправляет отправителю «прочитано». Оно уйдёт, если вы ответите.',
  'Silinen mesajlar korunur': 'Удалённые сообщения сохраняются',
  'Gönderen mesajı silse de metni burada "silindi" etiketiyle kalır.':
      'Даже если отправитель удалит сообщение, его текст останется здесь с пометкой «удалено».',
  'Mesajları sakla': 'Хранить сообщения',
  '{retentionDays} sonra silinir': 'Удаляются через {retentionDays}',
  'Yazma': 'Набор текста',
  '{count} yanıt':
      '{count, plural, one{# ответ} few{# ответа} many{# ответов} other{# ответа}}',
  'Telefonda ekran kilidi ya da parmak izi tanımlı değil.':
      'На этом телефоне не настроены блокировка экрана или отпечаток пальца.',
  'Uygulama kilidini açmak için doğrulayın':
      'Подтвердите, чтобы включить блокировку приложения',
  'Uygulama kilidi': 'Блокировка приложения',
  'Parmak izi, yüz tanıma ya da ekran kilidi':
      'Отпечаток пальца, распознавание лица или блокировка экрана',
  'Yeni hazır yanıt': 'Новый быстрый ответ',
  'Hazır yanıt yok.': 'Быстрых ответов нет.',
  'Düzelt': 'Исправить',
  'Sistem durumu · her şey hazır': 'Состояние системы · всё готово',
  'Sistem durumu · {problems} ayar eksik':
      'Состояние системы · {problems, plural, one{не хватает # настройки} few{не хватает # настроек} many{не хватает # настроек} other{не хватает # настройки}}',
  'Bildirim erişimi': 'Доступ к уведомлениям',
  'Mesajlar yakalanıyor': 'Сообщения перехватываются',
  'İzin var ama sistem servisi bağlamadı':
      'Разрешение есть, но система не подключила службу',
  'Mesajları okumak için gerekli': 'Нужен, чтобы читать сообщения',
  'Bağla': 'Подключить',
  'İzin ver': 'Разрешить',
  'Bildirim izni': 'Разрешение на уведомления',
  'Yeni mesajlar bildirilir': 'О новых сообщениях приходят уведомления',
  'Kapalıysa yeni mesaj bildirimi görmezsiniz':
      'Если выключено, вы не увидите уведомлений о новых сообщениях',
  'Pil kısıtlaması yok': 'Без ограничений батареи',
  'Arka planda kapatılmaz': 'Не закрывается в фоне',
  'Telefon uygulamayı arka planda kapatıp mesajları geciktirebilir':
      'Телефон может закрыть приложение в фоне и задерживать сообщения',
  'Otomatik başlatma (Xiaomi)': 'Автозапуск (Xiaomi)',
  'Açık olmalı; telefon yeniden başlayınca da çalışsın':
      'Должен быть включён, чтобы работать и после перезагрузки телефона',
  'Kontrol et': 'Проверить',
  'Mikrofon': 'Микрофон',
  'Sesli mesaj kaydedilebilir': 'Можно записывать голосовые сообщения',
  'Yalnızca sesli mesaj için; ilk kayıtta sorulur':
      'Только для голосовых сообщений; запрашивается при первой записи',
  'Tüm mesajlar tek tip, buradan yanıtlanabilen bildirimle':
      'Все сообщения в едином уведомлении, на которое можно ответить отсюда',
  'Kapalıysa yeni mesajları fark etmezsiniz':
      'Если выключено, вы не заметите новых сообщений',
  'Pil kısıtlamasını kaldır': 'Снять ограничение батареи',
  'Arka planda kapatılmasın, mesajlar gecikmesin':
      'Чтобы приложение не закрывалось в фоне, а сообщения не задерживались',
  'Telefon yeniden açılınca da çalışsın':
      'Чтобы работало и после перезагрузки телефона',
  'Son uygulamalarda kilitle': 'Закрепить в недавних приложениях',
  'Son uygulamalarda karta basılı tutup kilide dokunun; kilitsizken kaydırınca kapanıyor':
      'В недавних приложениях удерживайте карточку и нажмите на замок; без него смахивание закрывает приложение',
  'Yaptım': 'Готово',
  'WhatsApp\'a geçmeden yanıt': 'Отвечать, не переходя в WhatsApp',
  'Uygulama yeniden başlasa da yanıtlar doğrudan gitsin':
      'Ответы уходят напрямую, даже если приложение перезапустится',
  'Kurulumu tamamla · {done}/{count}': 'Завершите настройку · {done}/{count}',
  'Mesajlar eksiksiz ve gecikmeden gelsin':
      'Чтобы сообщения приходили полностью и без задержек',
  'Sonra': 'Позже',
  'Telegram\'ı bağla · isteğe bağlı': 'Подключить Telegram · по желанию',
  'Sessiz gruplar ve geçmiş de gelsin':
      'Получать и беззвучные группы, и историю',
  'Daha az göster': 'Свернуть',
  '{pending} adım daha':
      '{pending, plural, one{остался # шаг} few{осталось # шага} many{осталось # шагов} other{осталось # шага}}',
  'İsteğe bağlı adımlar': 'Необязательные шаги',
  'Henüz kaydedilen mesaj yok': 'Сохранённых сообщений пока нет',
  'Bir mesaja basılı tutup "Kaydet"e dokunun. Adres, kod, tarih gibi önemli mesajlar hangi uygulamadan gelirse gelsin burada toplanır.':
      'Удерживайте сообщение и нажмите «Сохранить». Важные сообщения — адреса, коды, даты — собираются здесь, из какого бы приложения они ни пришли.',
  'Fotoğraflar ve profil resimleri': 'Фото и фото профилей',
  'Telegram önbelleği': 'Кеш Telegram',
  'Geçici dosyalar': 'Временные файлы',
  'Önbellek temizlensin mi?': 'Очистить кеш?',
  'Telegram\'da 7 gündür açılmamış fotoğraf ve videolar, web servislerinin önbelleği ve geçici dosyalar silinir. Mesajlar, kişiler ve oturumlar silinmez; Telegram medyası açınca yeniden iner.':
      'Удаляются фото и видео Telegram, которые не открывались 7 дней, кеш веб-сервисов и временные файлы. Сообщения, люди и сеансы не удаляются; медиа Telegram загрузятся снова при открытии.',
  'Temizle': 'Очистить',
  '{freed} yer açıldı.': 'Освобождено: {freed}.',
  'Temizlenecek önbellek yoktu.': 'Очищать было нечего.',
  'Eski mesajları silmek için: saklama süresi.':
      'Чтобы удалять старые сообщения: срок хранения.',
  'Önbelleği temizle': 'Очистить кеш',
  'Günlere göre': 'По дням',
  'En çok yazıştıkların': 'С кем вы переписываетесь чаще всего',
  '{count} mesaj · {name}':
      '{count, plural, one{# сообщение} few{# сообщения} many{# сообщений} other{# сообщения}} · {name}',
  'Son 7 gün': 'Последние 7 дней',
  '{total} mesaj':
      '{total, plural, one{# сообщение} few{# сообщения} many{# сообщений} other{# сообщения}}',
  '{incoming} gelen': '{incoming} входящих',
  '{outgoing} giden': '{outgoing} исходящих',
  '{people} kişi':
      '{people, plural, one{# человек} few{# человека} many{# человек} other{# человека}}',
  '%{percent}': '{percent} %',
  'En yoğun saatin {hour}:00': 'Ваш самый активный час — {hour}:00',
  'Gelen her 10 mesaja {ratio} yanıt':
      '{ratio} ответа на каждые 10 полученных сообщений',
  'Gönderenin silip sende kalan {deleted} mesaj':
      '{deleted, plural, one{# сообщение удалено отправителем, но осталось у вас} few{# сообщения удалены отправителем, но остались у вас} many{# сообщений удалены отправителем, но остались у вас} other{# сообщения удалены отправителем, но остались у вас}}',
  'Bilgiler': 'Факты',
  'Çıkartmalar': 'Стикеры',
  'Bu bölümde çıkartma yok.': 'В этом разделе нет стикеров.',
  'GIF ara (boşsa kaydedilenler)': 'Поиск GIF (пусто — сохранённые)',
  'Kaydedilmiş GIF yok. Yukarıdan arayabilirsiniz.':
      'Сохранённых GIF нет. Можно поискать выше.',
  'GIF bulunamadı.': 'GIF не найдены.',
  'Telegram bağlantısı kapatılsın mı?': 'Отключить Telegram?',
  'Bu cihazın oturumu Telegram\'dan çıkarılır. Daha önce alınan mesajlar Mesa\'da kalır.':
      'Сеанс этого устройства будет удалён из Telegram. Полученные ранее сообщения останутся в Mesa.',
  'Çıkış yap': 'Выйти',
  'Telegram bağlantısı': 'Подключение к Telegram',
  'Bu derlemede Telegram uygulama kimliği yok. my.telegram.org → "API development tools" bölümünden api_id ve api_hash alınıp android/local.properties dosyasına telegram.apiId ve telegram.apiHash olarak yazılmalı, ardından uygulama yeniden derlenmeli.':
      'В этой сборке нет ID приложения Telegram. Получите api_id и api_hash на my.telegram.org → «API development tools», впишите их в android/local.properties как telegram.apiId и telegram.apiHash и пересоберите приложение.',
  '+90 5xx xxx xx xx': '+7 9xx xxx-xx-xx',
  'Devam': 'Продолжить',
  'Telegram hesabınız bağlı. Sessizdeki gruplar dahil yeni mesajlar gelen kutusuna düşer. Bir sohbeti açınca son mesajları da indirilir.':
      'Ваш аккаунт Telegram подключён. Новые сообщения, в том числе из беззвучных групп, приходят во входящие. При открытии чата загружаются и его последние сообщения.',
  'Bu giriş adımı desteklenmiyor.': 'Этот шаг входа не поддерживается.',
  'Telegram hesabınızı bağlayın': 'Подключите аккаунт Telegram',
  'Mesa, Telegram\'ın resmi kütüphanesiyle hesabınıza doğrudan bağlanır. Böylece bildirim üretmeyen sessiz grupların mesajları da gelir.':
      'Mesa подключается к вашему аккаунту напрямую через официальную библиотеку Telegram, поэтому приходят и сообщения беззвучных групп, которые не создают уведомлений.',
  'Telegram\'a bağlan': 'Подключиться к Telegram',
  'Çıkış yapılıyor…': 'Выход…',
  'Telegram\'a bağlanılıyor…': 'Подключение к Telegram…',
  'Telefon numaranız': 'Ваш номер телефона',
  'Doğrulama kodu': 'Код подтверждения',
  'E-posta kodu': 'Код из письма',
  'İki adımlı doğrulama şifresi': 'Пароль двухэтапной проверки',
  'Telefon numarası (ülke koduyla)': 'Номер телефона (с кодом страны)',
  'Kod': 'Код',
  '• Bağlantı yalnızca Telegram sunucularına gider; mesajlar yalnızca bu telefonda saklanır.\n• Okundu bilgisi gönderilmez, çevrimiçi görünmezsiniz.\n• Bu cihaz Telegram\'da "Etkin oturumlar" listesinde görünür.\n• Bağlıyken bildirim çubuğunda sessiz bir "Telegram\'a bağlı" bildirimi durur.':
      '• Подключение идёт только к серверам Telegram; сообщения хранятся только на этом телефоне.\n• Отметки о прочтении не отправляются, и вы не отображаетесь в сети.\n• Это устройство видно в Telegram в списке «Активные сеансы».\n• Пока подключение активно, в строке состояния висит беззвучное уведомление «Подключено к Telegram».',
  'Bir sohbete basılı tutun: sabitleyin, sonraya erteleyin ya da aynı kişinin başka uygulamadaki sohbetiyle birleştirin.':
      'Удерживайте чат: закрепите его, отложите или объедините с чатом того же человека в другом приложении.',
  'Gönder düğmesine basılı tutun: mesajı istediğiniz saate planlayın.':
      'Удерживайте кнопку отправки: запланируйте сообщение на любое время.',
  'Bir mesaja basılı tutup "Kaydet": tüm uygulamalardan kaydettikleriniz üstteki 🔖 listesinde.':
      'Удерживайте сообщение и нажмите «Сохранить»: всё сохранённое из всех приложений — в списке 🔖 вверху.',
  'Sohbetin üstündeki galeri düğmesi: o kişiyle paylaşılan tüm fotoğraf ve videolar tek yerde.':
      'Кнопка галереи вверху чата: все фото и видео, которыми вы обменивались с этим человеком, в одном месте.',
  'Bildirimden yazmadan yanıtlayın: hazır yanıtlarınız bildirimin altında tek dokunuşla. Listeyi Ayarlar → Hazır yanıtlar\'dan değiştirin.':
      'Отвечайте из уведомления без набора текста: быстрые ответы — в одно касание под уведомлением. Список меняется в Настройки → Быстрые ответы.',
  'Ana ekran bileşeni: okunmamışlar ve yanıt bekleyenler uygulamayı açmadan. Ayarlar → Ana ekran → Ekle.':
      'Виджет на главном экране: непрочитанные и ожидающие ответа без открытия приложения. Настройки → Главный экран → Добавить.',
  'Haftalık özet: kimlerle en çok yazıştığınızı üstteki grafik düğmesinden görün.':
      'Итоги недели: с кем вы переписываетесь чаще всего — по кнопке с графиком вверху.',
  'Günün ipucu': 'Совет дня',
  'Tüm mesajların tek yerde': 'Все сообщения в одном месте',
  'WhatsApp, Telegram, Instagram, Discord ve diğerleri tek gelen kutusunda; uygulamalar arasında gidip gelmeden.':
      'WhatsApp, Telegram, Instagram, Discord и другие в одних входящих — без переходов между приложениями.',
  'Bir kişi, tek sohbet': 'Один человек — один чат',
  'Aynı kişiyle WhatsApp\'tan, Instagram\'dan, Telegram\'dan yazıştıklarınız tek zaman çizgisinde; yanıtı istediğiniz uygulamadan verin.':
      'Переписка с одним человеком в WhatsApp, Instagram и Telegram в одной ленте; отвечайте из любого приложения.',
  'Görüldü göndermeden oku': 'Читать, не отправляя «прочитано»',
  'WhatsApp ve Instagram mesajlarını burada okumak karşı tarafa "görüldü" göndermez; Telegram\'da da isteğe bağlı.':
      'Чтение здесь сообщений WhatsApp и Instagram не отправляет «прочитано»; в Telegram — по желанию.',
  'Silinen mesajın yazısı kalır': 'Текст удалённых сообщений остаётся',
  'Gönderen "herkesten sil" dese de yazdığı metin burada "silindi" etiketiyle durur.':
      'Даже если отправитель выберет «Удалить у всех», написанное останется здесь с пометкой «удалено».',
  'Yanıt bekleyenler en üstte; sohbeti sonraya ertele, mesajı istediğin saate planla.':
      'Ожидающие ответа — вверху; отложите чат, запланируйте сообщение на любое время.',
  'Telefonunda kalır': 'Остаётся на вашем телефоне',
  'Mesajlar yalnızca bu telefonda saklanır; hiçbir sunucuya gönderilmez.':
      'Сообщения хранятся только на этом телефоне и никуда не отправляются.',
  'Bildirim erişimini aç': 'Включить доступ к уведомлениям',
  'Mesa mesajları uygulamaların bildirimlerinden okur. Açılan listede Mesa\'yı bulup izin verin.':
      'Mesa читает сообщения из уведомлений приложений. Найдите Mesa в открывшемся списке и разрешите доступ.',
  'İzin verilemiyor mu?': 'Не получается включить?',
  'Android, mağaza dışından kurulan uygulamalarda bu izni kısıtlar. Mesa\'nın anahtarına bir kez dokunun, sonra Uygulama bilgileri → ⋮ → Kısıtlanmış ayarlara izin ver\'i seçip tekrar deneyin.':
      'Android ограничивает это разрешение для приложений, установленных не из магазина. Нажмите один раз на переключатель Mesa, затем откройте «О приложении» → ⋮ → «Разрешить доступ к ограниченным настройкам» и попробуйте снова.',
  'Uygulama bilgileri': 'О приложении',
};
