import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/error_view.dart';
import '../../../../shared/widgets/feedback/app_loading_indicator.dart';
import '../../../auth/providers/session_provider.dart';
import '../../providers/message_provider.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String conversationId;
  const ConversationScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _envoyer() {
    final texte = _controller.text.trim();
    if (texte.isEmpty) return;
    _controller.clear();
    ref.read(conversationNotifierProvider(widget.conversationId).notifier).envoyer(texte);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final msgsState = ref.watch(conversationNotifierProvider(widget.conversationId));
    final moi = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Conversation')),
      body: Column(
        children: [
          Expanded(
            child: msgsState.when(
              loading: () => const AppLoadingIndicator(),
              error: (_, __) => const ErrorView(message: 'Impossible de charger la conversation.'),
              data: (msgs) => ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: msgs.length,
                itemBuilder: (context, i) {
                  final msg = msgs[i];
                  final estMoi = msg.expediteurId == moi?.id;
                  return Align(
                    alignment: estMoi ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.72,
                      ),
                      decoration: BoxDecoration(
                        color: estMoi ? AppColors.violet : AppColors.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(AppRadius.md),
                          topRight: const Radius.circular(AppRadius.md),
                          bottomLeft: Radius.circular(estMoi ? AppRadius.md : AppRadius.sm),
                          bottomRight: Radius.circular(estMoi ? AppRadius.sm : AppRadius.md),
                        ),
                        border: estMoi ? null : Border.all(color: AppColors.gray200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            msg.contenu,
                            style: AppTypography.bodyLarge.copyWith(
                              color: estMoi ? AppColors.white : AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.dateWithTime(msg.dateEnvoi),
                            style: AppTypography.caption.copyWith(
                              color: estMoi
                                  ? AppColors.white.withValues(alpha: 0.7)
                                  : AppColors.gray400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.gray200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Votre message...',
                        border: InputBorder.none,
                        filled: false,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _envoyer(),
                    ),
                  ),
                  IconButton(
                    onPressed: _envoyer,
                    icon: const Icon(Icons.send_rounded, color: AppColors.violet),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
