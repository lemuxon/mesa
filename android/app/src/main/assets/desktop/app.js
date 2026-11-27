// Bilgisayardan Mesa: tarayıcı tarafı. Telefondaki Mesa'nın yerel HTTPS
// sunucusuyla konuşur; oturum anahtarı yalnızca bu tarayıcıda saklanır.
'use strict';

(() => {
  const STRINGS = {
    tr: {
      title: 'Bilgisayardan Mesa',
      intro: "Telefonunuzdaki Mesa'ya bağlanmak için Bağlan'a tıklayın; telefonunuzda bir bildirim çıkacak.",
      connect: 'Bağlan',
      note: 'Bağlantı şifrelidir ve internete çıkmaz: mesajlar yalnızca telefonla bu bilgisayar arasında gider.',
      waiting: 'Telefonunuzdaki bildirimde bu kodu görüyorsanız "İzin ver"e dokunun.',
      denied: 'Bağlantı telefondan reddedildi.',
      expired: 'Süre doldu; yeniden deneyin.',
      busy: 'Çok sık denendi; biraz bekleyip yeniden deneyin.',
      offline: "Telefona ulaşılamıyor. Mesa'da Bilgisayardan Mesa açık mı, bilgisayar aynı Wi-Fi'de mi?",
      retry: 'Yeniden dene',
      search: 'Sohbet ara',
      logout: 'Çıkış yap',
      pick: 'Soldan bir sohbet seçin.',
      send: 'Gönder',
      placeholder: 'Mesaj yaz',
      noReply: 'Bu sohbete şu an bilgisayardan yanıt verilemiyor. Karşı taraftan yeni bir mesaj gelince yanıtlayabilirsiniz ya da telefondan yanıtlayın.',
      sendFailed: 'Gönderilemedi.',
      deleted: 'silindi',
      failedLabel: 'gönderilemedi',
      today: 'Bugün',
      yesterday: 'Dün',
      noChats: 'Henüz sohbet yok.',
      noMatch: 'Eşleşen sohbet yok.',
      reconnecting: 'Telefonla bağlantı koptu; yeniden bağlanılıyor…',
      back: 'Geri',
    },
    en: {
      title: 'Mesa on computer',
      intro: 'Click Connect to link this browser to Mesa on your phone; a notification will appear on your phone.',
      connect: 'Connect',
      note: 'The connection is encrypted and never goes to the internet: messages only travel between your phone and this computer.',
      waiting: "If your phone's notification shows this code, tap \"Allow\".",
      denied: 'The connection was denied on the phone.',
      expired: 'Time ran out; try again.',
      busy: 'Too many attempts; wait a moment and try again.',
      offline: "Can't reach the phone. Is Mesa on computer turned on in Mesa, and is this computer on the same Wi-Fi?",
      retry: 'Try again',
      search: 'Search chats',
      logout: 'Sign out',
      pick: 'Pick a chat on the left.',
      send: 'Send',
      placeholder: 'Type a message',
      noReply: "You can't reply to this chat from the computer right now. You can reply once a new message arrives from them, or reply on your phone.",
      sendFailed: "Couldn't send.",
      deleted: 'deleted',
      failedLabel: 'not sent',
      today: 'Today',
      yesterday: 'Yesterday',
      noChats: 'No chats yet.',
      noMatch: 'No matching chats.',
      reconnecting: 'Lost the connection to the phone; reconnecting…',
      back: 'Back',
    },
    es: {
      title: 'Mesa en el ordenador',
      intro: 'Haz clic en Conectar para vincular este navegador con Mesa en tu teléfono; aparecerá una notificación en el teléfono.',
      connect: 'Conectar',
      note: 'La conexión está cifrada y no sale a internet: los mensajes solo viajan entre tu teléfono y este ordenador.',
      waiting: 'Si la notificación del teléfono muestra este código, toca "Permitir".',
      denied: 'La conexión se rechazó en el teléfono.',
      expired: 'Se acabó el tiempo; inténtalo de nuevo.',
      busy: 'Demasiados intentos; espera un momento e inténtalo de nuevo.',
      offline: 'No se puede conectar con el teléfono. ¿Está activado Mesa en el ordenador en Mesa y está este ordenador en la misma Wi-Fi?',
      retry: 'Reintentar',
      search: 'Buscar chats',
      logout: 'Cerrar sesión',
      pick: 'Elige un chat a la izquierda.',
      send: 'Enviar',
      placeholder: 'Escribe un mensaje',
      noReply: 'Ahora no puedes responder a este chat desde el ordenador. Podrás hacerlo cuando llegue un mensaje nuevo, o responde desde el teléfono.',
      sendFailed: 'No se pudo enviar.',
      deleted: 'eliminado',
      failedLabel: 'no enviado',
      today: 'Hoy',
      yesterday: 'Ayer',
      noChats: 'Aún no hay chats.',
      noMatch: 'No hay chats que coincidan.',
      reconnecting: 'Se perdió la conexión con el teléfono; reconectando…',
      back: 'Atrás',
    },
    pt: {
      title: 'Mesa no computador',
      intro: 'Clique em Conectar para vincular este navegador ao Mesa no seu telefone; uma notificação aparecerá no telefone.',
      connect: 'Conectar',
      note: 'A conexão é criptografada e não passa pela internet: as mensagens só trafegam entre seu telefone e este computador.',
      waiting: 'Se a notificação do telefone mostrar este código, toque em "Permitir".',
      denied: 'A conexão foi recusada no telefone.',
      expired: 'O tempo acabou; tente de novo.',
      busy: 'Tentativas demais; aguarde um pouco e tente de novo.',
      offline: 'Não foi possível alcançar o telefone. O Mesa no computador está ativado no Mesa e este computador está na mesma Wi-Fi?',
      retry: 'Tentar de novo',
      search: 'Buscar conversas',
      logout: 'Sair',
      pick: 'Escolha uma conversa à esquerda.',
      send: 'Enviar',
      placeholder: 'Digite uma mensagem',
      noReply: 'Não é possível responder a esta conversa pelo computador agora. Você poderá responder quando chegar uma nova mensagem, ou responda pelo telefone.',
      sendFailed: 'Não foi possível enviar.',
      deleted: 'apagada',
      failedLabel: 'não enviada',
      today: 'Hoje',
      yesterday: 'Ontem',
      noChats: 'Ainda não há conversas.',
      noMatch: 'Nenhuma conversa encontrada.',
      reconnecting: 'A conexão com o telefone caiu; reconectando…',
      back: 'Voltar',
    },
    de: {
      title: 'Mesa am Computer',
      intro: 'Klicke auf Verbinden, um diesen Browser mit Mesa auf deinem Telefon zu verbinden; auf dem Telefon erscheint eine Benachrichtigung.',
      connect: 'Verbinden',
      note: 'Die Verbindung ist verschlüsselt und läuft nicht übers Internet: Nachrichten gehen nur zwischen deinem Telefon und diesem Computer hin und her.',
      waiting: 'Wenn die Benachrichtigung auf dem Telefon diesen Code zeigt, tippe auf „Zulassen“.',
      denied: 'Die Verbindung wurde auf dem Telefon abgelehnt.',
      expired: 'Die Zeit ist abgelaufen; versuche es erneut.',
      busy: 'Zu viele Versuche; warte kurz und versuche es erneut.',
      offline: 'Das Telefon ist nicht erreichbar. Ist „Mesa am Computer“ in Mesa eingeschaltet und ist dieser Computer im selben WLAN?',
      retry: 'Erneut versuchen',
      search: 'Chats durchsuchen',
      logout: 'Abmelden',
      pick: 'Wähle links einen Chat.',
      send: 'Senden',
      placeholder: 'Nachricht schreiben',
      noReply: 'Auf diesen Chat kannst du gerade nicht vom Computer aus antworten. Sobald eine neue Nachricht kommt, geht es, oder antworte auf dem Telefon.',
      sendFailed: 'Senden fehlgeschlagen.',
      deleted: 'gelöscht',
      failedLabel: 'nicht gesendet',
      today: 'Heute',
      yesterday: 'Gestern',
      noChats: 'Noch keine Chats.',
      noMatch: 'Keine passenden Chats.',
      reconnecting: 'Verbindung zum Telefon verloren; verbinde neu…',
      back: 'Zurück',
    },
    fr: {
      title: "Mesa sur l'ordinateur",
      intro: 'Cliquez sur Connecter pour relier ce navigateur à Mesa sur votre téléphone ; une notification apparaîtra sur le téléphone.',
      connect: 'Connecter',
      note: "La connexion est chiffrée et ne passe pas par Internet : les messages ne circulent qu'entre votre téléphone et cet ordinateur.",
      waiting: 'Si la notification du téléphone affiche ce code, touchez « Autoriser ».',
      denied: 'La connexion a été refusée sur le téléphone.',
      expired: 'Le délai est écoulé ; réessayez.',
      busy: 'Trop de tentatives ; patientez un peu et réessayez.',
      offline: "Impossible de joindre le téléphone. « Mesa sur l'ordinateur » est-il activé dans Mesa et cet ordinateur est-il sur le même Wi-Fi ?",
      retry: 'Réessayer',
      search: 'Rechercher des discussions',
      logout: 'Se déconnecter',
      pick: 'Choisissez une discussion à gauche.',
      send: 'Envoyer',
      placeholder: 'Écrire un message',
      noReply: "Vous ne pouvez pas répondre à cette discussion depuis l'ordinateur pour le moment. Vous pourrez le faire dès qu'un nouveau message arrivera, ou répondez depuis le téléphone.",
      sendFailed: "Échec de l'envoi.",
      deleted: 'supprimé',
      failedLabel: 'non envoyé',
      today: "Aujourd'hui",
      yesterday: 'Hier',
      noChats: "Aucune discussion pour l'instant.",
      noMatch: 'Aucune discussion correspondante.',
      reconnecting: 'Connexion au téléphone perdue ; reconnexion…',
      back: 'Retour',
    },
    ar: {
      title: 'Mesa على الكمبيوتر',
      intro: 'انقر على اتصال لربط هذا المتصفح بتطبيق Mesa على هاتفك؛ سيظهر إشعار على الهاتف.',
      connect: 'اتصال',
      note: 'الاتصال مشفّر ولا يمر عبر الإنترنت: تنتقل الرسائل بين هاتفك وهذا الكمبيوتر فقط.',
      waiting: 'إذا ظهر هذا الرمز في إشعار الهاتف، فالمس "سماح".',
      denied: 'رُفض الاتصال على الهاتف.',
      expired: 'انتهت المهلة؛ حاول مجددًا.',
      busy: 'محاولات كثيرة جدًا؛ انتظر قليلًا ثم حاول مجددًا.',
      offline: 'تعذّر الوصول إلى الهاتف. هل ميزة Mesa على الكمبيوتر مفعّلة في Mesa، وهل هذا الكمبيوتر على شبكة Wi-Fi نفسها؟',
      retry: 'أعد المحاولة',
      search: 'ابحث في المحادثات',
      logout: 'تسجيل الخروج',
      pick: 'اختر محادثة من القائمة.',
      send: 'إرسال',
      placeholder: 'اكتب رسالة',
      noReply: 'لا يمكنك الرد على هذه المحادثة من الكمبيوتر الآن. يمكنك الرد عند وصول رسالة جديدة، أو الرد من الهاتف.',
      sendFailed: 'تعذّر الإرسال.',
      deleted: 'محذوفة',
      failedLabel: 'لم تُرسل',
      today: 'اليوم',
      yesterday: 'أمس',
      noChats: 'لا توجد محادثات بعد.',
      noMatch: 'لا توجد محادثات مطابقة.',
      reconnecting: 'انقطع الاتصال بالهاتف؛ جارٍ إعادة الاتصال…',
      back: 'رجوع',
    },
    ru: {
      title: 'Mesa на компьютере',
      intro: 'Нажмите «Подключить», чтобы связать этот браузер с Mesa на телефоне; на телефоне появится уведомление.',
      connect: 'Подключить',
      note: 'Соединение зашифровано и не идёт через интернет: сообщения передаются только между вашим телефоном и этим компьютером.',
      waiting: 'Если в уведомлении на телефоне этот же код, нажмите «Разрешить».',
      denied: 'Подключение отклонено на телефоне.',
      expired: 'Время вышло; попробуйте снова.',
      busy: 'Слишком много попыток; подождите немного и попробуйте снова.',
      offline: 'Не удаётся связаться с телефоном. Включена ли функция «Mesa на компьютере» в Mesa и подключён ли компьютер к той же сети Wi-Fi?',
      retry: 'Повторить',
      search: 'Поиск чатов',
      logout: 'Выйти',
      pick: 'Выберите чат слева.',
      send: 'Отправить',
      placeholder: 'Напишите сообщение',
      noReply: 'Сейчас нельзя ответить в этот чат с компьютера. Ответить можно будет, когда придёт новое сообщение, или ответьте с телефона.',
      sendFailed: 'Не удалось отправить.',
      deleted: 'удалено',
      failedLabel: 'не отправлено',
      today: 'Сегодня',
      yesterday: 'Вчера',
      noChats: 'Чатов пока нет.',
      noMatch: 'Нет подходящих чатов.',
      reconnecting: 'Связь с телефоном потеряна; переподключение…',
      back: 'Назад',
    },
  };

  const $ = (id) => document.getElementById(id);
  const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
  let lang = (navigator.language || 'en').slice(0, 2);
  if (!STRINGS[lang]) lang = 'en';
  const t = (key) => STRINGS[lang][key] || STRINGS.en[key] || key;

  let token = null;
  try {
    token = localStorage.getItem('mesa_token');
  } catch (e) {
    token = null;
  }
  let conversations = [];
  let current = null;
  const avatars = new Map();
  const images = new Map();

  function el(tag, className, text) {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (text !== undefined) node.textContent = text;
    return node;
  }

  function applyTexts() {
    document.documentElement.lang = lang;
    document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';
    document.title = 'Mesa';
    document.querySelectorAll('[data-t]').forEach((node) => {
      node.textContent = t(node.dataset.t);
    });
    $('search').placeholder = t('search');
    $('input').placeholder = t('placeholder');
    for (const [id, key] of [['logout', 'logout'], ['back', 'back']]) {
      $(id).title = t(key);
      $(id).setAttribute('aria-label', t(key));
    }
  }

  let toastTimer = 0;
  function toast(text) {
    const box = $('toast');
    box.textContent = text;
    box.hidden = false;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => { box.hidden = true; }, 5000);
  }

  async function api(path, options = {}) {
    const headers = {};
    if (token) headers.Authorization = 'Bearer ' + token;
    if (options.body !== undefined) headers['Content-Type'] = 'application/json';
    const response = await fetch(path, {
      method: options.method || 'GET',
      headers,
      body: options.body === undefined ? undefined : JSON.stringify(options.body),
      cache: 'no-store',
    });
    if (response.status === 401 && token) {
      signOut(false);
      throw new Error('unauthorized');
    }
    return response;
  }

  // ---- Eşleştirme ----

  function showPair() {
    $('app').hidden = true;
    $('pair').hidden = false;
    $('pair-code').hidden = true;
    $('pair-status').textContent = '';
    $('pair-start').hidden = false;
    $('pair-start').textContent = t('connect');
  }

  function pairFailed(key) {
    $('pair-code').hidden = true;
    $('pair-status').textContent = t(key);
    $('pair-start').hidden = false;
    $('pair-start').textContent = t('retry');
  }

  async function startPairing() {
    $('pair-start').hidden = true;
    $('pair-status').textContent = '';
    let response;
    try {
      response = await fetch('/api/pair', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: '{}',
        cache: 'no-store',
      });
    } catch (e) {
      pairFailed('offline');
      return;
    }
    if (response.status === 429) {
      pairFailed('busy');
      return;
    }
    if (!response.ok) {
      pairFailed('offline');
      return;
    }
    const pairing = await response.json();
    $('pair-code').textContent = pairing.code;
    $('pair-code').hidden = false;
    $('pair-status').textContent = t('waiting');
    const started = Date.now();
    while (Date.now() - started < 120000) {
      await sleep(1500);
      let state;
      try {
        const res = await fetch('/api/pair/status?id=' + encodeURIComponent(pairing.id), { cache: 'no-store' });
        if (res.status === 404) {
          pairFailed('expired');
          return;
        }
        state = await res.json();
      } catch (e) {
        continue;
      }
      if (state.state === 'approved') {
        token = state.token;
        try {
          localStorage.setItem('mesa_token', token);
        } catch (e) {
          // Gizli pencere: oturum yalnızca bu sekmede sürer.
        }
        enterApp();
        return;
      }
      if (state.state === 'denied') {
        pairFailed('denied');
        return;
      }
    }
    pairFailed('expired');
  }

  async function signOut(tellPhone) {
    if (tellPhone) {
      try {
        await api('/api/logout', { method: 'POST', body: {} });
      } catch (e) {
        // Telefon kapalıysa da bu tarayıcıdaki anahtar silinir.
      }
    }
    token = null;
    try {
      localStorage.removeItem('mesa_token');
    } catch (e) {
      // Yok sayılır.
    }
    current = null;
    showPair();
  }

  // ---- Sohbetler ----

  async function enterApp() {
    let response;
    try {
      response = await api('/api/session');
    } catch (e) {
      if (token) toast(t('offline'));
      showPair();
      return;
    }
    if (!response.ok) {
      showPair();
      return;
    }
    const session = await response.json();
    if (STRINGS[session.language]) {
      lang = session.language;
      applyTexts();
    }
    $('pair').hidden = true;
    $('app').hidden = false;
    await loadList();
    listen();
  }

  async function loadList() {
    try {
      const response = await api('/api/conversations');
      if (!response.ok) return;
      conversations = await response.json();
      renderList();
    } catch (e) {
      // Bağlantı koptu; canlı akış yeniden bağlanınca yenilenir.
    }
  }

  let listTimer = 0;
  function refreshListSoon() {
    clearTimeout(listTimer);
    listTimer = setTimeout(loadList, 300);
  }

  function initials(name) {
    const parts = (name || '?').trim().split(/\s+/).filter(Boolean);
    return parts.slice(0, 2).map((part) => Array.from(part)[0]).join('').toLocaleUpperCase(lang) || '?';
  }

  function blobUrl(cache, key, path) {
    if (!cache.has(key)) {
      cache.set(key, api(path)
        .then((response) => (response.ok ? response.blob() : null))
        .then((blob) => (blob ? URL.createObjectURL(blob) : null))
        .catch(() => null));
    }
    return cache.get(key);
  }

  function avatar(conversation) {
    const box = el('div', 'avatar', initials(conversation.title));
    box.style.background = conversation.color || '';
    if (conversation.hasAvatar) {
      blobUrl(avatars, conversation.key, '/api/avatar?key=' + encodeURIComponent(conversation.key)).then((url) => {
        if (!url) return;
        const img = new Image();
        img.alt = '';
        img.src = url;
        box.replaceChildren(img);
      });
    }
    return box;
  }

  const sameDay = (a, b) => a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
  const timeLabel = (ms) => new Intl.DateTimeFormat(lang, { hour: '2-digit', minute: '2-digit' }).format(new Date(ms));

  function listTime(ms) {
    const date = new Date(ms);
    if (sameDay(date, new Date())) return timeLabel(ms);
    return new Intl.DateTimeFormat(lang, { day: 'numeric', month: 'short' }).format(date);
  }

  function dayLabel(ms) {
    const date = new Date(ms);
    const now = new Date();
    if (sameDay(date, now)) return t('today');
    const yesterday = new Date(now);
    yesterday.setDate(now.getDate() - 1);
    if (sameDay(date, yesterday)) return t('yesterday');
    const options = { day: 'numeric', month: 'long' };
    if (date.getFullYear() !== now.getFullYear()) options.year = 'numeric';
    return new Intl.DateTimeFormat(lang, options).format(date);
  }

  function renderList() {
    const query = $('search').value.trim().toLocaleLowerCase(lang);
    const list = $('list');
    list.replaceChildren();
    const shown = conversations.filter((c) => !query
      || (c.title || '').toLocaleLowerCase(lang).includes(query)
      || (c.lastText || '').toLocaleLowerCase(lang).includes(query));
    if (!shown.length) list.append(el('li', 'list-empty', t(conversations.length ? 'noMatch' : 'noChats')));
    for (const c of shown) {
      const item = el('li', 'item' + (c.key === current ? ' active' : '') + (c.unread ? ' unread' : ''));
      item.tabIndex = 0;
      item.addEventListener('click', () => openChat(c.key));
      item.addEventListener('keydown', (event) => {
        if (event.key === 'Enter') openChat(c.key);
      });
      const body = el('div', 'item-body');
      const top = el('div', 'item-top');
      top.append(el('span', 'item-title', c.title || ''), el('span', 'item-time', c.lastTime ? listTime(c.lastTime) : ''));
      const bottom = el('div', 'item-bottom');
      const chip = el('span', 'app-chip', c.app || '');
      chip.style.background = c.color || '';
      bottom.append(chip, el('span', 'item-text', c.lastText || ''));
      if (c.unread) bottom.append(el('span', 'badge', String(c.unread)));
      body.append(top, bottom);
      item.append(avatar(c), body);
      list.append(item);
    }
    const total = conversations.reduce((sum, c) => sum + (c.unread || 0), 0);
    document.title = total ? '(' + total + ') Mesa' : 'Mesa';
  }

  // ---- Sohbet ----

  async function openChat(key) {
    current = key;
    $('app').classList.add('reading');
    renderList();
    $('empty').hidden = true;
    $('thread').hidden = false;
    const conversation = conversations.find((c) => c.key === key);
    if (conversation) {
      $('thread-title').textContent = conversation.title || '';
      $('thread-app').textContent = conversation.app || '';
      $('thread-avatar').replaceWith(Object.assign(avatar(conversation), { id: 'thread-avatar' }));
    }
    $('messages').replaceChildren();
    await loadMessages(true);
    if (conversation && conversation.unread) {
      conversation.unread = 0;
      renderList();
      api('/api/read', { method: 'POST', body: { key } }).catch(() => {});
    }
    $('input').focus();
  }

  /** Metindeki bağlantılar tıklanabilir (yalnızca http/https). */
  function textWithLinks(text) {
    const box = el('div', 'text');
    const pattern = /https?:\/\/[^\s<>"']+/g;
    let last = 0;
    for (const match of text.matchAll(pattern)) {
      box.append(text.slice(last, match.index));
      const link = el('a', '', match[0]);
      link.href = match[0];
      link.target = '_blank';
      link.rel = 'noopener noreferrer';
      box.append(link);
      last = match.index + match[0].length;
    }
    box.append(text.slice(last));
    return box;
  }

  async function loadMessages(scrollToEnd) {
    const key = current;
    let data;
    try {
      const response = await api('/api/messages?key=' + encodeURIComponent(key));
      if (!response.ok) return;
      data = await response.json();
    } catch (e) {
      return;
    }
    if (key !== current) return;
    const conversation = conversations.find((c) => c.key === key);
    const box = $('messages');
    const nearEnd = box.scrollHeight - box.scrollTop - box.clientHeight < 120;
    box.replaceChildren();
    let lastDay = '';
    for (const m of data.messages) {
      const day = dayLabel(m.time);
      if (day !== lastDay) {
        const divider = el('div', 'day');
        divider.append(el('span', '', day));
        box.append(divider);
        lastDay = day;
      }
      const row = el('div', 'msg ' + (m.outgoing ? 'out' : 'in') + (m.failed ? ' failed' : ''));
      const bubble = el('div', 'bubble');
      if (conversation && conversation.isGroup && !m.outgoing && m.sender) bubble.append(el('div', 'sender', m.sender));
      if (m.image) {
        const img = new Image();
        img.alt = '';
        img.className = 'photo';
        blobUrl(images, key + '|' + m.id, '/api/media?key=' + encodeURIComponent(key) + '&id=' + encodeURIComponent(m.id)).then((url) => {
          if (url) img.src = url;
        });
        bubble.append(img);
      }
      if (m.text) bubble.append(textWithLinks(m.text));
      if (m.transcript) bubble.append(el('div', 'transcript', m.transcript));
      let meta = timeLabel(m.time);
      if (m.deleted) meta += ' · ' + t('deleted');
      if (m.failed) meta += ' · ' + t('failedLabel');
      bubble.append(el('div', 'meta', meta));
      row.append(bubble);
      box.append(row);
    }
    $('composer').hidden = !data.canReply;
    $('no-reply').hidden = !!data.canReply;
    if (scrollToEnd || nearEnd) box.scrollTop = box.scrollHeight;
  }

  function autosize() {
    const input = $('input');
    input.style.height = 'auto';
    input.style.height = Math.min(input.scrollHeight + 2, 160) + 'px';
    // Kaydırma çubuğu yalnızca en uzun boya ulaşınca.
    input.style.overflowY = input.scrollHeight + 2 > 160 ? 'auto' : 'hidden';
  }

  async function send(event) {
    event.preventDefault();
    const text = $('input').value.trim();
    if (!text || !current) return;
    $('send').disabled = true;
    try {
      const response = await api('/api/send', { method: 'POST', body: { key: current, text } });
      if (response.ok) {
        $('input').value = '';
        autosize();
        await loadMessages(true);
      } else if (response.status === 409) {
        toast(t('noReply'));
        await loadMessages(false);
      } else {
        toast(t('sendFailed'));
      }
    } catch (e) {
      if (token) toast(t('sendFailed'));
    } finally {
      $('send').disabled = false;
      $('input').focus();
    }
  }

  // ---- Canlı güncellemeler (sunucu olayları, oturum anahtarıyla) ----

  let listening = false;
  async function listen() {
    if (listening) return;
    listening = true;
    while (token) {
      try {
        const response = await api('/api/events');
        if (!response.ok || !response.body) throw new Error('events');
        $('banner').hidden = true;
        await loadList();
        if (current) loadMessages(false);
        const reader = response.body.getReader();
        const decoder = new TextDecoder();
        let buffer = '';
        for (;;) {
          const { value, done } = await reader.read();
          if (done) break;
          buffer += decoder.decode(value, { stream: true });
          let end;
          while ((end = buffer.indexOf('\n\n')) >= 0) {
            onEvent(buffer.slice(0, end));
            buffer = buffer.slice(end + 2);
          }
        }
      } catch (e) {
        // Aşağıda yeniden denenir.
      }
      if (!token) break;
      $('banner').textContent = t('reconnecting');
      $('banner').hidden = false;
      await sleep(3000);
    }
    listening = false;
  }

  function onEvent(chunk) {
    const data = chunk.split('\n').filter((line) => line.startsWith('data:')).map((line) => line.slice(5).trim()).join('');
    if (!data) return;
    let key;
    try {
      key = JSON.parse(data).key;
    } catch (e) {
      return;
    }
    refreshListSoon();
    if (key === current) loadMessages(false);
  }

  // ---- Başlangıç ----

  async function boot() {
    try {
      const response = await fetch('/api/hello', { cache: 'no-store' });
      const hello = await response.json();
      if (STRINGS[hello.language]) lang = hello.language;
    } catch (e) {
      // Tarayıcının dili.
    }
    applyTexts();
    $('pair-start').addEventListener('click', startPairing);
    $('logout').addEventListener('click', () => signOut(true));
    $('back').addEventListener('click', () => {
      $('app').classList.remove('reading');
      current = null;
      renderList();
    });
    $('search').addEventListener('input', renderList);
    $('composer').addEventListener('submit', send);
    $('input').addEventListener('input', autosize);
    $('input').addEventListener('keydown', (event) => {
      if (event.key === 'Enter' && !event.shiftKey && !event.isComposing) {
        event.preventDefault();
        $('composer').requestSubmit();
      }
    });
    if (token) enterApp();
    else showPair();
  }

  boot();
})();
