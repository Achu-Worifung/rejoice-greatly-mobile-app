import 'package:flutter/material.dart';
import '../components/Moderation_Card.dart';

class ContentModerationPage extends StatefulWidget {
  const ContentModerationPage({super.key});

  @override
  State<ContentModerationPage> createState() => _ContentModerationPageState();
}

class _ContentModerationPageState extends State<ContentModerationPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color gold = const Color(0xFFD27E09);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7EB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('CONTENT MODERATION', 
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: gold,
          labelColor: gold,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'SERMONS'),
            Tab(text: 'EVENTS'),
            Tab(text: 'VERSES'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildModerationList(type: 'sermon'),
          _buildModerationList(type: 'event'),
          _buildModerationList(type: 'verse'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: gold,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        onPressed: () => _openEditor(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildModerationList({required String type}) {
    // In a real app, this would be a FutureBuilder calling your Spring Boot API
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5, 
      itemBuilder: (context, index) {
        return ModerationCard(
          title: '$type Title $index',
          subtitle: 'Last updated: Oct 20, 2026',
          onEdit: () => _openEditor(context),
          onDelete: () => _confirmDelete(context),
        );
      },
    );
  }

  void _openEditor(BuildContext context) {
    // Modular Edit/Create Form logic
  }

  void _confirmDelete(BuildContext context) {
    // Delete confirmation logic
  }
}