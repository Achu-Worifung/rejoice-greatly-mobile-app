import 'package:flutter/material.dart';
import '../components/Moderation_Card.dart';
import '../theme/church_colors.dart';
import '../widgets/church_app_bar.dart';

class ContentModerationPage extends StatefulWidget {
  const ContentModerationPage({super.key});

  @override
  State<ContentModerationPage> createState() => _ContentModerationPageState();
}

class _ContentModerationPageState extends State<ContentModerationPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChurchColors.background,
      appBar: ChurchAppBar.of(
        title: const Text('Content moderation', style: ChurchAppBar.titleStyle),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ChurchColors.button,
          indicatorWeight: 3,
          labelColor: ChurchColors.accent,
          unselectedLabelColor: ChurchColors.muted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          tabs: const [
            Tab(text: 'Sermons'),
            Tab(text: 'Events'),
            Tab(text: 'Verses'),
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
        backgroundColor: ChurchColors.button,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onPressed: () => _openEditor(context),
        child: const Icon(Icons.add, color: ChurchColors.buttonText),
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