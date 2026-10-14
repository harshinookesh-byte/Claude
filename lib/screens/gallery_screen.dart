import 'package:flutter/material.dart';

import '../models/look.dart';
import '../ads/ad_service.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return Scaffold(
      bottomNavigationBar: AdScope.of(context).banner(),
      appBar: AppBar(
        title: const Text('My Looks',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: StudioBackground(
        child: SafeArea(
          child: game.gallery.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No saved looks yet.\nStyle your model in the Studio or '
                      'save a look after a fashion show!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    childAspectRatio: 0.55,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: game.gallery.length,
                  itemBuilder: (context, i) =>
                      _LookCard(saved: game.gallery[i]),
                ),
        ),
      ),
    );
  }
}

class _LookCard extends StatelessWidget {
  const _LookCard({required this.saved});

  final SavedLook saved;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => _LookSheet(saved: saved, parentContext: context),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Expanded(child: ModelView(look: saved.look)),
              Text(saved.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              if (saved.score != null)
                Text('Score ${saved.score}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9C4DCC))),
            ],
          ),
        ),
      ),
    );
  }
}

class _LookSheet extends StatelessWidget {
  const _LookSheet({required this.saved, required this.parentContext});

  final SavedLook saved;
  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.read(parentContext);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(saved.title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.5,
              child: ModelView(look: saved.look),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      game.deleteFromGallery(saved);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      game.setLook(saved.look);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Your model is wearing this look')));
                    },
                    icon: const Icon(Icons.checkroom),
                    label: const Text('Wear it'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
