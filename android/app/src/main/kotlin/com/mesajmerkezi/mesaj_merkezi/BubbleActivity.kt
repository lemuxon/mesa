package com.mesajmerkezi.mesaj_merkezi

/**
 * Sohbet balonu (Android 11+): bildirimdeki sohbet, ekranın üstünde yüzen
 * küçük pencerede açılır. MainActivity'nin bütün kanallarını kullanır;
 * Dart tarafında yalnızca sohbet ekranı çalışır (lib/main.dart: bubbleMain).
 * Hangi sohbetin açılacağı, MainActivity gibi LaunchToken'lı niyetten okunur.
 */
class BubbleActivity : MainActivity() {

    override val isBubble: Boolean get() = true

    override fun getDartEntrypointFunctionName(): String = "bubbleMain"
}
