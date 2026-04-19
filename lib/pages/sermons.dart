import 'package:flutter/material.dart';

class SermonsPage extends StatefulWidget {
  final Map<String, dynamic> data;
  const SermonsPage({super.key, required this.data});

  @override
  State<SermonsPage> createState() => _SermonsPageState();
}

class _SermonsPageState extends State<SermonsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {

    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    //fetch sermons data here if needed, or use widget.data if already passed in
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFD27E09);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7EB), // Matches your scaffold bg
      appBar: AppBar(
        toolbarHeight: 120,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          children: [
            // 1. Search Bar
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.zero, // Keep it square
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search sermons...',
                  prefixIcon: Icon(Icons.search, color: gold),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
        // 2. Tab Bar
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: gold,
          labelColor: gold,
          unselectedLabelColor: Colors.grey,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'ALL SERMONS'),
            Tab(text: 'SAVED'),
          ],
        ),
      ),
      // 3. Swipeable Content
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSermonList(isSavedOnly: false),
          _buildSermonList(isSavedOnly: true),
        ],
      ),
    );
  }

  Widget _buildSermonList({required bool isSavedOnly}) {
    // This is where you'd filter your data or call your SermonCard
    return ListView.builder(
      padding: const EdgeInsets.only(top: 10),
      itemCount: 5, // Placeholder
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: ListTile(
            tileColor: Colors.white,
            leading: const CircleAvatar(
              backgroundImage: NetworkImage('https://picsum.photos/200'),
            ),
            title: Text(isSavedOnly ? 'Saved Sermon $index' : 'Sermon Title $index'),
            subtitle: const Text('Pastor John Smith • Nov 20, 2023'),
            trailing: Icon(
              isSavedOnly ? Icons.bookmark : Icons.bookmark_border,
              color: const Color(0xFFD27E09),
            ),
          ),
        );
      },
    );
  }
}