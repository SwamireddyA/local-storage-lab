
import 'package:flutter/material.dart';
import 'database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final helper = DatabaseHelper();

  try {
    await helper.init();
    runApp(DirectoryApp(helper: helper));
  } catch (error, stackTrace) {
    debugPrint('Database initialization failed: $error\n$stackTrace');
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Could not open local storage. Check the logs.'),
        ),
      ),
    ));
  }
}

class DirectoryApp extends StatelessWidget {
  const DirectoryApp({super.key, required this.helper});

  final DatabaseHelper helper;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Folders and Cards',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        useMaterial3: true,
      ),
      home: FolderScreen(helper: helper),
    );
  }
}

class FolderScreen extends StatefulWidget {
  const FolderScreen({super.key, required this.helper});

  final DatabaseHelper helper;

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  List<Map<String, dynamic>> folders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadFolders();
  }

  Future<void> loadFolders() async {
    try {
      final result = await widget.helper.getFoldersWithCounts();
      if (!mounted) return;
      setState(() {
        folders = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load folders: $e')),
      );
    }
  }

  Future<void> addFolder() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Folder name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (name == null || name.trim().isEmpty) return;

    try {
      await widget.helper.insertFolder(name);
      await loadFolders();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Folder created.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not create folder. Check for a duplicate name.'),
        ),
      );
    }
  }

  Future<void> deleteFolder(Map<String, dynamic> folder) async {
    final id = folder['id'] as int;
    final name = folder['name'] as String;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete folder?'),
        content: Text(
          'Delete "$name" and all its cards? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.helper.deleteFolder(id);
      await loadFolders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete folder: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Folders')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addFolder,
        icon: const Icon(Icons.create_new_folder),
        label: const Text('Add folder'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : folders.isEmpty
              ? const Center(
                  child: Text(
                    'No folders yet.\nTap Add folder to get started.',
                    textAlign: TextAlign.center,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadFolders,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      top: 12,
                      bottom: 90,
                    ),
                    itemCount: folders.length,
                    itemBuilder: (context, index) {
                      final folder = folders[index];
                      final id = folder['id'] as int;
                      final name = folder['name'] as String;
                      final count = folder['card_count'] as int;

                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.folder,
                            color: Colors.deepOrange,
                            size: 34,
                          ),
                          title: Text(name),
                          subtitle: Text('$count card(s) • ID $id'),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CardsScreen(
                                  helper: widget.helper,
                                  folderId: id,
                                  folderName: name,
                                ),
                              ),
                            );
                            await loadFolders();
                          },
                          trailing: IconButton(
                            tooltip: 'Delete folder',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => deleteFolder(folder),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class CardsScreen extends StatefulWidget {
  const CardsScreen({
    super.key,
    required this.helper,
    required this.folderId,
    required this.folderName,
  });

  final DatabaseHelper helper;
  final int folderId;
  final String folderName;

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  List<Map<String, dynamic>> cards = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadCards();
  }

  Future<void> loadCards() async {
    try {
      final result = await widget.helper.getCards(widget.folderId);
      if (!mounted) return;
      setState(() {
        cards = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load cards: $e')),
      );
    }
  }

  Future<Map<String, String>?> showCardForm({
    Map<String, dynamic>? existing,
  }) async {
    final titleController =
        TextEditingController(text: existing?['title'] as String? ?? '');
    final suitController =
        TextEditingController(text: existing?['suit'] as String? ?? '');
    final notesController =
        TextEditingController(text: existing?['notes'] as String? ?? '');
    final imageController =
        TextEditingController(text: existing?['image_ref'] as String? ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Add card' : 'Edit card'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Card title',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a title.'
                        : null,
                  ),
                  TextFormField(
                    controller: suitController,
                    decoration: const InputDecoration(
                      labelText: 'Suit / category',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a suit or category.'
                        : null,
                  ),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'Notes'),
                    maxLines: 2,
                  ),
                  TextFormField(
                    controller: imageController,
                    decoration: const InputDecoration(
                      labelText: 'Image URL (optional)',
                      hintText: 'Leave blank for no image',
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext, {
                'title': titleController.text.trim(),
                'suit': suitController.text.trim(),
                'notes': notesController.text.trim(),
                'image_ref': imageController.text.trim(),
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    titleController.dispose();
    suitController.dispose();
    notesController.dispose();
    imageController.dispose();

    return result;
  }

  Future<void> addCard() async {
    final values = await showCardForm();
    if (values == null) return;

    try {
      await widget.helper.insertCard(
        title: values['title']!,
        suit: values['suit']!,
        notes: values['notes']!,
        imageRef:
            values['image_ref']!.isEmpty ? null : values['image_ref'],
        folderId: widget.folderId,
      );
      await loadCards();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add card: $e')),
      );
    }
  }

  Future<void> editCard(Map<String, dynamic> card) async {
    final values = await showCardForm(existing: card);
    if (values == null) return;

    try {
      await widget.helper.updateCard(
        id: card['id'] as int,
        title: values['title']!,
        suit: values['suit']!,
        notes: values['notes']!,
        imageRef:
            values['image_ref']!.isEmpty ? null : values['image_ref'],
        folderId: widget.folderId,
      );
      await loadCards();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update card: $e')),
      );
    }
  }

  Future<void> deleteCard(Map<String, dynamic> card) async {
    final id = card['id'] as int;
    final title = card['title'] as String;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete card?'),
        content: Text('Delete "$title" (ID $id)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.helper.deleteCard(id);
      await loadCards();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete card: $e')),
      );
    }
  }

  Widget cardImage(String? imageRef) {
    if (imageRef == null || imageRef.trim().isEmpty) {
      return const CircleAvatar(child: Icon(Icons.style));
    }

    final uri = Uri.tryParse(imageRef);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return const CircleAvatar(child: Icon(Icons.broken_image_outlined));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageRef,
        width: 54,
        height: 54,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const CircleAvatar(child: Icon(Icons.broken_image_outlined)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.folderName)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addCard,
        icon: const Icon(Icons.add),
        label: const Text('Add card'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : cards.isEmpty
              ? const Center(
                  child: Text(
                    'This folder is empty.\nTap Add card to create one.',
                    textAlign: TextAlign.center,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadCards,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      top: 12,
                      bottom: 90,
                    ),
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      final id = card['id'] as int;

                      return Card(
                        child: ListTile(
                          leading: cardImage(card['image_ref'] as String?),
                          title: Text('${card['title']}'),
                          subtitle: Text(
                            'ID $id • ${card['suit']}\n'
                            '${card['notes'] ?? ''}',
                          ),
                          isThreeLine:
                              (card['notes'] as String? ?? '').isNotEmpty,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') editCard(card);
                              if (value == 'delete') deleteCard(card);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
