# Changelog

## 1.2.1 (unreleased)

### New
- **WhatsApp chats stay complete in Mesa.** Until now, a reply you typed inside WhatsApp never reached Mesa, and while a
  chat was open in WhatsApp the other side's messages didn't either (WhatsApp shows no notification for the open chat),
  so chats looked one-sided. An optional accessibility service ("Mesa: my WhatsApp replies") watches the bottom of the
  WhatsApp chat on screen and adds every new message there, yours and theirs, to the same chat in Mesa. A chat you start
  in WhatsApp with someone who hasn't written to you appears in Mesa too. Chats you open in WhatsApp are marked as read.
  It only receives WhatsApp and WhatsApp Business events and only text messages are added. Turn it on from Settings →
  Apps being read, or from the tip in a WhatsApp chat.
- **You stay in Mesa when you send.** When a chat has no reply path (for example after the phone restarts), WhatsApp
  has to open for a moment; with the same service on, Mesa keeps a still image of its own screen on top (with a small
  "Sending via WhatsApp…" chip) while the service fills the message box, presses WhatsApp's Send button and brings Mesa
  back. Your taps go to that image, not to WhatsApp. It only acts within 10 seconds of your tap and only in the chat whose
  name matches. A send counts as done when the box empties or the message appears at the bottom of the chat; if it can't
  send, your text goes back into Mesa's message box and the WhatsApp draft is cleared. For a chat Mesa only knows from
  WhatsApp's screen, the service picks that chat on WhatsApp's share screen, and only if exactly one chat there has that
  name.

- **Replies go out instantly more often.** The notification's reply route used to live only in memory, so whenever
  Android closed Mesa in the background every chat fell back to sending through WhatsApp's screen. Mesa now leaves the
  routes of the 80 most recent chats with Android itself and takes them back when it starts again, so replies keep going
  out directly and invisibly. Restarting the phone or updating Mesa still clears them until a new message arrives.

- **Voice messages to text, on the phone.** Under a voice message, "Transcribe" turns it into text with Android's own
  speech recognition, offline when the phone has the language pack (Android 13+). WhatsApp keeps voice messages out of
  its notifications, so Mesa asks once for read access to WhatsApp's "WhatsApp Voice Notes" folder and matches the file
  by time and duration; when more than one file could fit, it doesn't guess. Telegram voice messages are downloaded as
  before. The text is kept with the message; the audio never leaves the phone.
- **Mesa on your computer.** Turn it on in Settings → Connections → Mesa on computer and open the address it shows
  (https://<phone IP>:8743) in a browser on a computer on the same Wi-Fi: your chats appear on the left, messages on the
  right, new ones arrive live, and you can reply wherever Mesa can reply directly (Telegram, and chats with a reply path
  from their notification). The phone serves the page itself over an encrypted connection with a certificate it creates
  (the browser warns once because no authority signed it); nothing goes through the internet. A browser connects only
  after you allow the four-digit code it shows in a notification on your unlocked phone, and connected computers can be
  disconnected from Mesa. Only local network addresses are served, requests that name another site are refused, and the
  page works in eight languages, light and dark.
- **Optional AI assistant with Claude.** Enter your own Anthropic API key in Settings → AI assistant and a strip above
  the message box offers "Suggest replies" (three short replies in the chat's language and your tone; tapping one puts it
  in the box), "Summarize" (what needs your attention first, written as it arrives) and "Ask" (a question answered from
  that chat only); while you type it offers "Improve": fix mistakes, make it more polite or shorter, or translate it into
  the other person's language, applied only after you approve. Claude Opus 5.5 by default, Sonnet 5.5 or Haiku 5.5 to
  choose from. Nothing is sent until you tap, the key is checked with Anthropic and stored encrypted, and on Opus and
  Sonnet a request that Claude's safety filter wrongly declines is retried on the model Anthropic recommends.
- **Translate messages on the phone.** A message that looks like it's in another language gets a "Translate" button
  (long-press any message for "Translate" too); the translation appears under it and is kept with the message. It runs
  offline with Google's ML Kit: the first time, Mesa asks before downloading the language pack (about 30 MB per
  language, once). Message text never leaves the phone, and ML Kit doesn't start until you tap "Translate". The button
  is decided on the phone from the alphabet and common words, so short messages, names and links don't get one.
  Downloaded packs can be deleted in Settings → Translation. The translation engine makes the app about 18 MB larger.
- **From message to action in one tap.** Under a message, Mesa offers what you'd do next: copy a verification code,
  call a phone number, copy an IBAN (only when its check digits are valid) or an email address, open a link, open an
  address or a map link in maps, and for dates and times ("yarın 15:00", "akşam 8", "cuma", "25 Kasım", "01.12.2026")
  add to calendar or get reminded half an hour before. Words like "yarın" count from the day the message was sent, and
  past times aren't offered. A notification with a verification code gets a "Copy 123456" button. Everything runs on
  the phone.

### Fixed
- **"Mark as read" on WhatsApp's own notification didn't reach Mesa.** With WhatsApp's notification kept, marking a chat
  read there (or opening it in WhatsApp) left it unread in Mesa with Mesa's notification still up. Mesa now follows
  WhatsApp when it removes its notification that way, and Mesa's own "Mark as read" also presses WhatsApp's, so the chat
  is read in both.
- **Mesa's notification stayed after "Mark as read" on Xiaomi.** To keep a bubble alive, the notification was re-posted
  as "hidden from the shade", which Xiaomi ignores. Now only a chat opened inside its bubble keeps the bubble; mark as
  read, reading in WhatsApp and opening the chat in Mesa remove the notification.
- **Chat bubbles closed right as they opened.** Opening the chat in the bubble marked it read, which removed its
  notification, and Android closes a bubble together with its notification. A bubbling chat now keeps its bubble and is only
  hidden from the notification shade. Deleting or snoozing the chat still closes the bubble.
- **Replies written in WhatsApp were not picked up.** The message box's typing events don't arrive reliably from
  WhatsApp (none did on the test phone); new messages are now read from the chat list itself.

## 1.2.0 (unreleased)

Full VPN, focus mode, automatic backups and chat bubbles.

### New
- **Full VPN with WireGuard.** Import a `.conf` file (or paste it) from your own server or a provider that offers
  WireGuard configurations, then connect from the Secure connection screen. All traffic goes through the tunnel and your IP
  address changes. Uses the official WireGuard library. The configuration, which holds the private key, is stored
  encrypted with a non-exportable Android Keystore key, and the screen only shows a summary. Live status shows the last
  handshake and traffic. Android runs one VPN at a time, so Mesa switches between secure DNS and the tunnel for you.
- **Focus mode.** Only VIPs, messages matching "Mark important" and emergencies (the same chat writing 3 times within
  5 minutes) notify you. Everything else quietly lands in Mesa, and a summary notification lists who wrote when focus
  ends. Turn it on for 1 hour, 3 hours, until 08:00 or until you turn it off, or schedule it by day (overnight windows
  work). Quick settings tile and a banner at the top of the inbox.
- **Automatic encrypted backups.** Pick a folder (phone, SD card, Drive…), daily or weekly. The newest 5 automatic backups
  are kept; manual backups are never touched. For this to run unattended, the password is stored encrypted with the
  Android Keystore. Manual backups still never store it.
- **Chat bubbles** (Android 11+). With unified notifications on, a chat can open in a floating bubble and you can reply
  without opening Mesa.

## 1.1.0 (unreleased)

Secure connection: reach blocked services and keep DNS private, with no servers and no account.

### New
- **Secure DNS for the whole phone.** A local, DNS-only VPN sends every DNS lookup over HTTPS (DoH) to the provider you
  choose: Cloudflare 1.1.1.1, Cloudflare with malware blocking (1.1.1.2) or family filter (1.1.1.3), **AdGuard (blocks
  ads and trackers on the whole phone)**, Quad9 or Google. Only the virtual DNS address is routed into the tunnel, so
  other traffic is untouched. Answers are cached for their TTL; if the provider's name is blocked, its IP addresses are
  tried. Quick settings tile, a "Turn off" action on its notification, and it comes back after a reboot. It is not a
  full VPN: your IP address does not change, and the screen says so.
- **Access shield for web services.** Mesa's web services (Discord, Slack, …) connect through a local proxy that resolves
  names with secure DNS and splits the TLS ClientHello inside the server name, so DNS and SNI blocks do not stop them. No
  VPN needed, and it works alongside your own VPN. The proxy only accepts Mesa's own web views (random per-install
  password); if it stops, pages fall back to a direct connection.
- **Telegram proxy (MTProto / SOCKS5)** through TDLib: paste a `tg://proxy`, `t.me/proxy` or `t.me/socks` link or enter
  it by hand, switch proxies on and off, measure the round-trip time, and test whether Telegram is reachable directly.
  Proxies can be added before signing in.
- **"Remind in 1 hour"** on unified notifications: snoozes the chat without opening the app.

## 1.0.1 (2026-11-25)

Security and reliability fixes from a full code audit (November 2026).

### Security
- **Conversation deep links can no longer be spoofed.** `MainActivity` is exported (launcher) and used to read the
  `conversation_key` extra from any intent, so another app could open Mesa on a chat of its choice. Mesa's own
  notification, shortcut, widget and reminder intents now carry a per-install random token that is compared in
  constant time (`LaunchToken.kt`); intents without it just open the inbox.
- **A reply can no longer go to the wrong conversation.** Notification reply / mark-read PendingIntents were told apart
  only by `key.hashCode()`. Two conversations with colliding hashes shared one PendingIntent, and
  `FLAG_UPDATE_CURRENT` overwrote the target conversation. Every PendingIntent now has a conversation-specific data URI.
  Same fix for snooze alarms and web service notifications.
- **Notification images are only read from other apps' content URIs.** A `file://` URI or one of Mesa's own provider
  would have made Mesa copy its own private files (database, Telegram session) into the media folder.
- **Web page notifications are size-capped** (title 200, body 4000, click id 100 characters), so a broken or hostile page
  cannot flood the database.
- File names picked for sending can no longer put a `/` into the outbox file name; the outbox path check now requires the
  directory separator (`outbox2/…` no longer matches).

### Reliability
- **Restoring a backup no longer risks losing all messages.** The live database used to be deleted before the backup
  copy was written; a full disk or I/O error mid-copy destroyed it. The backup is now staged next to the live database
  and swapped in with an atomic rename.
- Backup output stream is closed on every error path; a second tap on backup/restore no longer leaves the first Dart
  call hanging forever.
- "Mark as read" from a notification always finishes its broadcast (no ANR on database errors).
- A snooze reminder is shown at most once, even if an alarm from an older build also fires.
- Search shows an empty result instead of an uncaught error when the database is busy.

### Other
- Telegram receives the app language instead of a hard-coded `tr` (login code messages, server texts).
- Tapping an "important" notification opens that conversation instead of just the app.
- The web service lock screen text is localized.

### Build
- Builds with Flutter 3.50: Gradle 9.5.0, Android Gradle plugin 9.3.1, Kotlin 2.4.20 (Flutter 3.50 rejects the older
  Gradle 9.1 / AGP 9.0 / Kotlin 2.3).
- Debug builds install next to the release app as a separate app, "Mesa Dev" (`.debug` package suffix), so testing a
  build never requires uninstalling Mesa and losing its messages.
- The backup restore swap uses `Files.move` (atomic, replaces the target) on Android 8+; `File.renameTo` failed on
  Windows hosts, where the Robolectric tests run.
- New CI workflow runs the analyzer, the Dart tests and the Android unit tests on every push.
- `scripts/tdlib_indir.ps1`: TDLib download with SHA256 check for Windows, without Git Bash.
- README: Windows build steps and the list of files that must be backed up outside git.

### Upgrade note
Release APKs from 1.0.1 on are signed with a **new** key (the 1.0.0 key was lost). Android will not install 1.0.1 over
1.0.0: back up from Settings → Backup, uninstall, install 1.0.1, restore.

New certificate (SHA-256):
`6E:38:FB:B0:35:73:C8:60:9D:C4:DF:B2:C6:31:47:37:68:5A:49:45:7D:9C:FD:CC:BD:64:CF:5F:D6:58:F2:5F`
