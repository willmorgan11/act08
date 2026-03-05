import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../repositories/folder_repository.dart';
import '../repositories/card_repository.dart';
import 'cards_screen.dart';

class FoldersScreen extends StatefulWidget {
  @override
  _FoldersScreenState createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State {
  final FolderRepository _folderRepository = FolderRepository();
  final CardRepository _cardRepository = CardRepository();
  List _folders = [];
  Map _cardCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future _loadFolders() async {
    setState(() => _isLoading = true);

    final folders = await _folderRepository.getAllFolders();
    final Map counts = {};

    for (var folder in folders) {
      counts[folder.id!] = await _cardRepository.getCardCountByFolder(folder.id!);
    }

    setState(() {
      _folders = folders;
      _cardCounts = counts;
      _isLoading = false;
    });
  }

  Future _deleteFolder(Folder folder) async {
    final confirmed = await showDialog(
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
          ? const Center(child: CircularProgressIndicator()) // loading indicator
          : _folders.isEmpty
          ? const Center(child: Text('No folders yet. Add one.'))
          : GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: _folders.length,
              itemBuilder: (context, index) {
                final folder = _folders[index];
                final cardCount = _cardCounts[folder.id!] ?? 0;

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CardsScreen(folder: folder),
                        ),
                      );
                      _loadFolders(); // Refresh after returning
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getSuitIcon(folder.folderName),
                          size: 64,
                          color: _getSuitColor(folder.folderName),
                        ),
                        SizedBox(height: 8),
                        Text(
                          folder.folderName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$cardCount cards',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteFolder(folder),
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
      case 'Hearts':
        return Colors.red;
      case 'Spades':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }
}