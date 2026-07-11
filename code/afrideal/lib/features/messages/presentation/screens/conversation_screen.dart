import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/conversation_thread.dart';

/// Écran plein écran (mobile / navigation classique) affichant un
/// seul fil de discussion — la logique du fil elle-même vit dans
/// ConversationThread, réutilisée aussi par la vue scindée de
/// AdminMessagesScreen sur grand écran.
class ConversationScreen extends StatelessWidget {
  final String conversationId;
  const ConversationScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Conversation')),
      body: ConversationThread(conversationId: conversationId),
    );
  }
}
