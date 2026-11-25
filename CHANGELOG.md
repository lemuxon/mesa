# Changelog

## 1.2.1 (unreleased)

### New
- **Your WhatsApp replies show up in Mesa.** Until now, a reply you typed inside WhatsApp never reached Mesa, so chats
  looked one-sided. An optional accessibility service ("Mesa: my WhatsApp replies") adds what you send in WhatsApp to the
  same chat in Mesa and marks chats you open in WhatsApp as read. It only receives WhatsApp and WhatsApp Business events,
  reads only the message box, the Send button and the chat name, and only adds to chats that are already in Mesa. Turn it
  on from Settings → Apps being read, or from the tip in a WhatsApp chat.

### Fixed
- **Chat bubbles closed right as they opened.** Opening the chat in the bubble marked it read, which removed its
  notification, and Android closes a bubble together with its notification. A bubbling chat now keeps its bubble and is only
  hidden from the notification shade. Deleting or snoozing the chat still closes the bubble.

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
