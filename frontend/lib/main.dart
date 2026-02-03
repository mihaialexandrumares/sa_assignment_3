import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Library Architecture Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple.shade600,
          brightness: Brightness.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          prefixIconColor: Colors.deepPurple.shade600,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          surfaceTintColor: Colors.white,
        ),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String apiBase = 'http://localhost:8080';

  late String booksUrl;
  late String aiUrl;

  List<dynamic> books = [];
  List<String> featuredBooks = [];
  List<String> logs = [];

  List<Map<String, String>> chatHistory = [];
  final chatController = TextEditingController();
  bool isAiLoading = false;

  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final priceController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    booksUrl = '$apiBase/api/books';
    aiUrl = '$apiBase/api/ai/ask';
    loadBooks();
  }

  Future<void> loadBooks() async {
    setState(() => isLoading = true);
    try {
      var response = await http.get(Uri.parse(booksUrl));
      var featuredResponse = await http.get(Uri.parse('$booksUrl/featured'));

      setState(() {
        books = json.decode(response.body);
        featuredBooks = List<String>.from(json.decode(featuredResponse.body));
        isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
      _showErrorSnackBar('Failed to connect to backend');
    }
  }

  Future<void> addBook() async {
    if (titleController.text.isEmpty ||
        authorController.text.isEmpty ||
        priceController.text.isEmpty) {
      _showErrorSnackBar('Please fill all fields');
      return;
    }

    setState(() {
      logs.clear();
      logs.add(' > [FACADE] LibraryFacade.addBook() called');
    });

    try {
      await http.post(
        Uri.parse(booksUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': titleController.text,
          'author': authorController.text,
          'price': double.parse(priceController.text),
        }),
      );

      setState(() {
        logs.add(' > [FACADE] Book added through facade');
        logs.add(' > [DECORATOR] Applying FeaturedBookDecorator');
      });

      titleController.clear();
      authorController.clear();
      priceController.clear();

      loadBooks();
      _showSuccessSnackBar('Book added successfully');
    } catch (e) {
      _showErrorSnackBar('Error adding book: $e');
    }
  }

  Future<void> deleteBook(int id) async {
    setState(() {
      logs.clear();
      logs.add(' > [FACADE] LibraryFacade.deleteBook() called');
    });

    try {
      await http.delete(Uri.parse('$booksUrl/$id'));

      setState(() {
        logs.add(' > [FACADE] Book deleted through facade');
      });

      loadBooks();
      _showSuccessSnackBar('Book deleted');
    } catch (e) {
      _showErrorSnackBar('Error deleting book');
    }
  }


  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showChatModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: StatefulBuilder(
                builder: (context, setModalState) {
                  void handleSendMessage() {
                    if (chatController.text.isNotEmpty) {
                      String msg = chatController.text;

                      setModalState(() {
                        chatHistory.add({'role': 'user', 'message': msg});
                        isAiLoading = true;
                      });
                      chatController.clear();

                      http.post(
                        Uri.parse(aiUrl),
                        headers: {'Content-Type': 'application/json'},
                        body: json.encode({'prompt': msg}),
                      ).then((response) {
                        setModalState(() {
                          isAiLoading = false;
                          if (response.statusCode == 200) {
                            var data = json.decode(response.body);
                            chatHistory.add({'role': 'ai', 'message': data['answer']});
                          } else {
                            chatHistory.add({'role': 'error', 'message': 'AI Error: ${response.statusCode}'});
                          }
                        });
                      }).catchError((e) {
                        setModalState(() {
                          isAiLoading = false;
                          chatHistory.add({'role': 'error', 'message': 'Connection Error'});
                        });
                      });
                    }
                  }

                  return Column(
                    children: [
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 10),
                        height: 5,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Row(
                          children: [
                            Icon(Icons.chat,color:Colors.deepPurple.shade600),
                            SizedBox(width: 10),
                            Text("Library AI Assistant", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            )
                          ],
                        ),
                      ),
                      Divider(),
                      Expanded(
                        child: chatHistory.isEmpty
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[300]),
                              SizedBox(height: 10),
                              Text("Ask me anything about books!", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                            : ListView.builder(
                          controller: controller,
                          padding: EdgeInsets.all(16),
                          itemCount: chatHistory.length,
                          itemBuilder: (context, index) {
                            final msg = chatHistory[index];
                            final isUser = msg['role'] == 'user';
                            return Align(
                              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: EdgeInsets.only(bottom: 12),
                                padding: EdgeInsets.all(12),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                decoration: BoxDecoration(
                                  color: isUser ? Colors.deepPurple.shade600 : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16).copyWith(
                                    bottomRight: isUser ? Radius.zero : Radius.circular(16),
                                    bottomLeft: !isUser ? Radius.zero : Radius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  msg['message'] ?? '',
                                  style: TextStyle(
                                    color: isUser ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Input Area
                      if (isAiLoading)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: LinearProgressIndicator(),
                        ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: chatController,
                                decoration: InputDecoration(
                                  hintText: "Ask AI...",
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                onSubmitted: (_) => handleSendMessage(),
                              ),
                            ),
                            SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: Colors.deepPurple.shade600,
                              child: IconButton(
                                icon: Icon(Icons.send, color: Colors.white, size: 20),
                                onPressed: handleSendMessage,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.library_books, color: Colors.white),
            SizedBox(width: 10),
            Text('Design Patterns Demo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.deepPurple.shade600,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showChatModal,
        label: Text('Ask AI'),
        icon: Icon(Icons.chat),
        backgroundColor: Colors.deepPurple.shade600,
        foregroundColor: Colors.white,
      ),
      body: isLoading && books.isEmpty
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputForm(),
            SizedBox(height: 24),
            if (logs.isNotEmpty) _buildLogConsole(),
            if (logs.isNotEmpty) SizedBox(height: 24),
            _buildFeaturedSection(),
            SizedBox(height: 24),
            _buildBookList(),
            SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildInputForm() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add New Book',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple.shade600)),
            SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Book Title',
                prefixIcon: Icon(Icons.book),
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: authorController,
                    decoration: InputDecoration(
                      labelText: 'Author',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: 'Price',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: addBook,
                icon: Icon(Icons.add_circle_outline),
                label: Text('Add to Library', style: TextStyle(fontSize: 16)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepPurple.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogConsole() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('System Logic (Patterns)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: logs.map((log) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                log,
                style: TextStyle(
                  fontFamily: 'Courier New', // Monospace font
                  color: log.contains('FACADE') ? Colors.greenAccent : Colors.amberAccent,
                  fontSize: 13,
                ),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBookList() {
    if (books.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Library Inventory',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            Chip(
              label: Text('${books.length} items'),
              backgroundColor:Colors.deepPurple.shade50,
              labelStyle: TextStyle(color:Colors.deepPurple.shade600),
            )
          ],
        ),
        SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: books.length,
          separatorBuilder: (c, i) => SizedBox(height: 8),
          itemBuilder: (context, index) {
            final book = books[index];
            return Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple.shade100,
                  child: Text(
                    book['title'][0].toString().toUpperCase(),
                    style: TextStyle(color:Colors.deepPurple.shade600, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(book['title'], style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('by ${book['author']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\$${book['price']}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[700]),
                    ),
                    SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: book['id'] != null ? () => deleteBook(book['id']) : null,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeaturedSection() {
    if (featuredBooks.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 20),
            SizedBox(width: 8),
            Text('Featured (Decorator Pattern)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber[800])),
          ],
        ),
        SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: featuredBooks.map((text) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.amber[700]),
                  SizedBox(width: 8),
                  Expanded(child: Text(text, style: TextStyle(color: Colors.brown[900]))),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
}