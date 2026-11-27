// Türkçe metin → çeviri. Anahtarlar test/l10n_test.dart ile denetlenir
// (yeni metin: tr() ekleyin, buraya ve diğer dillere çevirisini yazın).
const pt = <String, String>{
  'Pazartesi': 'Segunda-feira',
  'Salı': 'Terça-feira',
  'Çarşamba': 'Quarta-feira',
  'Perşembe': 'Quinta-feira',
  'Cuma': 'Sexta-feira',
  'Cumartesi': 'Sábado',
  'Pazar': 'Domingo',
  'Bugün': 'Hoje',
  'Dün': 'Ontem',
  '{day} Ocak': '{day} de janeiro',
  '{day} Şubat': '{day} de fevereiro',
  '{day} Mart': '{day} de março',
  '{day} Nisan': '{day} de abril',
  '{day} Mayıs': '{day} de maio',
  '{day} Haziran': '{day} de junho',
  '{day} Temmuz': '{day} de julho',
  '{day} Ağustos': '{day} de agosto',
  '{day} Eylül': '{day} de setembro',
  '{day} Ekim': '{day} de outubro',
  '{day} Kasım': '{day} de novembro',
  '{day} Aralık': '{day} de dezembro',
  '{day}.{month}.{year}': '{day}/{month}/{year}',
  'bugün {clock}': 'hoje {clock}',
  'yarın {clock}': 'amanhã {clock}',
  'şimdi': 'agora',
  '{n} dk': '{n} min',
  '{n} sa': '{n} h',
  '{n} g': '{n} d',
  'B': 'B',
  'KB': 'KB',
  'MB': 'MB',
  'GB': 'GB',
  'Çıkartma': 'Figurinha',
  '📷 Fotoğraf': '📷 Foto',
  'Otomatik yanıt': 'Resposta automática',
  'Sessize al': 'Silenciar',
  'Önemli işaretle': 'Marcar como importante',
  '15 dakika': '15 minutos',
  '1 saat': '1 hora',
  '6 saat': '6 horas',
  '1 gün': '1 dia',
  'Pzt': 'Seg',
  'Sal': 'Ter',
  'Çar': 'Qua',
  'Per': 'Qui',
  'Cum': 'Sex',
  'Cmt': 'Sáb',
  'Paz': 'Dom',
  'hafta içi': 'dias úteis',
  'hafta sonu': 'fins de semana',
  'Tüm uygulamalar': 'Todos os apps',
  'Kimden: "{sender}"': 'De: "{sender}"',
  'İçerik: {words}': 'Contém: {words}',
  'gruplar dahil': 'grupos incluídos',
  'Süresiz': 'Para sempre',
  '7 gün': '7 dias',
  '30 gün': '30 dias',
  '90 gün': '90 dias',
  '1 yıl': '1 ano',
  'Tamam 👍': 'Ok 👍',
  'Şu an müsait değilim, sonra yazarım.':
      'Não posso falar agora, escrevo depois.',
  'Yoldayım, birazdan oradayım.': 'Estou a caminho, chego logo.',
  'Teşekkürler!': 'Obrigado!',
  '{step} bir giriş adımı değil': '{step} não é uma etapa de login',
  '🎥 Video': '🎥 Vídeo',
  '🎵 Ses dosyası': '🎵 Arquivo de áudio',
  '🎤 Sesli mesaj': '🎤 Mensagem de voz',
  '🎤 Ses': '🎤 Áudio',
  '⏺ Görüntülü mesaj': '⏺ Mensagem de vídeo',
  '📍 Konum': '📍 Localização',
  '📄 Dosya': '📄 Arquivo',
  '👤 Kişi': '👤 Contato',
  '📊 Anket': '📊 Enquete',
  'Arşiv': 'Arquivadas',
  'Arşivde sohbet yok.\nGelen kutusunda bir sohbete uzun basıp "Arşivle"yi seçebilirsiniz.':
      'Nenhuma conversa arquivada.\nToque e segure uma conversa na caixa de entrada e escolha "Arquivar".',
  'Yedekleniyor… Fotoğraflar çoksa biraz sürebilir.':
      'Fazendo backup… Pode demorar um pouco se houver muitas fotos.',
  'Yedek kaydedildi: {messages} mesaj, {files} fotoğraf ({bytes}).':
      'Backup salvo: {messages, plural, one{# mensagem} other{# mensagens}}, {files, plural, one{# foto} other{# fotos}} ({bytes}).',
  'Yedek alınamadı: {error}': 'Não foi possível fazer o backup: {error}',
  'bilinmeyen hata': 'erro desconhecido',
  'Yedekten geri yüklensin mi?': 'Restaurar do backup?',
  'Bu telefondaki Mesa mesajları, kişileri ve kuralları yedektekilerle değiştirilir. Telegram ve web servisi girişleri yedekte yoktur; gerekirse yeniden giriş yaparsınız.':
      'As mensagens, pessoas e regras do Mesa neste celular serão substituídas pelas do backup. Os logins do Telegram e dos serviços web não estão no backup; entre de novo se precisar.',
  'Vazgeç': 'Cancelar',
  'Dosya seç': 'Escolher arquivo',
  'Geri yükleniyor…': 'Restaurando…',
  'Geri yüklendi: {messages} mesaj, {files} fotoğraf.':
      'Restaurado: {messages, plural, one{# mensagem} other{# mensagens}}, {files, plural, one{# foto} other{# fotos}}.',
  'Şifre yanlış. Yedeği alırken girdiğiniz şifreyi deneyin.':
      'Senha incorreta. Tente a senha que você usou ao fazer o backup.',
  'Dosya açılamadı: {error}': 'Não foi possível abrir o arquivo: {error}',
  'yedek bozuk': 'o backup está corrompido',
  'Geri yüklenemedi: {error}': 'Não foi possível restaurar: {error}',
  'Yedek': 'Backup',
  'Yedekle': 'Fazer backup',
  'Mesajlar, kişiler, kurallar ve fotoğraflar; şifreli dosya. Henüz yedek alınmadı.':
      'Mensagens, pessoas, regras e fotos; arquivo criptografado. Nenhum backup ainda.',
  'Mesajlar, kişiler, kurallar ve fotoğraflar; şifreli dosya. Son yedek: {when}':
      'Mensagens, pessoas, regras e fotos; arquivo criptografado. Último backup: {when}',
  'Yedekten geri yükle': 'Restaurar do backup',
  'Yeni telefonda ya da sıfırlamadan sonra':
      'Em um celular novo ou depois de uma redefinição',
  'En az 8 karakter olmalı.': 'Deve ter pelo menos 8 caracteres.',
  'Şifreler aynı değil.': 'As senhas não coincidem.',
  'Yedek şifresi': 'Senha do backup',
  'Yedeğin şifresi': 'Senha do backup',
  'Bu şifreyi unutursanız yedek açılamaz; kimse kurtaramaz. Bir yere not edin.':
      'Se você esquecer esta senha, o backup não poderá ser aberto; ninguém consegue recuperá-lo. Anote-a em algum lugar.',
  'Şifre': 'Senha',
  'Göster': 'Mostrar',
  'Gizle': 'Ocultar',
  'Şifre (tekrar)': 'Senha (de novo)',
  'Aç': 'Abrir',
  'Açıldı. Bu sohbetten yeni mesaj gelince yanıtlarınız {appName} açılmadan, doğrudan gider.':
      'Ativado. Quando chegar uma nova mensagem nesta conversa, suas respostas irão direto, sem abrir o {appName}.',
  'Mesajınız bu sohbete de kaydedildi.':
      'Sua mensagem também foi salva nesta conversa.',
  'Gönderilmedi': 'Não enviada',
  'Tekrar gönder': 'Enviar de novo',
  'Mesaj gönderilemedi': 'Não foi possível enviar a mensagem',
  'Sil': 'Excluir',
  'Karşı tarafa hiç gitmedi': 'Nunca chegou à outra pessoa',
  'Kaydedilenlerden çıkar': 'Remover dos salvos',
  'Kaydet': 'Salvar',
  'Tüm uygulamalardan kaydedilenler tek listede':
      'Mensagens salvas de todos os apps em uma lista',
  'Kopyala': 'Copiar',
  'Kaydedilenlerden çıkarıldı.': 'Removida dos salvos.',
  'Kaydedildi ⭐': 'Salva ⭐',
  'Kopyalandı.': 'Copiado.',
  'Yeniden gönderiliyor…': 'Reenviando…',
  'Gönderilemedi. Bağlantıyı kontrol edin.':
      'Não foi possível enviar. Verifique a conexão.',
  'Ne zaman gönderilsin?': 'Quando enviar?',
  '⏰ {when} Telegram\'dan gönderilecek.':
      '⏰ Será enviada pelo Telegram {when}.',
  '⏰ {when} kendiliğinden gönderilecek.':
      '⏰ Será enviada automaticamente {when}.',
  '⏰ {when} bildirim gelecek: dokununca {appName} mesaj yazılmış olarak açılır, ➤ ile gönderirsiniz. {viaAppNote}':
      '⏰ Você vai receber uma notificação {when}: ao tocar, o {appName} abre com a mensagem escrita e você envia com ➤. {viaAppNote}',
  'O zamana kadar bu sohbetten yeni mesaj gelirse kendiliğinden gider.':
      'Se chegar uma nova mensagem nesta conversa antes disso, ela será enviada automaticamente.',
  'Planlı mesajlar': 'Mensagens agendadas',
  'İptal et': 'Cancelar envio',
  '{appName} bu sohbet için şu an doğrudan gönderme yolu vermiyor: zamanı gelince bildirime dokunup {appName} içinde gönderirsiniz. {viaAppNote}':
      'O {appName} não oferece agora um jeito de enviar direto para esta conversa: na hora certa, toque na notificação e envie pelo {appName}. {viaAppNote}',
  'Telegram bağlantısı açık değil.':
      'A conexão com o Telegram não está aberta.',
  '{appName} açılamadı.': 'Não foi possível abrir o {appName}.',
  'Gönderiliyor…': 'Enviando…',
  '{kind} gönderiliyor…': 'Enviando {kind}…',
  '{appName} açıldı; göndermek için orada ➤ düğmesine dokunun.':
      'O {appName} abriu; toque no botão ➤ de lá para enviar.',
  '{appName} dışarıdan {kind} kabul etmiyor.':
      'O {appName} não aceita {kind} de outros apps.',
  'Gönderilemedi.': 'Não foi possível enviar.',
  'Fotoğraf': 'Foto',
  'Video': 'Vídeo',
  'Sesli mesaj': 'Mensagem de voz',
  'Dosya': 'Arquivo',
  'Planlı mesaj': 'Mensagem agendada',
  'Zaman seç': 'Escolher horário',
  'Gönderilecek mesaj': 'Mensagem a enviar',
  'Sesli mesaj için mikrofon izni gerekli.':
      'É preciso permissão de microfone para mensagens de voz.',
  'Kayıt başlatılamadı.': 'Não foi possível começar a gravar.',
  'Kayıt çok kısa.': 'A gravação é curta demais.',
  'Uygulama açılamadı.': 'Não foi possível abrir o app.',
  'Siz': 'Você',
  'Hazır yanıtlar': 'Respostas rápidas',
  'Gizli okuma açık: Telegram\'da "görüldü" ve "yazıyor" gitmez.':
      'Leitura oculta ativada: o Telegram não envia "visto" nem "digitando".',
  'Burada okumak {name}\'ta "görüldü" göndermez. Yanıt verirseniz gider.':
      'Ler aqui não envia "visto" no {name}. É enviado se você responder.',
  'Görüldü gönderilmez': '"Visto" não é enviado',
  'Medya': 'Mídia',
  '{name} uygulamasında aç': 'Abrir no {name}',
  'Bu sohbette henüz mesaj yok.': 'Ainda não há mensagens nesta conversa.',
  '{count} planlı mesaj · ilki {when}':
      '{count, plural, one{# mensagem agendada} other{# mensagens agendadas}} · a primeira {when}',
  'Mesajınız {name}\'ta hazır açılır; orada ➤ ile gönderin.':
      'Sua mensagem abre pronta no {name}; envie por lá com ➤.',
  'Klavye': 'Teclado',
  'Emoji': 'Emoji',
  '{appName} ile yaz': 'Escrever no {appName}',
  'Mesaj yaz': 'Escreva uma mensagem',
  'Çıkartma ve GIF': 'Figurinhas e GIFs',
  'Fotoğraf, video, dosya': 'Foto, vídeo, arquivo',
  'Zamanla': 'Agendar',
  'Kamera': 'Câmera',
  'Sesli mesajı gönder': 'Enviar mensagem de voz',
  'Gönder (basılı tutun: zamanla)': 'Enviar (segure para agendar)',
  'Web servislerine yanıt, servisin kendi sayfasından yazılır.':
      'Respostas para serviços web são escritas na própria página do serviço.',
  '{name} telefonda kurulu değil.':
      'O {name} não está instalado neste celular.',
  '{name} sayfasında yanıtla': 'Responder na página do {name}',
  'çevrimiçi': 'online',
  'son görülme {seen}': 'visto por último {seen}',
  'bugün {time}': 'hoje às {time}',
  'dün {time}': 'ontem às {time}',
  'Kaydı sil': 'Apagar gravação',
  '◀ İptal için kaydırın': '◀ Deslize para cancelar',
  'Sesli mesaj: dokunun ya da basılı tutun': 'Mensagem de voz: toque ou segure',
  'Galeri': 'Galeria',
  'Açıklama ekle': 'Adicionar legenda',
  '{appName} hazır açılır; orada gönderin':
      'Abre pronta no {appName}; envie por lá',
  'Gönder': 'Enviar',
  'Gönderilemedi': 'Não enviada',
  'Gönderiliyor': 'Enviando',
  'Görüldü': 'Vista',
  'Gönderildi': 'Enviada',
  'Burada okumak {appName}\'ta "görüldü" göndermez. Yanıt verirseniz gider.':
      'Ler aqui não envia "visto" no {appName}. É enviado se você responder.',
  'Anladım': 'Entendi',
  'Oynat': 'Reproduzir',
  'Sesli mesaj indirilemedi.': 'Não foi possível baixar a mensagem de voz.',
  'Duraklat': 'Pausar',
  'Dinle': 'Ouvir',
  '{appName}\'ta aç': 'Abrir no {appName}',
  'Yanıt:': 'Resposta:',
  'Yükleniyor %{percent}': 'Enviando {percent}%',
  'Şu an gönderince {appName} açılıyor. Açarsanız bu sohbetten mesaj geldiğinde yanıtlarınız doğrudan gider.':
      'Agora, ao enviar, o {appName} é aberto. Ative isto e, quando chegar uma mensagem desta conversa, suas respostas irão direto.',
  'Kapat': 'Fechar',
  'Hatırlatma': 'Lembrete',
  'Sabitlendi': 'Fixada',
  'Önemli': 'Importante',
  'Sabitlemeyi kaldır': 'Desafixar',
  'Sabitle': 'Fixar',
  'Sonra hatırlat': 'Lembrar mais tarde',
  'Arşivden çıkar': 'Desarquivar',
  'Arşivle': 'Arquivar',
  'Kişiyle birleştir': 'Juntar com pessoa',
  'Aynı kişinin başka uygulamadaki sohbetiyle tek yerde':
      'A conversa desta pessoa em outro app, em um só lugar',
  '{name} kişisinden ayır': 'Separar de {name}',
  'Kişi': 'Pessoa',
  'Ne zaman hatırlatılsın?': 'Quando devemos lembrar você?',
  '⏰ {when} hatırlatılacak': '⏰ Você será lembrado {when}',
  '{target}: {name} ve {name2} sohbetleri birleşti':
      '{target}: as conversas de {name} e {name2} foram juntadas',
  '"{title}" silinsin mi?': 'Excluir "{title}"?',
  'Sohbet ve mesajları yalnızca Mesa\'dan silinir; {name} uygulamasındaki sohbete dokunulmaz.':
      'A conversa e as mensagens são excluídas só do Mesa; a conversa no {name} não é alterada.',
  '{title} ile birleştir': 'Juntar com {title}',
  'Aynı kişinin başka uygulamadaki sohbetini seçin. Mesajlar tek yerde görünür; istediğiniz zaman ayırabilirsiniz.':
      'Escolha a conversa desta pessoa em outro app. As mensagens aparecem em um só lugar; você pode separá-las quando quiser.',
  'Ara': 'Pesquisar',
  'Adını değiştir': 'Renomear',
  '{name} sohbetini ayır': 'Separar a conversa de {name}',
  'Kişinin adı': 'Nome da pessoa',
  '1 saat sonra': 'Daqui a 1 hora',
  '3 saat sonra': 'Daqui a 3 horas',
  'Bu akşam': 'Hoje à noite',
  'Yarın sabah': 'Amanhã de manhã',
  'Tarih ve saat seç': 'Escolher data e hora',
  'Yanıt bekliyor · {count}': 'Aguardando resposta · {count}',
  'Ertelenen sohbetler': 'Conversas adiadas',
  'Şimdi göster': 'Mostrar agora',
  'Sohbetler': 'Conversas',
  'Servisler': 'Serviços',
  'Kurallar': 'Regras',
  'Ayarlar': 'Configurações',
  'Yanıt gerekmez': 'Não precisa responder',
  'Yeni mesaj gelene kadar listeden kalkar':
      'Sai da lista até chegar uma nova mensagem',
  'Birleşik bildirimler açık. Yeni mesajlar artık Mesa bildirimiyle gelecek.':
      'As notificações unificadas estão ativadas. As novas mensagens vão chegar como notificações do Mesa.',
  'Mesajlar': 'Mensagens',
  'Hepsi okundu': 'Tudo lido',
  '{unreadTotal} okunmamış': '{unreadTotal} não lidas',
  'Haftalık özet': 'Resumo semanal',
  'Kaydedilenler': 'Salvas',
  'Diğer': 'Mais',
  'Tümünü okundu say': 'Marcar tudo como lido',
  'Arşiv ({archivedCount})': 'Arquivadas ({archivedCount})',
  'Tümü': 'Todos',
  'Ekle': 'Adicionar',
  'Servis ekle': 'Adicionar serviço',
  '{count} ertelenmiş sohbet':
      '{count, plural, one{# conversa adiada} other{# conversas adiadas}}',
  'Zamanı gelince hatırlatılacak': 'Você será lembrado na hora certa',
  '{name} artık tek satırda: {name2} ve {name3} mesajları birlikte.':
      '{name} agora é uma só linha: mensagens de {name2} e {name3} juntas.',
  'Tüm mesajlarda ara': 'Pesquisar em todas as mensagens',
  'Henüz mesaj yok': 'Ainda não há mensagens',
  'WhatsApp, Instagram, Discord gibi uygulamalardan yeni mesaj geldikçe burada toplanır; eski mesajlar görünmez. Telegram\'ı Ayarlar\'dan bağlarsanız geçmişi de gelir.':
      'As novas mensagens de apps como WhatsApp, Instagram e Discord se reúnem aqui conforme chegam; as antigas não aparecem. Conecte o Telegram em Configurações para receber o histórico também.',
  'Bildirimleri birleştir': 'Unificar notificações',
  'Her uygulamanın ayrı bildirimi yerine tek tip Mesa bildirimleri: kişi fotoğrafı, doğrudan yanıt ve kurallarınla birlikte.':
      'Um só tipo de notificação do Mesa em vez de uma para cada app: com foto do contato, resposta direta e suas regras.',
  'Bildirim servisi çalışmıyor':
      'O serviço de notificações não está funcionando',
  'Yeni mesajlar şu an yakalanmıyor. Xiaomi uygulamayı arka planda engelliyor: Otomatik başlatma iznini açın ve uygulama ayarlarında pil tasarrufunu "Kısıtlama yok" yapın. Ardından "Yeniden bağla"ya dokunun.':
      'As novas mensagens não estão sendo capturadas agora. A Xiaomi está bloqueando o app em segundo plano: ative a permissão de Início automático e deixe a economia de bateria em "Sem restrições" nas configurações do app. Depois toque em "Reconectar".',
  'Yeni mesajlar şu an yakalanmıyor. Telefon uygulamayı arka planda kapatmış olabilir: uygulama ayarlarında pil kısıtlamasını kaldırın, ardından "Yeniden bağla"ya dokunun.':
      'As novas mensagens não estão sendo capturadas agora. O celular pode ter fechado o app em segundo plano: remova a restrição de bateria nas configurações do app e depois toque em "Reconectar".',
  'Otomatik başlatma': 'Início automático',
  'Uygulama ayarları': 'Configurações do app',
  'Yeniden bağla': 'Reconectar',
  'Aynı kişi mi?': 'Mesma pessoa?',
  'Telefon numaraları aynı. Birleştirirseniz mesajları tek satırda, tek zaman çizgisinde görürsünüz.':
      'Os números de telefone são iguais. Juntando, você vê as mensagens em uma só linha, em uma só linha do tempo.',
  'Adları aynı. Birleştirirseniz mesajları tek satırda, tek zaman çizgisinde görürsünüz.':
      'Os nomes são iguais. Juntando, você vê as mensagens em uma só linha, em uma só linha do tempo.',
  'Farklı kişiler': 'Pessoas diferentes',
  'Birleştir': 'Juntar',
  'Uygulamanın dili': 'Idioma do app',
  'Telefonun dili': 'Idioma do celular',
  'Dil': 'Idioma',
  'Telefonun dili ({language})': 'Idioma do celular ({language})',
  'Mesa\'yı açmak için kimliğinizi doğrulayın':
      'Confirme sua identidade para abrir o Mesa',
  'Mesa kilitli': 'O Mesa está bloqueado',
  'Kilidi aç': 'Desbloquear',
  'Fotoğraflar': 'Fotos',
  'Videolar': 'Vídeos',
  'Ocak': 'Janeiro',
  'Şubat': 'Fevereiro',
  'Mart': 'Março',
  'Nisan': 'Abril',
  'Mayıs': 'Maio',
  'Haziran': 'Junho',
  'Temmuz': 'Julho',
  'Ağustos': 'Agosto',
  'Eylül': 'Setembro',
  'Ekim': 'Outubro',
  'Kasım': 'Novembro',
  'Aralık': 'Dezembro',
  'Henüz fotoğraf ya da video yok': 'Ainda não há fotos nem vídeos',
  'Bildiriminde önizlemesi gelen fotoğraflar ve Telegram medyası burada toplanır.':
      'As fotos com prévia nas notificações e a mídia do Telegram se reúnem aqui.',
  'Tam boyut': 'Tamanho original',
  'Medya açılamadı.': 'Não foi possível abrir a mídia.',
  'Görsel açılamadı.': 'Não foi possível abrir a imagem.',
  'İndiriliyor…': 'Baixando…',
  'Açılıyor…': 'Abrindo…',
  'İndiriliyor… %{percent}': 'Baixando… {percent}%',
  'Sesi kapat': 'Desativar som',
  'Sesi aç': 'Ativar som',
  'Tam ekrandan çık': 'Sair da tela cheia',
  'Tam ekran': 'Tela cheia',
  'Başlangıç saati': 'Horário de início',
  'Bitiş saati': 'Horário de término',
  'En az bir gün seçin.': 'Escolha pelo menos um dia.',
  'Kural silinsin mi?': 'Excluir a regra?',
  '"{name}" kalıcı olarak silinecek.':
      '"{name}" será excluída permanentemente.',
  'Yeni kural': 'Nova regra',
  'Kuralı düzenle': 'Editar regra',
  'Kural adı': 'Nome da regra',
  'Ne yapılsın?': 'O que deve acontecer?',
  'Mesaja, geldiği uygulama üzerinden otomatik cevap verilir.':
      'A mensagem recebe uma resposta automática pelo app de onde veio.',
  'Mesajlar kaydedilir ama okunmamış sayılmaz.':
      'As mensagens são salvas, mas não contam como não lidas.',
  'Sohbet, açılana kadar listenin en üstünde yıldızla durur.':
      'A conversa fica no topo da lista com uma estrela até você abri-la.',
  'Yanıt metni': 'Texto da resposta',
  'Şu an müsait değilim, sonra yazacağım.':
      'Não posso falar agora, escrevo depois.',
  'Otomatik yanıt için bir metin yazın':
      'Escreva um texto para a resposta automática',
  'Aynı sohbete tekrar yanıt için bekle':
      'Esperar antes de responder de novo à mesma conversa',
  'Hangi mesajlarda?': 'Em quais mensagens?',
  'Uygulama seçilmedi: tüm uygulamalar': 'Nenhum app escolhido: todos os apps',
  'Yalnızca seçilen uygulamalar': 'Só os apps escolhidos',
  'Kimden (isteğe bağlı)': 'De (opcional)',
  'Sohbet ya da kişi adında geçen ifade':
      'Texto no nome da conversa ou da pessoa',
  'Anahtar kelimeler (isteğe bağlı)': 'Palavras-chave (opcional)',
  'acil, toplantı, fatura': 'urgente, reunião, fatura',
  'Virgülle ayırın; herhangi biri geçerse kural çalışır':
      'Separe com vírgulas; a regra é aplicada se qualquer uma aparecer',
  'Grup sohbetlerinde de çalışsın': 'Também em conversas em grupo',
  'Gruptaki herkes otomatik yanıtı görür.':
      'Todos no grupo veem a resposta automática.',
  'Ne zaman?': 'Quando?',
  'Yalnızca belirli saatlerde': 'Só em certos horários',
  'Gün boyu': 'O dia todo',
  'Başlangıç {from}': 'Início {from}',
  'Bitiş {to}': 'Fim {to}',
  'Gece yarısını aşar: {from}–{to} (ertesi gün)':
      'Passa da meia-noite: {from}–{to} (dia seguinte)',
  'Koşul yok: bu kural her yeni mesaja yanıt verir (bekleme süresi ve saatlik sınırla).':
      'Sem condições: esta regra responde a cada nova mensagem (com o tempo de espera e o limite por hora).',
  'Kurallar nasıl çalışır?': 'Como as regras funcionam?',
  'Kurallar uygulama kapalıyken de, yeni mesaj gelir gelmez çalışır.\n\nOtomatik yanıt güvenliği: aynı anda gelen mesajlara tek yanıt; aynı sohbete bekleme süresi dolmadan tekrar yanıt yok; tüm sohbetlerde saatte en fazla 20 yanıt.\n\nYanıt, kaynak uygulamanın bildirimi üzerinden (Telegram\'da doğrudan) gider; bildirim yoksa gönderilmez.':
      'As regras são aplicadas assim que chega uma nova mensagem, mesmo com o app fechado.\n\nSegurança das respostas automáticas: uma só resposta para mensagens que chegam juntas; nada de responder de novo à mesma conversa antes do fim do tempo de espera; no máximo 20 respostas por hora somando todas as conversas.\n\nA resposta sai pela notificação do app de origem (direto no Telegram); sem notificação, não é enviada.',
  'Otomatik yanıt, sessize alma, önemli işaretleme':
      'Resposta automática, silenciar, marcar como importante',
  '{active} etkin kural':
      '{active, plural, one{# regra ativa} other{# regras ativas}}',
  'Kural ekle': 'Adicionar regra',
  'Kurallarınız': 'Suas regras',
  'Son 7 günde {recentFires} kez çalıştı':
      'Aplicada {recentFires, plural, one{uma vez} other{# vezes}} nos últimos 7 dias',
  'Henüz kural yok': 'Ainda não há regras',
  'Yukarıdaki hazır kurallardan birine dokunun ya da kendiniz ekleyin.':
      'Toque em uma das regras prontas acima ou crie a sua.',
  'WhatsApp\'ta "acil" geçen mesajları önemli işaretle':
      'Marcar como importantes as mensagens do WhatsApp com "urgente"',
  'İş grubunu sessize al': 'Silenciar o grupo do trabalho',
  'Gece 23:00–08:00 arası "Sabah yazarım" diye yanıtla':
      'Responder "Escrevo de manhã" entre 23:00 e 08:00',
  'Gece modu': 'Modo noturno',
  '23:00–08:00 otomatik yanıt': 'Resposta automática das 23:00 às 08:00',
  'Gece otomatik yanıt': 'Resposta automática noturna',
  'Şu an uyuyorum, sabah dönerim 🌙':
      'Estou dormindo agora, respondo de manhã 🌙',
  'Meşgulüm': 'Ocupado',
  'Herkese kısa yanıt': 'Resposta curta para todos',
  'Şu an müsait değilim, birazdan yazarım.':
      'Não posso falar agora, escrevo já já.',
  'Mesai dışı': 'Fora do expediente',
  'Hafta içi 18:00–09:00': 'Dias úteis 18:00–09:00',
  'Mesai dışı yanıt': 'Resposta fora do expediente',
  'Mesai saatleri dışındayım, yarın dönüş yapacağım.':
      'Estou fora do horário de trabalho, respondo amanhã.',
  'Acil mesajlar': 'Mensagens urgentes',
  '"acil", "hemen" geçenleri öne çıkar':
      'Destaca as que têm "urgente", "agora"',
  'acil': 'urgente',
  'hemen': 'agora',
  'önemli': 'importante',
  'ara beni': 'me liga',
  'Hazır kurallar': 'Regras prontas',
  'Mesajlarda ara': 'Pesquisar nas mensagens',
  'Bütün uygulamalardaki mesajlarda arar. En az iki harf yazın.':
      'Pesquisa nas mensagens de todos os apps. Digite pelo menos duas letras.',
  'Sonuç bulunamadı.': 'Nenhum resultado.',
  '{name} açılamadı.': 'Não foi possível abrir o {name}.',
  'Servisler nasıl çalışır?': 'Como os serviços funcionam?',
  'Her servis kendi resmi web sitesiyle, uygulamanın içindeki tarayıcıda açılır. Giriş bilgileriniz yalnızca bu telefonda kalır; Mesa yalnızca o servisin sunucusuyla konuşur.\n\nArka planda bağlı servisler uygulama kapalıyken de yeni mesajları bildirir ve mesajlar Sohbetler\'e düşer. Bunun için telefonun pil ayarında Mesa\'ya "Kısıtlama yok" verilmelidir. Her açık servis pil ve bellek harcar.\n\nInstagram, X ve LinkedIn gibi bazı siteler açıkken mesaj bildirimi göndermez; onlarda okunmamış sayısı arttığında haber verilir.\n\n"Google ile giriş" bu sayfalarda çalışmaz; e-posta ve şifreyle girin.':
      'Cada serviço abre com seu próprio site oficial no navegador dentro do app. Seus dados de login ficam só neste celular; o Mesa só fala com o servidor daquele serviço.\n\nOs serviços conectados em segundo plano avisam sobre novas mensagens mesmo com o app fechado, e as mensagens chegam em Conversas. Para isso, o Mesa precisa estar em "Sem restrições" nas configurações de bateria do celular. Cada serviço aberto gasta bateria e memória.\n\nAlguns sites, como Instagram, X e LinkedIn, não enviam notificações de mensagem enquanto estão abertos; neles você é avisado quando o número de não lidas aumenta.\n\n"Entrar com o Google" não funciona nestas páginas; entre com e-mail e senha.',
  '{unread} okunmamış': '{unread} não lidas',
  'Tüm uygulamalar tek yerde': 'Todos os apps em um só lugar',
  'Uygulamalar': 'Apps',
  'Web servisleri': 'Serviços web',
  '{name} ayarları': 'Configurações do {name}',
  'Okunmamış var': 'Há mensagens não lidas',
  'Bildirim kapalı': 'Notificações desativadas',
  'Arka planda bağlı': 'Conectado em segundo plano',
  'Yalnızca açıkken': 'Só enquanto aberto',
  'Henüz web servisi yok': 'Ainda não há serviços web',
  'Telefonda uygulaması olmayan servisleri resmi web sürümleriyle buraya ekleyin. Yeni mesajlar Sohbetler\'e ve bildirimlere düşer.':
      'Adicione aqui, pelas versões web oficiais, os serviços que não têm app neste celular. As novas mensagens chegam em Conversas e nas notificações.',
  'Başka bir site': 'Outro site',
  'Adresini yazarak, ör. vk.com/im': 'Digitando o endereço, ex.: vk.com/im',
  'KakaoTalk, Viber, LINE ve Signal\'in web sürümü yok. Uygulamaları telefona kurulursa mesajları bildirimlerden otomatik toplanır.':
      'KakaoTalk, Viber, LINE e Signal não têm versão web. Se os apps deles estiverem instalados no celular, as mensagens são coletadas automaticamente das notificações.',
  'Ekli · ikinci hesap eklenir': 'Adicionado · adiciona uma segunda conta',
  'Uygulaması kurulu, bildirimleri zaten geliyor':
      'O app está instalado, as notificações dele já chegam',
  'https ile açılan geçerli bir site adresi yazın.':
      'Digite um endereço de site válido que comece com https.',
  'Ad': 'Nome',
  'Adres': 'Endereço',
  '{name} oturumu kapatılsın mı?': 'Sair do {name}?',
  'Bu servisin giriş bilgileri ve site verileri telefondan silinir. Yeniden giriş yapmanız gerekir.':
      'Os dados de login e do site deste serviço serão apagados do celular. Você vai precisar entrar de novo.',
  'Oturumu kapat': 'Sair',
  '{name} kaldırılsın mı?': 'Remover {name}?',
  'Oturum ve site verileri telefondan silinir. Sohbetler\'deki eski mesajlar kalır.':
      'A sessão e os dados do site serão apagados do celular. As mensagens antigas em Conversas continuam.',
  'Kaldır': 'Remover',
  'Arka planda bağlı kalsın': 'Manter conectado em segundo plano',
  'Uygulama kapalıyken de yeni mesajlar bildirilir; pil kullanımı artar':
      'Avisa sobre novas mensagens mesmo com o app fechado; gasta mais bateria',
  'Bildirimler': 'Notificações',
  'Yeni mesajlar Sohbetler\'e ve bildirimlere':
      'Novas mensagens em Conversas e nas notificações',
  'Videolar kendiliğinden oynasın': 'Reproduzir vídeos automaticamente',
  'Kapalıyken videolar dokununca oynar; sayfa daha akıcı olur':
      'Desativado, os vídeos tocam ao serem tocados; a página fica mais fluida',
  'Eski mesajlar silinsin mi?': 'Excluir mensagens antigas?',
  '{days} öncesine ait mesajlar ve görselleri Mesa\'dan kalıcı olarak silinecek. Kaynak uygulamalardaki mesajlara dokunulmaz.':
      'Mensagens e imagens com mais de {days} serão excluídas permanentemente do Mesa. As mensagens nos apps de origem não são alteradas.',
  'Seçilen uygulamalarda yanıt, Mesa yeniden başlasa da doğrudan gider':
      'Nos apps escolhidos, as respostas vão direto mesmo se o Mesa reiniciar',
  'Kendi bildirimi de kalsın': 'Manter também a notificação do próprio app',
  'Seçtiğiniz uygulamanın bildirimi çubuktan kaldırılmaz. Bildirim orada durdukça, Mesa yeniden başlasa da (güncelleme, telefonun yeniden açılması) o sohbete yanıt ve planlı mesaj uygulamaya geçmeden gider. Aynı mesaj için iki bildirim görürsünüz; Mesa\'nınki sessiz gelir.':
      'A notificação do app escolhido não é removida da barra. Enquanto ela estiver lá, respostas e mensagens agendadas para aquela conversa vão direto, sem passar pelo app, mesmo se o Mesa reiniciar (uma atualização, o celular reiniciando). Você vai ver duas notificações da mesma mensagem; a do Mesa chega em silêncio.',
  'Ana ekranda boş bir yere basılı tutun → Bileşenler (Widget) → Mesa\'yı sürükleyip bırakın.':
      'Toque e segure um espaço vazio da tela inicial → Widgets → arraste e solte o Mesa.',
  'Birleşik bildirimler': 'Notificações unificadas',
  'Uygulamaların ayrı bildirimleri yerine kişi fotoğraflı, yanıtlanabilen tek tip bildirim':
      'Um só tipo de notificação com a foto do contato, que você pode responder, em vez das notificações separadas de cada app',
  'Önemli mesajlarda bildirim': 'Notificar mensagens importantes',
  '"Önemli işaretle" kuralına uyunca, sessizdekiler dahil':
      'Quando a regra "Marcar como importante" é aplicada, inclusive nas silenciadas',
  'Ana ekran': 'Tela inicial',
  'Ana ekran bileşeni': 'Widget da tela inicial',
  'Okunmamışlar ve yanıt bekleyenler, uygulamayı açmadan':
      'Não lidas e aguardando resposta, sem abrir o app',
  'Bağlantılar': 'Conexões',
  'Doğrudan bağlantı: sessiz gruplar ve geçmiş':
      'Conexão direta: grupos silenciados e histórico',
  'Telegram\'da gizli okuma': 'Leitura oculta no Telegram',
  'Okuduğunuzda "görüldü", yazarken "yazıyor" gitmez':
      'Sem "visto" ao ler e sem "digitando" ao escrever',
  'Telegram kanallarını gösterme': 'Ocultar canais do Telegram',
  'Kişiler ve gruplar gelmeye devam eder':
      'Pessoas e grupos continuam chegando',
  'Okunan uygulamalar': 'Apps de onde as mensagens são coletadas',
  'Gizlilik': 'Privacidade',
  'Görmeden okuma': 'Ler sem ser visto',
  'WhatsApp, Instagram ve diğerlerinde mesajı burada okumak karşı tarafa "görüldü" göndermez. Yanıt verirseniz gider.':
      'Ler aqui uma mensagem do WhatsApp, Instagram e outros não envia "visto" para quem mandou. É enviado se você responder.',
  'Silinen mesajlar korunur': 'As mensagens apagadas são mantidas',
  'Gönderen mesajı silse de metni burada "silindi" etiketiyle kalır.':
      'Mesmo que quem enviou apague a mensagem, o texto fica aqui com a etiqueta "apagada".',
  'Mesajları sakla': 'Manter mensagens',
  '{retentionDays} sonra silinir': 'Excluídas após {retentionDays}',
  'Yazma': 'Escrita',
  '{count} yanıt': '{count, plural, one{# resposta} other{# respostas}}',
  'Telefonda ekran kilidi ya da parmak izi tanımlı değil.':
      'Não há bloqueio de tela nem impressão digital configurados neste celular.',
  'Uygulama kilidini açmak için doğrulayın':
      'Confirme para ativar o bloqueio do app',
  'Uygulama kilidi': 'Bloqueio do app',
  'Parmak izi, yüz tanıma ya da ekran kilidi':
      'Impressão digital, reconhecimento facial ou bloqueio de tela',
  'Yeni hazır yanıt': 'Nova resposta rápida',
  'Hazır yanıt yok.': 'Nenhuma resposta rápida.',
  'Düzelt': 'Corrigir',
  'Sistem durumu · her şey hazır': 'Status do sistema · tudo pronto',
  'Sistem durumu · {problems} ayar eksik':
      'Status do sistema · {problems, plural, one{falta # configuração} other{faltam # configurações}}',
  'Bildirim erişimi': 'Acesso às notificações',
  'Mesajlar yakalanıyor': 'As mensagens estão sendo capturadas',
  'İzin var ama sistem servisi bağlamadı':
      'Há permissão, mas o sistema não conectou o serviço',
  'Mesajları okumak için gerekli': 'Necessário para ler as mensagens',
  'Bağla': 'Conectar',
  'İzin ver': 'Permitir',
  'Bildirim izni': 'Permissão de notificações',
  'Yeni mesajlar bildirilir': 'As novas mensagens são notificadas',
  'Kapalıysa yeni mesaj bildirimi görmezsiniz':
      'Desativado, você não vê notificações de novas mensagens',
  'Pil kısıtlaması yok': 'Sem restrição de bateria',
  'Arka planda kapatılmaz': 'Não é fechado em segundo plano',
  'Telefon uygulamayı arka planda kapatıp mesajları geciktirebilir':
      'O celular pode fechar o app em segundo plano e atrasar as mensagens',
  'Otomatik başlatma (Xiaomi)': 'Início automático (Xiaomi)',
  'Açık olmalı; telefon yeniden başlayınca da çalışsın':
      'Precisa estar ativado para funcionar também depois que o celular reiniciar',
  'Kontrol et': 'Verificar',
  'Mikrofon': 'Microfone',
  'Sesli mesaj kaydedilebilir': 'É possível gravar mensagens de voz',
  'Yalnızca sesli mesaj için; ilk kayıtta sorulur':
      'Só para mensagens de voz; pedido na primeira gravação',
  'Tüm mesajlar tek tip, buradan yanıtlanabilen bildirimle':
      'Todas as mensagens em um só tipo de notificação que você responde daqui',
  'Kapalıysa yeni mesajları fark etmezsiniz':
      'Desativado, você não percebe as novas mensagens',
  'Pil kısıtlamasını kaldır': 'Remover a restrição de bateria',
  'Arka planda kapatılmasın, mesajlar gecikmesin':
      'Para não ser fechado em segundo plano e as mensagens não atrasarem',
  'Telefon yeniden açılınca da çalışsın':
      'Para funcionar também depois que o celular reiniciar',
  'Son uygulamalarda kilitle': 'Travar em apps recentes',
  'Son uygulamalarda karta basılı tutup kilide dokunun; kilitsizken kaydırınca kapanıyor':
      'Em apps recentes, segure o cartão e toque no cadeado; sem trava, deslizar fecha o app',
  'Yaptım': 'Feito',
  'WhatsApp\'a geçmeden yanıt': 'Responder sem ir para o WhatsApp',
  'Uygulama yeniden başlasa da yanıtlar doğrudan gitsin':
      'Para as respostas irem direto mesmo se o app reiniciar',
  'Kurulumu tamamla · {done}/{count}': 'Concluir configuração · {done}/{count}',
  'Mesajlar eksiksiz ve gecikmeden gelsin':
      'Para as mensagens chegarem completas e sem atraso',
  'Sonra': 'Depois',
  'Telegram\'ı bağla · isteğe bağlı': 'Conectar o Telegram · opcional',
  'Sessiz gruplar ve geçmiş de gelsin':
      'Receber também grupos silenciados e histórico',
  'Daha az göster': 'Mostrar menos',
  '{pending} adım daha':
      '{pending, plural, one{falta # etapa} other{faltam # etapas}}',
  'İsteğe bağlı adımlar': 'Etapas opcionais',
  'Henüz kaydedilen mesaj yok': 'Ainda não há mensagens salvas',
  'Bir mesaja basılı tutup "Kaydet"e dokunun. Adres, kod, tarih gibi önemli mesajlar hangi uygulamadan gelirse gelsin burada toplanır.':
      'Toque e segure uma mensagem e toque em "Salvar". Mensagens importantes, como endereços, códigos e datas, se reúnem aqui, venham do app que vierem.',
  'Fotoğraflar ve profil resimleri': 'Fotos e fotos de perfil',
  'Telegram önbelleği': 'Cache do Telegram',
  'Geçici dosyalar': 'Arquivos temporários',
  'Önbellek temizlensin mi?': 'Limpar o cache?',
  'Telegram\'da 7 gündür açılmamış fotoğraf ve videolar, web servislerinin önbelleği ve geçici dosyalar silinir. Mesajlar, kişiler ve oturumlar silinmez; Telegram medyası açınca yeniden iner.':
      'Fotos e vídeos do Telegram não abertos há 7 dias, o cache dos serviços web e os arquivos temporários são apagados. Mensagens, pessoas e sessões não são apagadas; a mídia do Telegram é baixada de novo quando você a abre.',
  'Temizle': 'Limpar',
  '{freed} yer açıldı.': '{freed} liberados.',
  'Temizlenecek önbellek yoktu.': 'Não havia cache para limpar.',
  'Eski mesajları silmek için: saklama süresi.':
      'Para apagar mensagens antigas: período de retenção.',
  'Önbelleği temizle': 'Limpar cache',
  'Günlere göre': 'Por dia',
  'En çok yazıştıkların': 'Com quem você mais conversa',
  '{count} mesaj · {name}':
      '{count, plural, one{# mensagem} other{# mensagens}} · {name}',
  'Son 7 gün': 'Últimos 7 dias',
  '{total} mesaj': '{total, plural, one{# mensagem} other{# mensagens}}',
  '{incoming} gelen': '{incoming} recebidas',
  '{outgoing} giden': '{outgoing} enviadas',
  '{people} kişi': '{people, plural, one{# pessoa} other{# pessoas}}',
  '%{percent}': '{percent}%',
  'En yoğun saatin {hour}:00': 'Seu horário mais movimentado é {hour}:00',
  'Gelen her 10 mesaja {ratio} yanıt':
      '{ratio} respostas a cada 10 mensagens recebidas',
  'Gönderenin silip sende kalan {deleted} mesaj':
      '{deleted, plural, one{# mensagem apagada por quem enviou e guardada para você} other{# mensagens apagadas por quem enviou e guardadas para você}}',
  'Bilgiler': 'Destaques',
  'Çıkartmalar': 'Figurinhas',
  'Bu bölümde çıkartma yok.': 'Não há figurinhas nesta seção.',
  'GIF ara (boşsa kaydedilenler)': 'Pesquisar GIFs (vazio: salvos)',
  'Kaydedilmiş GIF yok. Yukarıdan arayabilirsiniz.':
      'Nenhum GIF salvo. Você pode pesquisar acima.',
  'GIF bulunamadı.': 'Nenhum GIF encontrado.',
  'Telegram bağlantısı kapatılsın mı?': 'Desconectar o Telegram?',
  'Bu cihazın oturumu Telegram\'dan çıkarılır. Daha önce alınan mesajlar Mesa\'da kalır.':
      'A sessão deste aparelho será removida do Telegram. As mensagens recebidas antes ficam no Mesa.',
  'Çıkış yap': 'Sair',
  'Telegram bağlantısı': 'Conexão com o Telegram',
  'Bu derlemede Telegram uygulama kimliği yok. my.telegram.org → "API development tools" bölümünden api_id ve api_hash alınıp android/local.properties dosyasına telegram.apiId ve telegram.apiHash olarak yazılmalı, ardından uygulama yeniden derlenmeli.':
      'Esta versão não tem um ID de app do Telegram. Obtenha um api_id e um api_hash em my.telegram.org → "API development tools", escreva-os em android/local.properties como telegram.apiId e telegram.apiHash e compile o app de novo.',
  '+90 5xx xxx xx xx': '+55 11 9xxxx-xxxx',
  'Devam': 'Continuar',
  'Telegram hesabınız bağlı. Sessizdeki gruplar dahil yeni mesajlar gelen kutusuna düşer. Bir sohbeti açınca son mesajları da indirilir.':
      'Sua conta do Telegram está conectada. As novas mensagens, inclusive de grupos silenciados, chegam na caixa de entrada. Ao abrir uma conversa, as mensagens recentes também são baixadas.',
  'Bu giriş adımı desteklenmiyor.': 'Esta etapa de login não é compatível.',
  'Telegram hesabınızı bağlayın': 'Conecte sua conta do Telegram',
  'Mesa, Telegram\'ın resmi kütüphanesiyle hesabınıza doğrudan bağlanır. Böylece bildirim üretmeyen sessiz grupların mesajları da gelir.':
      'O Mesa se conecta direto à sua conta com a biblioteca oficial do Telegram, então chegam também as mensagens dos grupos silenciados, que não geram notificações.',
  'Telegram\'a bağlan': 'Conectar ao Telegram',
  'Çıkış yapılıyor…': 'Saindo…',
  'Telegram\'a bağlanılıyor…': 'Conectando ao Telegram…',
  'Telefon numaranız': 'Seu número de telefone',
  'Doğrulama kodu': 'Código de verificação',
  'E-posta kodu': 'Código do e-mail',
  'İki adımlı doğrulama şifresi': 'Senha da verificação em duas etapas',
  'Telefon numarası (ülke koduyla)': 'Número de telefone (com código do país)',
  'Kod': 'Código',
  '• Bağlantı yalnızca Telegram sunucularına gider; mesajlar yalnızca bu telefonda saklanır.\n• Okundu bilgisi gönderilmez, çevrimiçi görünmezsiniz.\n• Bu cihaz Telegram\'da "Etkin oturumlar" listesinde görünür.\n• Bağlıyken bildirim çubuğunda sessiz bir "Telegram\'a bağlı" bildirimi durur.':
      '• A conexão vai só para os servidores do Telegram; as mensagens ficam só neste celular.\n• Confirmações de leitura não são enviadas e você não aparece online.\n• Este aparelho aparece na lista "Sessões ativas" do Telegram.\n• Enquanto estiver conectado, uma notificação silenciosa "Conectado ao Telegram" fica na barra.',
  'Bir sohbete basılı tutun: sabitleyin, sonraya erteleyin ya da aynı kişinin başka uygulamadaki sohbetiyle birleştirin.':
      'Toque e segure uma conversa: fixe, adie para depois ou junte com a conversa da mesma pessoa em outro app.',
  'Gönder düğmesine basılı tutun: mesajı istediğiniz saate planlayın.':
      'Toque e segure o botão de enviar: agende a mensagem para o horário que quiser.',
  'Bir mesaja basılı tutup "Kaydet": tüm uygulamalardan kaydettikleriniz üstteki 🔖 listesinde.':
      'Toque e segure uma mensagem e toque em "Salvar": o que você salva de todos os apps fica na lista 🔖 lá em cima.',
  'Sohbetin üstündeki galeri düğmesi: o kişiyle paylaşılan tüm fotoğraf ve videolar tek yerde.':
      'O botão de galeria no topo da conversa: todas as fotos e vídeos trocados com aquela pessoa em um só lugar.',
  'Bildirimden yazmadan yanıtlayın: hazır yanıtlarınız bildirimin altında tek dokunuşla. Listeyi Ayarlar → Hazır yanıtlar\'dan değiştirin.':
      'Responda pela notificação sem digitar: suas respostas rápidas ficam a um toque, embaixo da notificação. Mude a lista em Configurações → Respostas rápidas.',
  'Ana ekran bileşeni: okunmamışlar ve yanıt bekleyenler uygulamayı açmadan. Ayarlar → Ana ekran → Ekle.':
      'Widget da tela inicial: não lidas e quem aguarda resposta, sem abrir o app. Configurações → Tela inicial → Adicionar.',
  'Haftalık özet: kimlerle en çok yazıştığınızı üstteki grafik düğmesinden görün.':
      'Resumo semanal: veja com quem você mais conversa pelo botão de gráfico lá em cima.',
  'Günün ipucu': 'Dica do dia',
  'Tüm mesajların tek yerde': 'Todas as suas mensagens em um só lugar',
  'WhatsApp, Telegram, Instagram, Discord ve diğerleri tek gelen kutusunda; uygulamalar arasında gidip gelmeden.':
      'WhatsApp, Telegram, Instagram, Discord e outros em uma só caixa de entrada, sem ficar pulando entre apps.',
  'Bir kişi, tek sohbet': 'Uma pessoa, uma conversa',
  'Aynı kişiyle WhatsApp\'tan, Instagram\'dan, Telegram\'dan yazıştıklarınız tek zaman çizgisinde; yanıtı istediğiniz uygulamadan verin.':
      'O que você conversa com a mesma pessoa no WhatsApp, Instagram e Telegram em uma só linha do tempo; responda pelo app que preferir.',
  'Görüldü göndermeden oku': 'Leia sem enviar "visto"',
  'WhatsApp ve Instagram mesajlarını burada okumak karşı tarafa "görüldü" göndermez; Telegram\'da da isteğe bağlı.':
      'Ler aqui mensagens do WhatsApp e do Instagram não envia "visto"; no Telegram também é opcional.',
  'Silinen mesajın yazısı kalır': 'O texto da mensagem apagada fica',
  'Gönderen "herkesten sil" dese de yazdığı metin burada "silindi" etiketiyle durur.':
      'Mesmo que quem enviou escolha "apagar para todos", o que escreveu fica aqui com a etiqueta "apagada".',
  'Yanıt bekleyenler en üstte; sohbeti sonraya ertele, mesajı istediğin saate planla.':
      'Quem aguarda resposta fica no topo; adie uma conversa, agende uma mensagem para o horário que quiser.',
  'Telefonunda kalır': 'Fica no seu celular',
  'Mesajlar yalnızca bu telefonda saklanır; hiçbir sunucuya gönderilmez.':
      'As mensagens ficam só neste celular; nunca são enviadas para nenhum servidor.',
  'Bildirim erişimini aç': 'Ativar o acesso às notificações',
  'Mesa mesajları uygulamaların bildirimlerinden okur. Açılan listede Mesa\'yı bulup izin verin.':
      'O Mesa lê as mensagens nas notificações dos apps. Encontre o Mesa na lista que abrir e dê permissão.',
  'İzin verilemiyor mu?': 'Não consegue ativar?',
  'Android, mağaza dışından kurulan uygulamalarda bu izni kısıtlar. Mesa\'nın anahtarına bir kez dokunun, sonra Uygulama bilgileri → ⋮ → Kısıtlanmış ayarlara izin ver\'i seçip tekrar deneyin.':
      'O Android restringe esta permissão em apps instalados fora de uma loja. Toque uma vez no botão do Mesa, depois abra Informações do app → ⋮ → Permitir configurações restritas e tente de novo.',
  'Uygulama bilgileri': 'Informações do app',
  // Güvenli bağlantı (1.1)
  'Anahtar (secret)': 'Chave (secret)',
  'Açık · {provider}': 'Ativado · {provider}',
  'Açılan pencerede "Tamam"a dokunarak VPN iznini verin.':
      'Toque em "OK" na janela que abrir para permitir a VPN.',
  'Bağlantıdan ekle': 'Adicionar por link',
  'Başka bir VPN açık. Android aynı anda tek VPN\'e izin verir; şifreli DNS açılınca o kapanır.':
      'Outra VPN está ativada. O Android permite só uma VPN por vez; ao ativar o DNS seguro, ela será desativada.',
  'Başka bir VPN açıldığı için şifreli DNS kapandı.':
      'O DNS seguro foi desativado porque outra VPN foi ativada.',
  'Bildirim panelini aşağı çekip düzenle simgesine dokunun ve "Şifreli DNS" kutucuğunu ekleyin; tek dokunuşla açıp kapatırsınız.':
      'Puxe o painel de notificações, toque no ícone de editar e adicione o bloco "DNS seguro" para ligar e desligar com um toque.',
  'Bir hata oluştu.': 'Algo deu errado.',
  'Bu bir Telegram proxy bağlantısı değil.':
      'Isto não é um link de proxy do Telegram.',
  'Bu telefonun tarayıcı bileşeni bunu desteklemiyor.':
      'O componente de navegador deste telefone não oferece suporte a isso.',
  'Bütün telefonda reklamları ve izleyicileri engeller':
      'Bloqueia anúncios e rastreadores no telefone inteiro',
  'Bütün telefonda şifreli DNS': 'DNS seguro no telefone inteiro',
  'Dene': 'Testar',
  'Discord, Slack gibi web servisleri DNS ve SNI engellerine takılmadan açılır. VPN gerekmez, kendi VPN\'inizle de çakışmaz.':
      'Serviços web como Discord e Slack abrem sem esbarrar em bloqueios de DNS e SNI. Não precisa de VPN e não conflita com a sua VPN.',
  'Elle ekle': 'Adicionar manualmente',
  'En hızlı seçeneklerden biri; gizlilik odaklı':
      'Uma das opções mais rápidas; focada em privacidade',
  'Engellenen servislere erişin ve DNS sorgularınızı gizleyin. Sunucu yok, hesap yok.':
      'Acesse serviços bloqueados e esconda suas consultas DNS. Sem servidores, sem conta.',
  'Engellenen servislere erişin, DNS sorgularınızı gizleyin, reklamları engelleyin':
      'Acesse serviços bloqueados, esconda consultas DNS, bloqueie anúncios',
  'Erişim kalkanı': 'Escudo de acesso',
  'Erişim kalkanı açıldı. Web servislerini yeniden açınca devreye girer.':
      'O escudo de acesso foi ativado. Ele passa a valer quando você reabrir os serviços web.',
  'Geçerli bir MTProto anahtarı girin.': 'Digite uma chave MTProto válida.',
  'Google\'ın genel DNS\'i': 'DNS público do Google',
  'Güvenli bağlantı': 'Conexão segura',
  'Her zaman açık': 'Sempre ativado',
  'Hızlı ayarlar kutucuğu': 'Bloco de configurações rápidas',
  'Hızı ölç': 'Medir velocidade',
  'Kapalı': 'Desativado',
  'Kullanıcı adı (isteğe bağlı)': 'Usuário (opcional)',
  'Kullanılıyor': 'Em uso',
  'Ortalama {ms} ms · {cached} önbellekten · {failed} başarısız':
      'Média de {ms} ms · {cached} do cache · {failed} com falha',
  'Parola (isteğe bağlı)': 'Senha (opcional)',
  'Port': 'Porta',
  'Proxy bağlantısı': 'Link de proxy',
  'Proxy ekle': 'Adicionar proxy',
  'Proxy eklemek için önce Telegram bağlantısını başlatın.':
      'Para adicionar um proxy, inicie primeiro a conexão com o Telegram.',
  'Proxy eklendi ve Telegram için açıldı.':
      'Proxy adicionado e ativado para o Telegram.',
  'Sunucu': 'Servidor',
  'Sunucu ve port (1–65535) gerekli.':
      'Servidor e porta (1–65535) são obrigatórios.',
  'Telefon açılınca kendiliğinden başlasın: sistemin VPN ayarlarında Mesa için "Her zaman açık VPN"i seçin.':
      'Para iniciar sozinho ao ligar o telefone, escolha "VPN sempre ativa" para o Mesa nas configurações de VPN do sistema.',
  'Telefonun "Özel DNS" ayarı bir sunucuya sabitlenmiş; o ayar kapatılmadan şifreli DNS etkisiz kalabilir.':
      'A configuração "DNS particular" do telefone está fixada em um servidor; o DNS seguro pode não ter efeito até você desativá-la.',
  'Telegram proxy': 'Proxy do Telegram',
  'Telegram\'a doğrudan erişim': 'Acesso direto ao Telegram',
  'Ulaşılamıyor': 'Inacessível',
  'VPN izni verilmedi. Açmak için yeniden deneyin.':
      'A permissão de VPN não foi concedida. Tente de novo para ativar.',
  'Web servisleri için erişim kalkanı': 'Escudo de acesso para serviços web',
  'Zararlı siteleri engeller; kâr amacı gütmeyen kuruluş':
      'Bloqueia sites maliciosos; mantido por uma organização sem fins lucrativos',
  'Zararlı sitelerle birlikte yetişkin içeriği de engeller':
      'Bloqueia conteúdo adulto além de sites maliciosos',
  'Zararlı ve oltalama sitelerini engeller':
      'Bloqueia sites maliciosos e de phishing',
  '{connections} bağlantı · {splits} engel aşma':
      '{connections} conexões · {splits} bloqueios contornados',
  '{count, plural, one{# sorgu} other{# sorgu}}':
      '{count, plural, one{# consulta} other{# consultas}}',
  'Ölçülüyor…': 'Medindo…',
  'Şifreli DNS': 'DNS seguro',
  'Şifreli DNS ve erişim kalkanı': 'DNS seguro e escudo de acesso',
  'Şifreli DNS, operatörün DNS engellerini aşar ve hangi sitelere girdiğinizi operatörden gizler. IP adresinizi gizlemez; tam bir VPN değildir. DNS sorguları seçtiğiniz sağlayıcıya gider, Mesa\'nın sunucusu yoktur.':
      'O DNS seguro contorna os bloqueios de DNS da operadora e esconde dela quais sites você visita. Não esconde seu endereço IP; não é uma VPN completa. As consultas DNS vão para o provedor escolhido; o Mesa não tem servidores.',
  // 2. aşama: tam VPN, odak modu, otomatik yedek, balonlar (1.2)
  '3 saat': '3 horas',
  'Acil durum': 'Emergências',
  'Aynı kişi 5 dakika içinde 3 kez yazarsa bildirim gelir.':
      'Se a mesma pessoa escrever 3 vezes em 5 minutos, você é notificado.',
  'Açık': 'Ativado',
  'Açık · siz kapatana kadar': 'Ativado · até você desativar',
  'Açık · {time} saatine kadar': 'Ativado · até {time}',
  'Bağlantı yoksa interneti kes': 'Bloquear a internet sem a VPN',
  'Bağlanıyor… sunucudan henüz yanıt yok':
      'Conectando… o servidor ainda não respondeu',
  'Bağlı': 'Conectado',
  'Başlangıç': 'Início',
  'Ben kapatana kadar': 'Até eu desativar',
  'Bildirim panelindeki "Odak modu" kutucuğuyla da tek dokunuşla açıp kapatabilirsiniz.':
      'Você também pode ligar e desligar com um toque pelo bloco "Modo foco" no painel de notificações.',
  'Bildirimdeki sohbet ekranın üstünde yüzen balonda açılır; uygulamayı açmadan yanıtlayın':
      'A conversa da notificação abre em uma bolha flutuante; responda sem abrir o app',
  'Birleşik bildirimler kapalı: WhatsApp gibi uygulamaların kendi bildirimleri yine ses çıkarabilir. Odak modunun her şeyi susturması için birleşik bildirimleri açın.':
      'As notificações unificadas estão desativadas: apps como o WhatsApp ainda podem tocar com as próprias notificações. Ative-as para o modo foco silenciar tudo.',
  'Bitiş': 'Fim',
  'Bu yapılandırma bu telefonda açılamıyor; silip yeniden içe aktarın.':
      'Esta configuração não pode ser aberta neste telefone; exclua e importe de novo.',
  'Bütün trafiğiniz kendi WireGuard sunucunuz ya da bir VPN sağlayıcısı üzerinden geçer; IP adresiniz değişir.':
      'Todo o seu tráfego passa pelo seu próprio servidor WireGuard ou por um provedor de VPN; seu endereço IP muda.',
  'Dosya okunamadı.': 'Não foi possível ler o arquivo.',
  'Dosyadan içe aktar': 'Importar de arquivo',
  'Eklenecek sohbet yok.': 'Não há conversas para adicionar.',
  'Her gün': 'Todos os dias',
  'Her gün belirli saatlerde': 'Em horários fixos todos os dias',
  'Her hafta': 'Toda semana',
  'Israrla yazana izin ver': 'Deixar passar mensagens insistentes',
  'Kayıtlı parola açılamadı; otomatik yedeği yeniden açın.':
      'Não foi possível abrir a senha salva; ative o backup automático de novo.',
  'Klasör seç': 'Escolher pasta',
  'Klasöre yazılamadı; klasörü yeniden seçin.':
      'Não foi possível gravar na pasta; escolha a pasta de novo.',
  'Odak modu': 'Modo foco',
  'Odak modu açık': 'Modo foco ativado',
  'Odaktayken yalnızca VIP kişiler, "Önemli işaretle" kuralına uyan mesajlar ve acil durumlar bildirim verir. Diğer mesajlar Mesa\'da sessizce birikir; odak bitince kısa bir özet gelir.':
      'Durante o foco, só VIPs, mensagens que seguem a regra "Marcar como importante" e emergências notificam você. As outras se acumulam em silêncio no Mesa; ao terminar, chega um resumo.',
  'Otomatik yedek': 'Backup automático',
  'Otomatik yedek açıldı; ilk yedek şimdi alınıyor.':
      'Backup automático ativado; o primeiro está sendo feito agora.',
  'Panodan yapıştır': 'Colar da área de transferência',
  'Sabah 08:00\'e kadar': 'Até as 08:00 da manhã',
  'Seçtiğiniz klasöre düzenli olarak şifreli yedek alınır; en yeni 5 otomatik yedek saklanır. Otomatik çalışabilmesi için parola bu telefonda, telefonun güvenli donanım anahtarıyla şifrelenip saklanır.':
      'Backups criptografados são salvos regularmente na pasta escolhida; os 5 backups automáticos mais recentes são mantidos. Para funcionar sozinho, a senha fica guardada neste telefone, criptografada com a chave de hardware segura do telefone.',
  'Seçtiğiniz klasöre düzenli, şifreli yedek':
      'Backups criptografados regulares na pasta escolhida',
  'Sistemin VPN ayarlarında Mesa için "Her zaman açık VPN" ve "VPN olmadan bağlantıları engelle"yi açın.':
      'Nas configurações de VPN do sistema, ative "VPN sempre ativa" e "Bloquear conexões sem VPN" para o Mesa.',
  'Sohbet balonları': 'Bolhas de conversa',
  'Sohbet bulunamadı.': 'Conversa não encontrada.',
  'Sunucudan uzun süredir yanıt yok': 'O servidor não responde há um tempo',
  'Sunucunun adresi çözülemedi. İnternet bağlantınızı kontrol edin.':
      'Não foi possível resolver o endereço do servidor. Verifique sua conexão com a internet.',
  'Tam VPN (WireGuard)': 'VPN completa (WireGuard)',
  'Tünel açılamadı ({code}).': 'Não foi possível iniciar o túnel ({code}).',
  'VIP ekle': 'Adicionar VIP',
  'VIP kişiler': 'VIPs',
  'VIP kişiler dışında sessizlik; zamanlanabilir, bitince özet':
      'Silêncio exceto para VIPs; pode ser agendado, resumo ao terminar',
  'VIP kişiler odaktayken de size ulaşır: aile, yakın arkadaşlar, iş için önemli biri.':
      'Os VIPs conseguem falar com você mesmo no foco: família, amigos próximos, alguém importante do trabalho.',
  'WireGuard yapılandırması': 'Configuração do WireGuard',
  'WireGuard yapılandırması eklendi.': 'Configuração do WireGuard adicionada.',
  'Yalnızca VIP kişiler bildirim verir': 'Só VIPs notificam você',
  'Yapılandırma dosyasını kendi sunucunuzdan ya da WireGuard dosyası veren bir sağlayıcıdan (ör. Proton VPN\'in ücretsiz planı) alabilirsiniz.':
      'Você pode obter o arquivo de configuração do seu próprio servidor ou de um provedor que ofereça arquivos WireGuard (por exemplo, o plano gratuito do Proton VPN).',
  'Yapılandırma okunamadı. Dosyanın bir WireGuard (.conf) dosyası olduğundan emin olun.':
      'Não foi possível ler a configuração. Verifique se o arquivo é um arquivo WireGuard (.conf).',
  'Yapılandırmada sunucu ([Peer]) yok.':
      'A configuração não tem servidor ([Peer]).',
  'Yedek yazılamadı; yer kalmamış olabilir.':
      'Não foi possível gravar o backup; o armazenamento pode estar cheio.',
  'Zamanlama': 'Agendamento',
  'son: {when}': 'último: {when}',
  'yalnızca bazı adresler': 'só alguns endereços',
  '{count, plural, one{# mesaj susturuldu} other{# mesaj susturuldu}}':
      '{count, plural, one{# mensagem silenciada} other{# mensagens silenciadas}}',
  'Çıkar': 'Remover',
  'İçe aktar': 'Importar',
  'Şimdi yedekle': 'Fazer backup agora',
  '↓ {rx} · ↑ {tx}': '↓ {rx} · ↑ {tx}',
  // 1.2.1: WhatsApp'ta yazılan yanıtlar
  'Ayarı aç': 'Abrir configuração',
  'WhatsApp\'ta yazdıklarım': 'O que escrevo no WhatsApp',
  'WhatsApp\'ta yazdıklarınız da görünsün':
      'Mostrar também o que você escreve no WhatsApp',
  'WhatsApp\'tan yazdığınız yanıtlar burada görünmüyor. Görünsün mü?':
      'As respostas que você escreve no WhatsApp não aparecem aqui. Mostrar?',
  // 1.2.1: otomatik gönderim
  'Bu servis şunları yapar:\n• WhatsApp\'ta açık sohbete gelen ve sizin yazdığınız yeni mesajlar Mesa\'daki aynı sohbete eklenir; sohbet Mesa\'da yoksa açılır.\n• WhatsApp\'ta açtığınız sohbet burada da okunmuş sayılır.\n• Mesa\'dan yazdığınız mesaj, Mesa\'dan çıkmadan WhatsApp üzerinden gönderilir.\n\nAçılan sayfada "İndirilen uygulamalar"a girip "Mesa: WhatsApp yanıtlarım"ı açın. Yalnızca WhatsApp okunur ve hiçbir şey telefondan çıkmaz.\n\nAyar soluk görünüyorsa: Uygulama bilgisi → ⋮ → Kısıtlanmış ayarlara izin ver.':
      'Este serviço:\n• Adiciona à mesma conversa no Mesa as mensagens novas da conversa do WhatsApp que você tem aberta, recebidas e escritas por você, e cria a conversa no Mesa se ela não existir.\n• Marca aqui como lidas as conversas que você abre no WhatsApp.\n• Envia pelo WhatsApp as mensagens que você escreve no Mesa sem sair do Mesa.\n\nNa próxima página, abra "Apps baixados" e ative "Mesa: minhas respostas do WhatsApp". Só o WhatsApp é lido e nada sai do seu telefone.\n\nSe a opção estiver esmaecida: Informações do app → ⋮ → Permitir configurações restritas.',
  'WhatsApp\'ta yazdıklarınız ve orada açıkken gelenler de Mesa\'da görünür; Mesa\'dan yazdıklarınız WhatsApp\'ta kendiliğinden gönderilir':
      'O que você escreve no WhatsApp e o que chega enquanto uma conversa está aberta lá também aparece no Mesa; as mensagens que você escreve no Mesa são enviadas sozinhas no WhatsApp',
  'Mesajınız {name} üzerinden, Mesa\'dan çıkmadan gönderilir.':
      'Sua mensagem é enviada pelo {name} sem sair do Mesa.',
  'Otomatik gönder': 'Envio automático',
  'WhatsApp\'ta gönderilemedi; mesajınız yazma alanında.':
      'Não foi possível enviar no WhatsApp; sua mensagem está na caixa de texto.',
  // Mesajdan işe tek dokunuş
  'Açılamadı.': 'Não foi possível abrir.',
  'Bağlantıyı aç': 'Abrir link',
  'E-postayı kopyala': 'Copiar e-mail',
  'Haritada aç': 'Abrir no mapa',
  'Hatırlat': 'Lembrar',
  'Hatırlatma kurulamadı.': 'Não foi possível criar o lembrete.',
  'IBAN\'ı kopyala': 'Copiar IBAN',
  'Kodu kopyala': 'Copiar código',
  'Kopyalandı': 'Copiado',
  'Takvim uygulaması bulunamadı.': 'Nenhum app de calendário encontrado.',
  'Takvime ekle': 'Adicionar à agenda',
  'Telefonla ara': 'Ligar',
  '{time} için hatırlatma kuruldu': 'Lembrete criado para {time}',
  // Sesli mesajı yazıya çevirme
  'Başka bir sesli mesaj çevriliyor; az sonra yeniden deneyin.':
      'Outra mensagem de voz está sendo transcrita; tente de novo daqui a pouco.',
  'Bu dilin konuşma paketi indiriliyor; biraz sonra yeniden deneyin.':
      'O pacote de fala deste idioma está sendo baixado; tente de novo em breve.',
  'Bu sesli mesajın dosyası telefonda bulunamadı. WhatsApp\'ta bir kez açıp indirin, sonra yeniden deneyin.':
      'O arquivo desta mensagem de voz não está no telefone. Abra-a uma vez no WhatsApp para baixar e tente de novo.',
  'Bu telefon sesli mesajı yazıya çeviremiyor (Android 13 gerekli).':
      'Este telefone não consegue transcrever mensagens de voz (requer Android 13).',
  'Bu, WhatsApp\'ın sesli mesaj klasörü değil. "WhatsApp Voice Notes" klasörünü seçin.':
      'Essa não é a pasta de mensagens de voz do WhatsApp. Escolha a pasta "WhatsApp Voice Notes".',
  'Klasörü seç': 'Escolher pasta',
  'Sesli mesaj yazıya çevrilemedi.':
      'Não foi possível transcrever a mensagem de voz.',
  'Sesli mesajda anlaşılır konuşma bulunamadı.':
      'Nenhuma fala clara encontrada na mensagem de voz.',
  'WhatsApp ses klasörü seçilmedi.':
      'A pasta de voz do WhatsApp não foi escolhida.',
  'WhatsApp sesli mesajları': 'Mensagens de voz do WhatsApp',
  'WhatsApp sesli mesajları bildirime koymuyor, telefondaki kendi klasöründe saklıyor. Yazıya çevirmek için Mesa\'nın o klasörü okuması gerekiyor.\n\nAçılan sayfada "Bu klasörü kullan"a, sonra "İzin ver"e dokunun. Ses telefondan çıkmaz; yazıya çevirme telefonda yapılır.':
      'O WhatsApp não coloca mensagens de voz nas notificações; ele as guarda na própria pasta no telefone. Para transcrevê-las, o Mesa precisa ler essa pasta.\n\nNa próxima página, toque em "Usar esta pasta" e depois em "Permitir". O áudio não sai do seu telefone; a transcrição é feita no telefone.',
  'Yazıya çevir': 'Transcrever',
  'Yazıya çevirmek için Android mikrofon izni istiyor; mikrofon kullanılmaz.':
      'O Android pede permissão de microfone para transcrever; o microfone não é usado.',
  'Yazıya çevrildi': 'Transcrito',
  'Yazıya çevriliyor…': 'Transcrevendo…',
  // Mesaj çevirisi
  'Başka dildeki mesajlar bu paketlerle telefonda çevrilir; mesajlar hiçbir yere gönderilmez. Sildiğiniz paket gerekince yeniden sorulur.': 'Mensagens em outros idiomas são traduzidas no telefone com estes pacotes; as mensagens não são enviadas a lugar nenhum. Um pacote excluído é oferecido de novo quando for necessário.',
  'Başka dildeki mesajlar telefonda çevrilir; indirilen paketler burada': 'Mensagens em outros idiomas são traduzidas no telefone; os pacotes baixados ficam aqui',
  'Bu dil ({language}) telefonda çevrilemiyor.': 'Este idioma ({language}) não pode ser traduzido no telefone.',
  'Bu mesaj zaten sizin dilinizde.': 'Esta mensagem já está no seu idioma.',
  'Bu mesajda çevrilecek yazı yok.': 'Esta mensagem não tem texto para traduzir.',
  'Dil paketi indirilemedi. İnternet bağlantınızı kontrol edip yeniden deneyin.': 'Não foi possível baixar o pacote de idioma. Verifique sua conexão com a internet e tente de novo.',
  'Dil paketi indiriliyor…': 'Baixando pacote de idioma…',
  'Dil paketi silinemedi.': 'Não foi possível excluir o pacote de idioma.',
  'Dil paketleri indirilsin mi?': 'Baixar pacotes de idioma?',
  'Henüz dil paketi indirilmedi. Bir mesajın altındaki "Çevir"e dokununca gereken paket sorulur.': 'Nenhum pacote de idioma baixado ainda. Ao tocar em "Traduzir" abaixo de uma mensagem, o pacote necessário será oferecido.',
  'Mesaj çevrilemedi.': 'Não foi possível traduzir a mensagem.',
  'Mesajın dili anlaşılamadı.': 'Não foi possível identificar o idioma da mensagem.',
  'Telefonda çevrilir; mesaj hiçbir yere gönderilmez': 'Traduzido no telefone; a mensagem não é enviada a lugar nenhum',
  '{language} dil paketi indirilsin mi?': 'Baixar o pacote de {language}?',
  'Çevir': 'Traduzir',
  'Çeviri': 'Tradução',
  'Çeviri dil paketleri': 'Pacotes de idioma para tradução',
  'Çeviri telefonda yapılır; mesajlarınız hiçbir yere gönderilmez. Bunun için Google\'ın çeviri paketi bir kez indirilir (dil başına yaklaşık 30 MB), sonra internetsiz çalışır.': 'A tradução é feita no telefone; suas mensagens não são enviadas a lugar nenhum. Para isso, o pacote de tradução do Google é baixado uma vez (cerca de 30 MB por idioma) e depois funciona sem internet.',
  'Çeviri · aslı {language}': 'Traduzido do {language}',
  'Çeviriyi gizle': 'Ocultar tradução',
  'Çevriliyor…': 'Traduzindo…',
  'İndir ve çevir': 'Baixar e traduzir',
  'İndirilecek: {languages}': 'Será baixado: {languages}',
  // Yapay zekâ asistanı
  'API anahtarı': 'Chave de API',
  'Anahtar girilmedi': 'Nenhuma chave inserida',
  'Anahtar kaydedildi; asistan hazır.': 'Chave salva; o assistente está pronto.',
  'Anahtar kaydedildi; internet olmadığı için doğrulanamadı.': 'Chave salva; não foi possível verificá-la porque não há internet.',
  'Anahtar kaydedilemedi.': 'Não foi possível salvar a chave.',
  'Anahtar kayıtlı': 'Chave salva',
  'Anahtar nasıl alınır?': 'Como obter uma chave?',
  'Anahtar silinsin mi?': 'Excluir a chave?',
  'Anahtarı değiştir': 'Alterar chave',
  'Anahtarı gir': 'Inserir chave',
  'Anahtarı sil': 'Excluir chave',
  'Anthropic bu anahtarı kabul etmedi. Doğru kopyaladığınızdan emin olun.': 'A Anthropic não aceitou esta chave. Verifique se você a copiou corretamente.',
  'Anthropic hesabınızda kredi kalmadı ya da harcama sınırına ulaşıldı. console.anthropic.com\'dan bakabilirsiniz.': 'Sua conta da Anthropic ficou sem crédito ou atingiu o limite de gastos. Você pode verificar em console.anthropic.com.',
  'Anthropic, API ile gönderilen verileri yapay zekâsını eğitmek için kullanmadığını belirtiyor. Ücret, kullandıkça Anthropic hesabınızdaki krediden düşer.': 'A Anthropic afirma que não usa os dados enviados pela API para treinar sua IA. O custo é descontado do crédito da sua conta da Anthropic conforme o uso.',
  'Asistan yanıt veremedi; yeniden deneyin.': 'O assistente não conseguiu responder; tente de novo.',
  'Asistan, yeniden anahtar girene kadar çalışmaz. Anahtar Anthropic hesabınızda kalır; tamamen iptal etmek için console.anthropic.com\'dan silin.': 'O assistente não funcionará até você inserir uma chave de novo. A chave continua na sua conta da Anthropic; para revogá-la totalmente, exclua-a em console.anthropic.com.',
  'Bu API anahtarının bu işe izni yok.': 'Esta chave de API não tem permissão para isso.',
  'Bu bir Claude API anahtarına benzemiyor; anahtarlar "sk-ant-" ile başlar.': 'Isto não parece uma chave de API do Claude; as chaves começam com "sk-ant-".',
  'Claude API anahtarı': 'Chave de API do Claude',
  'Claude API anahtarı geçersiz ya da silinmiş. Ayarlar\'dan yeniden girin.': 'A chave de API do Claude é inválida ou foi excluída. Insira-a de novo em Configurações.',
  'Claude bu isteği yanıtlamadı.': 'O Claude não respondeu a este pedido.',
  'Claude düşünüyor…': 'O Claude está pensando…',
  'Claude ile düzelt': 'Melhorar com o Claude',
  'Claude ile sohbet özeti, sohbete soru, yanıt önerisi ve mesaj düzeltme': 'Resumos de conversas, perguntas sobre uma conversa, sugestões de resposta e correção de mensagens com o Claude',
  'Claude şu an çok yoğun; biraz sonra yeniden deneyin.': 'O Claude está muito ocupado agora; tente de novo daqui a pouco.',
  'Claude\'a ulaşılamadı. İnternet bağlantınızı kontrol edin.': 'Não foi possível falar com o Claude. Verifique sua conexão com a internet.',
  'Daha kibar yap': 'Deixar mais educado',
  'Daha kısa yap': 'Deixar mais curto',
  'Dengeli · uzun bir özet yaklaşık 1,5 sent': 'Equilibrado · um resumo longo custa cerca de 1,5 centavo',
  'Dil, sohbetin son mesajlarından anlaşılır; onlar da gönderilir.': 'O idioma é deduzido das últimas mensagens da conversa, que também são enviadas.',
  'Düzeltiliyor…': 'Melhorando…',
  'En akıllısı · uzun bir özet yaklaşık 3 sent': 'O mais inteligente · um resumo longo custa cerca de 3 centavos',
  'En hızlısı ve en ucuzu · uzun bir özet 0,1 sentten az': 'O mais rápido e barato · um resumo longo custa menos de 0,1 centavo',
  'Karşı tarafın diline çevir': 'Traduzir para o idioma da outra pessoa',
  'Kullan': 'Usar',
  'Model': 'Modelo',
  'Ne gönderilir?': 'O que é enviado?',
  'Seçili model hesabınızda kullanılamıyor; Ayarlar\'dan başka bir model seçin.': 'O modelo selecionado não está disponível na sua conta; escolha outro em Configurações.',
  'Sohbet asistana gönderilemeyecek kadar uzun.': 'A conversa é longa demais para enviar ao assistente.',
  'Sohbete sor': 'Perguntar sobre a conversa',
  'Sohbetleri özetler, sohbete sorduğunuz soruyu yanıtlar, yanıt önerir ve yazdığınızı düzeltir. Anthropic\'in yapay zekâsı Claude ile, sizin API anahtarınızla çalışır.': 'Resume conversas, responde às suas perguntas sobre uma conversa, sugere respostas e melhora o que você escreve. Usa a IA da Anthropic, o Claude, com sua própria chave de API.',
  'Sor': 'Perguntar',
  'Telefonda şifreli saklanır; Mesa\'nın yedeklerine girmez.': 'Fica criptografada no telefone; não entra nos backups do Mesa.',
  'Verileriniz ve ücret': 'Seus dados e o custo',
  'Yalnızca siz dokununca': 'Só quando você toca',
  'Yanıt öner': 'Sugerir respostas',
  'Yapay zekâ': 'IA',
  'Yapay zekâ asistanı': 'Assistente de IA',
  'Yapıştır': 'Colar',
  'Yazdığınız metin Claude\'a gönderilir; siz onaylamadan değişmez.': 'O que você escreveu é enviado ao Claude; nada muda até você aprovar.',
  'Yazım hatalarını düzelt': 'Corrigir erros de escrita',
  'Yeniden dene': 'Tentar de novo',
  'console.anthropic.com\'da hesap açın, kredi yükleyin, "API Keys" bölümünden bir anahtar oluşturup buraya yapıştırın. Anahtarı kimseyle paylaşmayın.': 'Crie uma conta em console.anthropic.com, adicione crédito, crie uma chave em "API Keys" e cole aqui. Não compartilhe a chave com ninguém.',
  '{model} · Yapay zekâ yanılabilir': '{model} · A IA pode errar',
  '{title} sohbetinin özeti': 'Resumo da conversa: {title}',
  'Çok sık istek gönderildi; biraz bekleyip yeniden deneyin.': 'Pedidos demais; aguarde um pouco e tente de novo.',
  'Önce Ayarlar → Yapay zekâ asistanı bölümünden Claude API anahtarınızı girin.': 'Primeiro insira sua chave de API do Claude em Configurações → Assistente de IA.',
  'Önerilen metin': 'Texto sugerido',
  'Öneriler hazırlanıyor…': 'Preparando sugestões…',
  'Önerileri kapat': 'Fechar sugestões',
  'Örn. Ne zaman buluşuyorduk?': 'Ex.: Quando íamos nos encontrar?',
  'Özet ve soruda sohbetin son mesajları, yanıt önerisinde son 30 mesaj, düzeltmede yalnızca yazdığınız metin (çeviride son 10 mesaj da) gönderen adlarıyla Anthropic\'e gider. Kendiliğinden hiçbir şey gönderilmez; asistan sizin yerinize mesaj atmaz.': 'Nos resumos e perguntas, as mensagens recentes da conversa; nas sugestões, as últimas 30 mensagens; na correção, só o que você escreveu (e as últimas 10 mensagens ao traduzir) vão para a Anthropic com os nomes dos remetentes. Nada é enviado sozinho e o assistente nunca envia mensagens por você.',
  'Özetle': 'Resumir',
};
