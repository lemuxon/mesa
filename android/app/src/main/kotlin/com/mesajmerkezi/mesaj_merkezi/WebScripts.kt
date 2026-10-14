package com.mesajmerkezi.mesaj_merkezi

/**
 * Servis sayfalarına, sayfanın kendi betiklerinden önce eklenen kod.
 *
 * Android'in gömülü tarayıcısı web bildirimlerini desteklemez; siteler yeni
 * mesajda `new Notification(...)` çağırır ve hiçbir şey olmaz. Buradaki
 * Notification sınıfı izin verilmiş gibi davranır ve bildirimi
 * `MesajMerkezi` köprüsüyle uygulamaya iletir (Ferdium da aynı yolu izler).
 * Köprü yalnızca servisin kendi kökenlerinde tanımlıdır (WebCatalog.originRules).
 */
object WebScripts {

    const val BRIDGE = "MesajMerkezi"

    val notificationShim = """
(function () {
  if (window.__mmShim) return;
  window.__mmShim = true;
  var bridge = window.$BRIDGE;
  function post(o) { try { bridge.postMessage(JSON.stringify(o)); } catch (e) {} }
  function str(v) { return v == null ? '' : String(v); }
  var shown = {};
  var order = [];
  var seq = 0;
  function remember(n) {
    shown[n._id] = n;
    order.push(n._id);
    while (order.length > 50) delete shown[order.shift()];
  }
  function MMNotification(title, options) {
    options = options || {};
    this.title = str(title);
    this.body = str(options.body);
    this.tag = str(options.tag);
    this.icon = str(options.icon);
    this.data = options.data;
    this.onclick = null; this.onshow = null; this.onclose = null; this.onerror = null;
    this._id = 'n' + (++seq) + '-' + Date.now();
    this._listeners = {};
    remember(this);
    post({ type: 'notification', id: this._id, title: this.title, body: this.body, tag: this.tag });
    var self = this;
    setTimeout(function () { self._fire('show'); }, 0);
  }
  MMNotification.permission = 'granted';
  MMNotification.maxActions = 0;
  MMNotification.requestPermission = function (cb) {
    if (typeof cb === 'function') { try { cb('granted'); } catch (e) {} }
    return Promise.resolve('granted');
  };
  MMNotification.prototype.close = function () { this._fire('close'); };
  MMNotification.prototype.addEventListener = function (type, fn) {
    (this._listeners[type] = this._listeners[type] || []).push(fn);
  };
  MMNotification.prototype.removeEventListener = function (type, fn) {
    var l = this._listeners[type] || [];
    var i = l.indexOf(fn);
    if (i >= 0) l.splice(i, 1);
  };
  MMNotification.prototype._fire = function (type) {
    var ev = { type: type, target: this, currentTarget: this, preventDefault: function () {} };
    var handler = this['on' + type];
    if (typeof handler === 'function') { try { handler.call(this, ev); } catch (e) {} }
    (this._listeners[type] || []).slice().forEach(function (fn) {
      try { fn.call(this, ev); } catch (e) {}
    }, this);
  };
  try {
    Object.defineProperty(window, 'Notification', { value: MMNotification, writable: true, configurable: true });
  } catch (e) { window.Notification = MMNotification; }

  if (navigator.permissions && navigator.permissions.query) {
    var query = navigator.permissions.query.bind(navigator.permissions);
    navigator.permissions.query = function (d) {
      if (d && (d.name === 'notifications' || d.name === 'push')) {
        return Promise.resolve({ state: 'granted', status: 'granted', onchange: null,
          addEventListener: function () {}, removeEventListener: function () {} });
      }
      return query(d);
    };
  }
  if (window.ServiceWorkerRegistration && ServiceWorkerRegistration.prototype) {
    ServiceWorkerRegistration.prototype.showNotification = function (title, options) {
      new MMNotification(title, options);
      return Promise.resolve();
    };
  }
  // Tanılama: betik bu sayfada çalıştı (yalnızca ana çerçeve, içerik yok).
  if (window.top === window) {
    var ready = function () { post({ type: 'ready', permission: MMNotification.permission }); };
    if (document.readyState === 'complete') ready(); else window.addEventListener('load', ready);
  }
  // Uygulamadaki bildirime dokununca sitenin kendi tıklama işleyicisi çalışır
  // (genelde ilgili sohbeti açar).
  window.__mmClick = function (id) {
    var n = shown[id];
    if (!n) return false;
    try { window.focus(); } catch (e) {}
    n._fire('click');
    return true;
  };
})();
""".trimIndent()

    /**
     * Sitenin en büyük simgesini (web uygulaması bildirgesi ya da
     * apple-touch-icon) bulup bildirir; uygulama onu indirir. SVG atlanır
     * (Android çözemez), "maskable" simgeler kenarları kırpıldığı için seçilmez.
     */
    val iconFinder = """
(function () {
  if (window.__mmIcons || window.top !== window) return;
  window.__mmIcons = true;
  var bridge = window.$BRIDGE;
  function post(o) { try { bridge.postMessage(JSON.stringify(o)); } catch (e) {} }
  function sizeOf(v) { var m = /(\d+)x(\d+)/.exec(v || ''); return m ? parseInt(m[1], 10) : 0; }
  function raster(url, type) { return !/\.svg(\?|#|$)/i.test(url) && type !== 'image/svg+xml'; }
  function fromLinks() {
    var best = null, bestSize = -1;
    document.querySelectorAll('link[rel]').forEach(function (l) {
      var rel = (l.getAttribute('rel') || '').toLowerCase();
      if (rel.indexOf('icon') < 0 || !l.href || !raster(l.href, l.type)) return;
      var size = sizeOf(l.getAttribute('sizes')) || (rel.indexOf('apple-touch-icon') >= 0 ? 180 : 32);
      if (size > bestSize) { bestSize = size; best = l.href; }
    });
    return best ? { url: best, size: bestSize } : null;
  }
  function fromManifest() {
    var link = document.querySelector('link[rel="manifest"]');
    if (!link || !link.href) return Promise.resolve(null);
    return fetch(link.href, { credentials: 'include' }).then(function (r) { return r.json(); }).then(function (m) {
      var best = null, bestSize = -1;
      (m.icons || []).forEach(function (i) {
        if (!i.src) return;
        var url = new URL(i.src, link.href).href;
        var purpose = (i.purpose || 'any').split(' ');
        if (!raster(url, i.type) || purpose.indexOf('any') < 0) return;
        var size = sizeOf(i.sizes);
        if (size > bestSize && size <= 512) { bestSize = size; best = url; }
      });
      return best ? { url: best, size: bestSize } : null;
    }).catch(function () { return null; });
  }
  var tries = 0;
  function find() {
    fromManifest().then(function (m) {
      var l = fromLinks();
      var pick = m && (!l || m.size >= l.size) ? m : l;
      // Simge henüz eklenmemiş olabilir (tek sayfalık uygulamalar sonradan ekler).
      if (!pick && ++tries < 4) { setTimeout(find, 5000); return; }
      if (!pick) { post({ type: 'iconTrace', step: 'bulunamadı', reason: '' }); return; }
      // Discord simgeyi resmin kendisini taşıyan data: adresine çeviriyor.
      if (pick.url.indexOf('data:image/') === 0) {
        post({ type: 'icon', url: '', size: pick.size, data: pick.url });
        return;
      }
      // Boyut yazmayan .ico dosyaları büyük sürüm içerebilir (Discord: 256 px);
      // gerçek boyuta uygulama indirince bakar.
      if (!pick) return;
      // Simgeyi sayfanın kendi bağlantısıyla indirip gönderir: uygulamanın
      // ayrı bağlantısı bazı ağlarda (SSL) reddedildi. Olmazsa yalnızca adres.
      fetch(pick.url, { credentials: 'include' }).then(function (r) {
        if (!r.ok) throw new Error('http');
        return r.blob();
      }).then(function (blob) {
        if (blob.size > 400000) throw new Error('büyük');
        return new Promise(function (resolve, reject) {
          var reader = new FileReader();
          reader.onload = function () { resolve(reader.result); };
          reader.onerror = reject;
          reader.readAsDataURL(blob);
        });
      }).then(function (data) {
        post({ type: 'icon', url: pick.url, size: pick.size, data: data });
      }).catch(function (err) {
        post({ type: 'iconTrace', step: 'fetch', reason: String(err && err.message || err).slice(0, 60) });
        // Sitenin güvenlik kuralı (CSP) indirmeyi engelleyebilir; resim olarak
        // yükleyip çizimden alınır (aynı kökendeki simgede çalışır).
        var img = new Image();
        img.crossOrigin = 'anonymous';
        img.onload = function () {
          try {
            var size = Math.min(img.naturalWidth || 0, 256);
            if (size < 48) throw new Error('küçük');
            var canvas = document.createElement('canvas');
            canvas.width = size;
            canvas.height = size;
            canvas.getContext('2d').drawImage(img, 0, 0, size, size);
            post({ type: 'icon', url: pick.url, size: size, data: canvas.toDataURL('image/png') });
          } catch (e) {
            post({ type: 'iconTrace', step: 'canvas', reason: String(e && e.message || e).slice(0, 60) + ' ' + img.naturalWidth });
            post({ type: 'icon', url: pick.url, size: pick.size });
          }
        };
        img.onerror = function () {
          post({ type: 'iconTrace', step: 'img', reason: 'yüklenemedi' });
          post({ type: 'icon', url: pick.url, size: pick.size });
        };
        img.src = pick.url;
      });
    });
  }
  function later() { setTimeout(find, 3000); }
  if (document.readyState === 'complete') later(); else window.addEventListener('load', later);
})();
""".trimIndent()

    /**
     * Videolar yalnızca kullanıcı dokununca oynar. Akıştaki kendiliğinden
     * oynayan videolar işlemciyi en çok yoran şey; site oynatmayı denerse
     * tarayıcının "otomatik oynatma engellendi" hatası döner (siteler bunu
     * zaten bekler ve oynat düğmesi gösterir).
     */
    val noAutoplay = """
(function () {
  if (window.__mmNoAutoplay) return;
  window.__mmNoAutoplay = true;
  function allowed(media) {
    var ua = navigator.userActivation;
    return media.__mmStarted || !ua || ua.isActive;
  }
  var play = HTMLMediaElement.prototype.play;
  HTMLMediaElement.prototype.play = function () {
    if (!allowed(this)) {
      return Promise.reject(new DOMException('Otomatik oynatma kapalı', 'NotAllowedError'));
    }
    this.__mmStarted = true;
    return play.apply(this, arguments);
  };
  // autoplay özniteliğiyle kendiliğinden başlayanlar.
  document.addEventListener('play', function (e) {
    var media = e.target;
    if (media && media.tagName === 'VIDEO' && !allowed(media)) media.pause();
  }, true);
})();
""".trimIndent()

    /** Masaüstü kimliğiyle açılan sayfanın kendini telefon sanmaması için. */
    val desktopPlatform = """
(function () {
  try { Object.defineProperty(navigator, 'platform', { get: function () { return 'Win32'; } }); } catch (e) {}
  try {
    if (navigator.userAgentData) {
      var brands = navigator.userAgentData.brands;
      var data = {
        brands: brands, mobile: false, platform: 'Windows',
        getHighEntropyValues: function () {
          return Promise.resolve({ brands: brands, mobile: false, platform: 'Windows', platformVersion: '15.0.0',
            architecture: 'x86', bitness: '64', model: '' });
        },
        toJSON: function () { return { brands: brands, mobile: false, platform: 'Windows' }; }
      };
      Object.defineProperty(navigator, 'userAgentData', { get: function () { return data; } });
    }
  } catch (e) {}
})();
""".trimIndent()

    /** Masaüstü sayfasını 1024 piksel genişlikte çizdirir; tarayıcı ekrana sığdırır. */
    val wideViewport = """
(function () {
  function apply() {
    var head = document.head || document.documentElement;
    if (!head) return;
    var meta = document.querySelector('meta[name="viewport"]');
    if (!meta) { meta = document.createElement('meta'); meta.name = 'viewport'; head.appendChild(meta); }
    if (meta.content !== 'width=1024') meta.content = 'width=1024';
  }
  apply();
  document.addEventListener('DOMContentLoaded', apply);
  if (document.documentElement) {
    new MutationObserver(apply).observe(document.documentElement, { childList: true, subtree: false });
  }
})();
""".trimIndent()
}
