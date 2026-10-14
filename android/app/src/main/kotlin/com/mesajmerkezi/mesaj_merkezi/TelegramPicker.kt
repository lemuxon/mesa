package com.mesajmerkezi.mesaj_merkezi

import org.drinkless.tdlib.TdApi
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

/**
 * Telegram'a gönderilecek çıkartma ve GIF'leri listeler ve gönderir.
 * Listeler arayüze "jeton" ile verilir; gönderirken jeton TDLib içeriğine
 * çevrilir. Önizlemeler küçük resimlerdir (hareketli çıkartma/GIF oynatılmaz).
 *
 * Tüm işler [worker] üzerinde, TDLib'e engelleyici çağrılarla yapılır;
 * TDLib'in kendi iş parçacığı asla bekletilmez.
 */
object TelegramPicker {

    private sealed interface Pick {
        class Content(val content: TdApi.InputMessageContent) : Pick
        class Inline(val queryId: Long, val resultId: String) : Pick
    }

    private val worker = Executors.newFixedThreadPool(2)
    private val picks = ConcurrentHashMap<String, Pick>()
    private val nextToken = AtomicInteger()

    private const val RECENT_SET_ID = "recent"
    private const val THUMBNAIL_TIMEOUT_SECONDS = 10L

    /** Arka planda çalıştırır; sonucu [done] ile (hata: null) döner. */
    fun <T> async(work: () -> T, done: (T?) -> Unit) {
        worker.execute {
            val value = try {
                work()
            } catch (e: RuntimeException) {
                null
            }
            done(value)
        }
    }

    /** "Son kullanılanlar" + yüklü çıkartma paketleri. */
    fun stickerSets(): List<Map<String, Any?>> {
        val sets = TelegramClient.call(
            TdApi.GetInstalledStickerSets().apply { stickerType = TdApi.StickerTypeRegular() }
        ) as? TdApi.StickerSets
        val installed = sets?.sets.orEmpty().map { set ->
            mapOf(
                "id" to set.id.toString(),
                "title" to set.title,
                "thumbPath" to set.covers.firstOrNull()?.let { previewOf(it) }?.let(::download),
            )
        }
        return listOf(mapOf("id" to RECENT_SET_ID, "title" to TelegramClient.text(R.string.tg_recent_stickers), "thumbPath" to null)) + installed
    }

    fun stickers(setId: String): List<Map<String, Any?>> {
        val stickers = if (setId == RECENT_SET_ID) {
            (TelegramClient.call(TdApi.GetRecentStickers().apply { isAttached = false }) as? TdApi.Stickers)
                ?.stickers.orEmpty().toList()
        } else {
            (TelegramClient.call(TdApi.GetStickerSet().apply { this.setId = setId.toLong() }) as? TdApi.StickerSet)
                ?.stickers.orEmpty().toList()
        }
        val thumbs = downloadAll(stickers.map(::previewOf))
        return stickers.mapIndexed { i, sticker ->
            mapOf(
                "token" to register(
                    Pick.Content(
                        TdApi.InputMessageSticker().apply {
                            this.sticker = TdApi.InputSticker().apply {
                                this.sticker = TdApi.InputFileId().apply { id = sticker.sticker.id }
                                width = sticker.width
                                height = sticker.height
                            }
                            emoji = sticker.emoji
                        }
                    )
                ),
                "thumbPath" to thumbs[i],
                "emoji" to sticker.emoji,
            )
        }
    }

    /** Boş sorgu: kaydedilmiş GIF'ler. Dolu sorgu: Telegram'ın @gif botuyla arama. */
    fun gifs(key: String, query: String): List<Map<String, Any?>> =
        if (query.isBlank()) savedGifs() else searchGifs(key, query.trim())

    private fun savedGifs(): List<Map<String, Any?>> {
        val animations = (TelegramClient.call(TdApi.GetSavedAnimations()) as? TdApi.Animations)
            ?.animations.orEmpty().toList()
        return gifItems(animations) { animation ->
            Pick.Content(
                TdApi.InputMessageAnimation().apply {
                    this.animation = TdApi.InputAnimation().apply {
                        this.animation = TdApi.InputFileId().apply { id = animation.animation.id }
                        duration = animation.duration
                        width = animation.width
                        height = animation.height
                    }
                }
            )
        }
    }

    private fun searchGifs(key: String, query: String): List<Map<String, Any?>> {
        val chatId = TelegramClient.chatIdOf(key)
        val botChat = TelegramClient.call(TdApi.SearchPublicChat().apply { username = "gif" }) as? TdApi.Chat
            ?: return emptyList()
        val botUserId = (botChat.type as? TdApi.ChatTypePrivate)?.userId ?: return emptyList()
        val results = TelegramClient.call(
            TdApi.GetInlineQueryResults().apply {
                this.botUserId = botUserId
                this.chatId = chatId
                this.query = query
                offset = ""
            }
        ) as? TdApi.InlineQueryResults ?: return emptyList()
        val animations = results.results.filterIsInstance<TdApi.InlineQueryResultAnimation>()
        return gifItems(animations.map { it.animation }) { animation ->
            val result = animations.first { it.animation === animation }
            Pick.Inline(results.inlineQueryId, result.id)
        }
    }

    private fun gifItems(
        animations: List<TdApi.Animation>,
        pick: (TdApi.Animation) -> Pick,
    ): List<Map<String, Any?>> {
        val thumbs = downloadAll(animations.map { a -> a.thumbnail?.takeIf(::isImageThumbnail)?.file })
        return animations.mapIndexed { i, animation ->
            mapOf(
                "token" to register(pick(animation)),
                "thumbPath" to thumbs[i],
                // Küçük resim indirilemezse TDLib'in gömülü bulanık önizlemesi.
                "miniThumb" to animation.minithumbnail?.data,
            )
        }
    }

    /** Jetonu gönderir; jeton bilinmiyorsa (liste eskidi) false. */
    fun send(key: String, token: String): Boolean {
        val chatId = TelegramClient.chatIdOf(key)
        val function: TdApi.Function<*> = when (val pick = picks[token] ?: return false) {
            is Pick.Content -> TdApi.SendMessage().apply {
                this.chatId = chatId
                inputMessageContent = pick.content
            }
            is Pick.Inline -> TdApi.SendInlineQueryResultMessage().apply {
                this.chatId = chatId
                queryId = pick.queryId
                resultId = pick.resultId
                hideViaBot = true
            }
        }
        return TelegramClient.call(function) !is TdApi.Error
    }

    private fun register(pick: Pick): String {
        // Eski listelerin jetonları birikmesin; panel her açılışta yeniden ister.
        if (picks.size > 2000) picks.clear()
        return "p${nextToken.incrementAndGet()}".also { picks[it] = pick }
    }

    /** Gösterilebilir önizleme: statik çıkartmanın kendisi, yoksa küçük resmi. */
    private fun previewOf(sticker: TdApi.Sticker): TdApi.File? =
        if (sticker.format is TdApi.StickerFormatWebp) sticker.sticker
        else sticker.thumbnail?.takeIf(::isImageThumbnail)?.file

    private fun isImageThumbnail(thumbnail: TdApi.Thumbnail) =
        thumbnail.format is TdApi.ThumbnailFormatWebp ||
            thumbnail.format is TdApi.ThumbnailFormatJpeg ||
            thumbnail.format is TdApi.ThumbnailFormatPng

    private fun download(file: TdApi.File): String? = downloadAll(listOf(file)).first()

    /** Dosyaları paralel indirir; zaman aşımına uğrayanlar null kalır. */
    private fun downloadAll(files: List<TdApi.File?>): List<String?> {
        val paths = arrayOfNulls<String>(files.size)
        val latch = CountDownLatch(files.count { it != null })
        files.forEachIndexed { i, file ->
            if (file == null) return@forEachIndexed
            if (file.local.isDownloadingCompleted) {
                paths[i] = file.local.path
                latch.countDown()
                return@forEachIndexed
            }
            TelegramClient.callAsync(
                TdApi.DownloadFile().apply {
                    fileId = file.id
                    priority = 16
                    offset = 0
                    limit = 0
                    synchronous = true
                }
            ) { result ->
                val downloaded = result as? TdApi.File
                if (downloaded?.local?.isDownloadingCompleted == true) paths[i] = downloaded.local.path
                latch.countDown()
            }
        }
        latch.await(THUMBNAIL_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        return paths.toList()
    }
}
