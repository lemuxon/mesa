# Changelog

## 1.0.1 (unreleased)

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

### Upgrade note
Release APKs from 1.0.1 on are signed with a **new** key (the 1.0.0 key was lost). Android will not install 1.0.1 over
1.0.0: back up from Settings → Backup, uninstall, install 1.0.1, restore.
