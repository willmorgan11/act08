import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../models/card.dart';
import '../repositories/card_repository.dart';
import '../repositories/folder_repository.dart';

class AddEditCardScreen extends StatefulWidget {
  final Folder folder;
  final PlayingCard? existingCard; // the card to edit, if null, creates a new card

  const AddEditCardScreen({
    super.key,
    required this.folder,
    this.existingCard,
  });

  @override
  State<AddEditCardScreen> createState() => _AddEditCardScreenState();
}

class _AddEditCardScreenState extends State<AddEditCardScreen> {
  final _cardRepo = CardRepository();
  final _folderRepo = FolderRepository();

  List<Folder> _allFolders = [];
  String? _selectedSuit;  // the selected suit from the dropdown
  int? _selectedFolderId; // the selected folder id

  bool _saving = false; // true when a save operation is in progress to prevent duplicate saves

  static const _suits = ['Hearts', 'Spades'];

  static const _cardNames = [
    'Ace', '2', '3', '4', '5', '6', '7',
    '8', '9', '10', 'Jack', 'Queen', 'King'
  ];

  String? _selectedCardName;  // card name selected from the dropdown

  bool get _isEditing => widget.existingCard != null; // true if editing an existing card, false if adding a new one.

  @override
  void initState() {
    super.initState();
    _loadFolders();

    if (_isEditing) {
      // pre-fill all fields with the existing values
      final c = widget.existingCard!;
      _selectedCardName = _cardNames.contains(c.cardName) ? c.cardName : _cardNames.first;
      _selectedSuit = c.suit;
      _selectedFolderId = c.folderId;
    } else {
      // new cards default to the folder this screen was opened from
      _selectedSuit = widget.folder.folderName;
      _selectedFolderId = widget.folder.id;
    }
  }

  // loads all folders from the database to populate the folder dropdown.
  Future<void> _loadFolders() async {
    final folders = await _folderRepo.getAllFolders();
    setState(() => _allFolders = folders);
  }

  // builds the asset image path for a card based on its suit and name
  String _buildImageUrl(String suit, String cardName) =>
      'assets/cards/${suit.toLowerCase()}_$cardName.png';

  // validates inputs, then inserts or updates the card in the database.
  Future<void> _save() async {
    final name = _selectedCardName;

    if (name == null) {
      _showSnack('Please select a card name');
      return;
    }
    if (_selectedSuit == null) {
      _showSnack('Please select a suit');
      return;
    }
    if (_selectedFolderId == null) {
      _showSnack('Please select a folder');
      return;
    }

    setState(() => _saving = true);
    try {
      final imageUrl = _buildImageUrl(_selectedSuit!, name);

      if (_isEditing) {
        // update the existing card using copyWith to only change modified fields
        await _cardRepo.updateCard(
          widget.existingCard!.copyWith(
            cardName: name,
            suit: _selectedSuit,
            imageUrl: imageUrl,
            folderId: _selectedFolderId,
          ),
        );
        _showSnack('Card updated');
      } else {
        // insert a new card into the database
        await _cardRepo.insertCard(PlayingCard(
          cardName: name,
          suit: _selectedSuit!,
          imageUrl: imageUrl,
          folderId: _selectedFolderId!,
        ));
        _showSnack('Card added');
      }

      // return to the previous screen after a successful save
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnack('Error saving card: $e');
    } finally {
      // re-enables the save button whether the operation succeeded or failed
      setState(() => _saving = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green, // green background
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        title: Text(
          _isEditing ? 'Edit Card' : 'Add Card',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // card name dropdown
            _label('Card Name'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedCardName,
              decoration: _inputDecoration('Select card name'),
              items: _cardNames
                  .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCardName = v),
            ),

            const SizedBox(height: 20),

            // suit dropdown
            _label('Suit'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedSuit,
              decoration: _inputDecoration('Select suit'),
              items: _suits
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSuit = v),
            ),

            const SizedBox(height: 20),

            // folder dropdown
            _label('Folder'),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: _selectedFolderId,
              decoration: _inputDecoration('Select folder'),
              items: _allFolders
                  .map((f) => DropdownMenuItem(
                  value: f.id, child: Text(f.folderName)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedFolderId = v),
            ),

            const SizedBox(height: 32),

            // image preview
            if (_selectedSuit != null && _selectedCardName != null) ...[
              _label('Image Preview'),
              const SizedBox(height: 8),
              Center(
                child: SizedBox(
                  height: 120,
                  child: Image.asset(
                    _buildImageUrl(_selectedSuit!, _selectedCardName!),
                    errorBuilder: (_, __, ___) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported,
                            size: 48, color: Colors.white54),
                        const SizedBox(height: 8),
                        const Text(
                          'No image found for this card',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // save button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : Text(
                _isEditing ? 'Save Changes' : 'Add Card',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Styled label widget label for each field
  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
        color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );
}