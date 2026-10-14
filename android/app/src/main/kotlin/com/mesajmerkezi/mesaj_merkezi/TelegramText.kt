package com.mesajmerkezi.mesaj_merkezi

import org.drinkless.tdlib.TdApi

/** TDLib nesnelerini gelen kutusunda gösterilecek metne çevirir. */
object TelegramText {

    /** Mesaj içeriğinin metni; medya için açıklama (varsa altyazıyla). Desteklenmeyen tür: null. */
    fun describe(content: TdApi.MessageContent): String? = when (content) {
        is TdApi.MessageText -> content.text.text
        is TdApi.MessagePhoto -> withCaption("📷 Fotoğraf", content.caption)
        is TdApi.MessageVideo -> withCaption("🎥 Video", content.caption)
        is TdApi.MessageAnimation -> withCaption("GIF", content.caption)
        is TdApi.MessageDocument -> withCaption("📄 ${content.document.fileName.ifBlank { "Dosya" }}", content.caption)
        is TdApi.MessageAudio -> withCaption("🎵 Ses dosyası", content.caption)
        is TdApi.MessageVoiceNote -> withCaption("🎤 Sesli mesaj", content.caption)
        is TdApi.MessageVideoNote -> "⏺ Görüntülü mesaj"
        is TdApi.MessageSticker -> "${content.sticker.emoji} Çıkartma".trim()
        is TdApi.MessageLocation -> "📍 Konum"
        is TdApi.MessageVenue -> "📍 ${content.venue.title}"
        is TdApi.MessageContact -> "👤 Kişi: ${content.contact.firstName} ${content.contact.lastName}".trim()
        is TdApi.MessagePoll -> "📊 Anket: ${content.poll.question.text}"
        else -> null
    }?.takeIf { it.isNotBlank() }

    /**
     * Gelen kutusunda gösterilebilecek görsel dosya ve türü. Animasyonlu
     * (tgs/webm) çıkartmalarda ve mp4 GIF'lerde küçük resim kullanılır.
     */
    fun mediaFile(content: TdApi.MessageContent): Pair<TdApi.File, String>? = when (content) {
        is TdApi.MessageSticker -> {
            val sticker = content.sticker
            if (sticker.format is TdApi.StickerFormatWebp) {
                sticker.sticker to "image/webp"
            } else {
                sticker.thumbnail?.let(::thumbnailFile)
            }
        }
        is TdApi.MessagePhoto ->
            content.photo.sizes.filter { it.width <= 800 }.maxByOrNull { it.width }?.let { it.photo to "image/jpeg" }
        is TdApi.MessageAnimation -> {
            val animation = content.animation
            if (animation.mimeType == "image/gif") {
                animation.animation to "image/gif"
            } else {
                animation.thumbnail?.let(::thumbnailFile)
            }
        }
        is TdApi.MessageVideo -> content.video.thumbnail?.let(::thumbnailFile)
        is TdApi.MessageVideoNote -> content.videoNote.thumbnail?.let(::thumbnailFile)
        else -> null
    }

    /** Mesajın medya türü: photo, video, animation, sticker, voice, audio; medya yoksa null. */
    fun mediaKind(content: TdApi.MessageContent): String? = when (content) {
        is TdApi.MessagePhoto -> "photo"
        is TdApi.MessageVideo, is TdApi.MessageVideoNote -> "video"
        is TdApi.MessageAnimation -> "animation"
        is TdApi.MessageSticker -> "sticker"
        is TdApi.MessageVoiceNote -> "voice"
        is TdApi.MessageAudio -> "audio"
        else -> null
    }

    /**
     * Tam boy dosya: fotoğrafın en büyük boyu, videonun/GIF'in kendisi.
     * Kullanıcı açınca indirilir; çıkartmalarda önizleme yeterli.
     */
    fun fullFile(content: TdApi.MessageContent): TdApi.File? = when (content) {
        is TdApi.MessagePhoto -> content.photo.sizes.maxByOrNull { it.width }?.photo
        is TdApi.MessageVideo -> content.video.video
        is TdApi.MessageVideoNote -> content.videoNote.video
        is TdApi.MessageAnimation -> content.animation.animation
        // Sesli mesaj ve ses dosyası uygulamada dinlenir.
        is TdApi.MessageVoiceNote -> content.voiceNote.voice
        is TdApi.MessageAudio -> content.audio.audio
        else -> null
    }

    /** Gönderilirken sunucuya yüklenen dosya (fotoğraf, video, ses, belge). */
    fun uploadFile(content: TdApi.MessageContent): TdApi.File? =
        fullFile(content) ?: (content as? TdApi.MessageDocument)?.document?.document

    /** Videonun, GIF'in, sesin süresi (saniye); yoksa null. */
    fun mediaDuration(content: TdApi.MessageContent): Int? = when (content) {
        is TdApi.MessageVideo -> content.video.duration
        is TdApi.MessageVideoNote -> content.videoNote.duration
        is TdApi.MessageAnimation -> content.animation.duration
        is TdApi.MessageVoiceNote -> content.voiceNote.duration
        is TdApi.MessageAudio -> content.audio.duration
        else -> null
    }?.takeIf { it > 0 }

    /** Tam boy dosyanın boyutu (bayt); bilinmiyorsa null. */
    fun mediaSize(content: TdApi.MessageContent): Long? = fullFile(content)?.let {
        if (it.size.toLong() > 0) it.size.toLong() else it.expectedSize.toLong()
    }?.takeIf { it > 0 }

    private fun thumbnailFile(thumbnail: TdApi.Thumbnail): Pair<TdApi.File, String>? = when (thumbnail.format) {
        is TdApi.ThumbnailFormatWebp -> thumbnail.file to "image/webp"
        is TdApi.ThumbnailFormatJpeg -> thumbnail.file to "image/jpeg"
        is TdApi.ThumbnailFormatPng -> thumbnail.file to "image/png"
        is TdApi.ThumbnailFormatGif -> thumbnail.file to "image/gif"
        else -> null
    }

    fun displayName(user: TdApi.User): String =
        "${user.firstName} ${user.lastName}".trim().ifEmpty { TelegramClient.text(R.string.tg_deleted_account) }

    private fun withCaption(label: String, caption: TdApi.FormattedText?): String {
        val text = caption?.text.orEmpty().trim()
        return if (text.isEmpty()) label else "$label: $text"
    }
}
