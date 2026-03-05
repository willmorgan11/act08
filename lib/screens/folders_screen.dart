import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../repositories/folder_repository.dart';
import '../repositories/card_repository.dart';
import 'cards_screen.dart';

class FoldersScreen extends StatefulWidget {
  @override
  _FoldersScreenState createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final FolderRepository _folderRepository = FolderRepository();
  final CardRepository _cardRepository = CardRepository();
  List<Folder> _folders = [];
  Map<int, int> _cardCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() => _isLoading = true);

    final folders = await _folderRepository.getAllFolders();
    final Map<int, int> counts = {};

    for (var folder in folders) {
      counts[folder.id!] = await _cardRepository.getCardCountByFolder(folder.id!);
    }

    setState(() {
      _folders = folders;
      _cardCounts = counts;
      _isLoading = false;
    });
  }

  Future<void> _deleteFolder(Folder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Folder?'),
        content: Text(
            'Are you sure you want to delete "${folder.folderName}"? '
                'This will also delete all ${_cardCounts[folder.id!]} cards in this folder.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _folderRepository.deleteFolder(folder.id!);
      _loadFolders();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Folder "${folder.folderName}" deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Card Organizer'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _folders.isEmpty
          ? const Center(child: Text('No folders yet. Add one.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _folders.length,
        itemBuilder: (context, index) {
          final folder = _folders[index];
          final cardCount = _cardCounts[folder.id!] ?? 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // navigates into folder
                  Expanded(
                    child: InkWell(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CardsScreen(folder: folder),
                          ),
                        );
                        _loadFolders(); // loads selected folder
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: Row(
                          children: [
                            Icon(
                              _getSuitIcon(folder.folderName),
                              size: 56,
                              color: _getSuitColor(folder.folderName),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    folder.folderName,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$cardCount cards',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // delete button
                  InkWell(
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                    onTap: () => _deleteFolder(folder),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: Icon(Icons.delete, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getSuitIcon(String suitName) {
    switch (suitName) {
      case 'Hearts': return Icons.favorite;
      case 'Spades': return Icons.eco;
      default: return Icons.help;
    }
  }

  Color _getSuitColor(String suitName) {
    switch (suitName) {
      case 'Hearts': return Colors.red;
      case 'Spades': return Colors.black;
      default: return Colors.grey;
    }
  }
}