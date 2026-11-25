import 'bridge.dart';
import 'models.dart';

/// Anahtarı verilen sohbet ve (birleştirilmiş kişiyse) kişinin bütün
/// sohbetleri, en yeniden eskiye. Sohbet bulunamazsa null. Gelen kutusu
/// (bildirime dokunma) ve sohbet balonu aynı mantığı kullanır.
Future<({Conversation conversation, List<Conversation> members})?>
loadConversation(CoreBridge bridge, String key) async {
  final all = [
    ...await bridge.conversations(),
    ...await bridge.conversations(archived: true),
  ];
  final conversation = all.where((c) => c.key == key).firstOrNull;
  if (conversation == null) return null;
  final person = conversation.personId;
  final members = person == null
      ? <Conversation>[]
      : (all.where((c) => c.personId == person).toList()
          ..sort((a, b) => b.lastTime.compareTo(a.lastTime)));
  return (
    conversation: conversation,
    members: members.length > 1 ? members : const <Conversation>[],
  );
}
