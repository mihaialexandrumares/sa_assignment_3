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
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          prefixIconColor: Colors.indigo,
        ),
        cardTheme: CardThemeData(
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
  // NOTE: Ensure your backend is running on port 8080
  // For Android Emulator use 'http://10.0.2.2:8080/api/books'
  // For iOS/Web use 'http://localhost:8080/api/books'
  final String baseUrl = 'http://localhost:8080/api/books';

  List<dynamic> books = [];
  List<String> featuredBooks = [];
  List<String> logs = [];

  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final priceController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadBooks();
  }

  Future<void> loadBooks() async {
    setState(() => isLoading = true);
    try {
      var response = await http.get(Uri.parse(baseUrl));
      var featuredResponse = await http.get(Uri.parse('$baseUrl/featured'));

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
        Uri.parse(baseUrl),
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
      await http.delete(Uri.parse('$baseUrl/$id'));

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
        backgroundColor: Colors.indigo,
        elevation: 0,
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
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
                  backgroundColor: Colors.indigo,
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
            color: Color(0xFF1E1E1E), // Dark terminal background
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
              backgroundColor: Colors.indigo.shade50,
              labelStyle: TextStyle(color: Colors.indigo),
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
                  backgroundColor: Colors.indigo.shade100,
                  child: Text(
                    book['title'][0].toString().toUpperCase(),
                    style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
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