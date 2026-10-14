package com.mesajmerkezi.mesaj_merkezi

import android.content.Context
import android.util.Log
import java.util.Calendar

/** RuleEngine'in kararlarını uygular. Hub.io iş parçacığında çağrılır. */
object RuleRunner {

    private const val TAG = "MesajMerkezi"
    private const val HOUR_MS = 60 * 60 * 1000L

    /** Çalışan kuralların eylemlerini döner (bildirim kararı için). */
    fun run(
        context: Context,
        store: MessageStore,
        conv: CapturedConversation,
        newIncoming: List<CapturedMessage>,
    ): Set<RuleAction> {
        val rules = store.rules()
        if (rules.isEmpty()) return emptySet()
        val now = System.currentTimeMillis()
        val local = Calendar.getInstance().apply { timeInMillis = now }
        val input = RuleInput(
            packageName = conv.packageName,
            title = conv.title,
            isGroup = conv.isGroup,
            newIncoming = newIncoming,
            now = now,
            minuteOfDay = local.get(Calendar.HOUR_OF_DAY) * 60 + local.get(Calendar.MINUTE),
            // Calendar: pazar = 1, pazartesi = 2 … → pazartesi = 0 … pazar = 6
            dayIndex = (local.get(Calendar.DAY_OF_WEEK) + 5) % 7,
        )
        val fired = RuleEngine.decide(
            rules,
            input,
            lastAutoReply = { store.lastAutoReply(it, conv.key) },
            autoRepliesLastHour = store.autoRepliesSince(now - HOUR_MS),
        )
        for (rule in fired) {
            when (rule.action) {
                RuleAction.AUTO_REPLY -> {
                    try {
                        Hub.sendReply(context, conv.key, rule.replyText, auto = true)
                    } catch (e: NoReplyActionException) {
                        Log.i(TAG, "Otomatik yanıt gönderilemedi, yanıt yolu yok: ${rule.name}")
                        continue
                    }
                    if (Hub.recordsOwnReplies(conv.key)) {
                        store.recordOutgoing(conv.key, rule.replyText, auto = true)
                    }
                }
                RuleAction.MUTE -> store.clearUnread(conv.key)
                RuleAction.IMPORTANT -> {
                    store.setImportant(conv.key)
                    // Birleşik bildirimler açıksa önem, sohbetin kendi bildiriminde gösterilir.
                    // Web servislerinin bildirimi her zaman Mesa'dan gelir.
                    if (!AppSettings.unifiedNotifications(context) && !WebServices.isWebKey(conv.key)) {
                        ImportantNotifier.notify(context, conv, newIncoming.last().text)
                    }
                }
            }
            store.recordFire(rule.id, conv.key, rule.action, now)
        }
        return fired.map { it.action }.toSet()
    }
}
