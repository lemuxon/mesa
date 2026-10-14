# TDLib: libtdjni.so, TdApi nesnelerini JNI üzerinden sınıf ve alan adlarıyla
# oluşturur/okur. R8 bunları yeniden adlandırır ya da silerse release
# derlemesi giriş anında çöker (debug'da görünmez).
-keep class org.drinkless.tdlib.** { *; }
