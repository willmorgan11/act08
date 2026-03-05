import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../models/card.dart';
import '../repositories/card_repository.dart';
import 'add_edit_card_screen.dart';

// displays all cards in a specific folder
class CardsScreen extends StatefulWidget {
  final Folder folder;
  const CardsScreen({super.key, required this.folder});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final _cardRepo = CardRepository();
  List<PlayingCard> _cards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCards(); // fetch all cards when the screen loads
  }

  Future<void> _loadCards() async {
    setState(() => _loading = true);
    try {
      final cards = await _cardRepo.getCardsByFolderId(widget.folder.id!);
      setState(() {
        _cards = cards;
        _loading = false;
      });
    } catch (e) { // SnackBar for loading error
      setState(() => _loading = false);
      _showSnack('Error loading cards: $e');
    }
  }

  // delete a card with a confirmation message to prevent data loss
  Future<void> _deleteCard(PlayingCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // forces the user to complete the action
      builder: (_) => AlertDialog(
        title: const Text('Delete Card?'),
        content: Text('Delete "${card.cardName} of ${card.suit}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _cardRepo.deleteCard(card.id!);
        _showSnack('${card.cardName} deleted');
        _loadCards(); // reload the cards after deletion
      } catch (e) {
        _showSnack('Failed to delete: $e');
      }
    }
  }

  // navigates to AddEditCardScreen
  Future<void> _openAddEdit({PlayingCard? card}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditCardScreen(
          folder: widget.folder,
          existingCard: card,
        ),
      ),
    );
    _loadCards(); // reload the cards after leaving AddEditCardScreen
  }

  // displays snackbard message at the bottom
  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // returns red for Hearts and black for Spades
  Color get _suitColor =>
      (widget.folder.folderName == 'Hearts' ||
          widget.folder.folderName == 'Diamonds')
          ? Colors.red
          : Colors.black87;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        title: Text(
          '${widget.folder.folderName} (${_cards.length})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: _loading // loading indicator
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _cards.isEmpty
          ? const Center(
        child: Text(
          'No cards yet.\nTap + to add one.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3 columns
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.68, // card shape aspect ratio
        ),
        itemCount: _cards.length,
        itemBuilder: (context, index) {
          final card = _cards[index];
          return _CardTile(
            card: card,
            suitColor: _suitColor,
            onEdit: () => _openAddEdit(card: card),
            onDelete: () => _deleteCard(card),
          );
        },
      ),
      // button to add a new card to current folder
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber[800],
        foregroundColor: Colors.white,
        onPressed: () => _openAddEdit(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
// each card tile displays the image, name, and the edit/delete buttons
class _CardTile extends StatelessWidget {
  final PlayingCard card;
  final Color suitColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CardTile({
    required this.card,
    required this.suitColor,
    required this.onEdit,
    required this.onDelete,
  });

  // loads the image from assets
  Widget _buildImage() {
    if (card.imageUrl == null || card.imageUrl!.isEmpty) {
      return Icon(Icons.image_not_supported, size: 40, color: Colors.grey[400]);
    }
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      child: Image.asset(
        card.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => Icon(
          Icons.broken_image,
          size: 40,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Center(child: _buildImage()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              card.cardName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: suitColor,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              InkWell(
                onTap: onEdit,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.edit, size: 16, color: Colors.blue),
                ),
              ),
              InkWell(
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.delete, size: 16, color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}