import 'package:flutter/material.dart';
import 'package:alertmate/model/newslist.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  // The current filter value
  String currentFilter = "All";

  // Controller for the search bar
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Filtered news items based on the current filter and search query
    List<Map<String, String>> filteredNewsItems = allNewsItems.where((item) {
      final matchesFilter =
          currentFilter == "All" || item["source"] == currentFilter;
      final matchesSearch = searchController.text.isEmpty ||
          item["title"]!
              .toLowerCase()
              .contains(searchController.text.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'News',
          style: TextStyle(fontWeight: FontWeight.bold), // Bold title
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {}); // Trigger UI refresh on search query change
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                hintText: 'Search',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChipWidget(
                    label: "All",
                    isSelected: currentFilter == "All",
                    onSelected: () {
                      setState(() {
                        currentFilter = "All";
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChipWidget(
                    label: "RAPPLER",
                    isSelected: currentFilter == "RAPPLER",
                    onSelected: () {
                      setState(() {
                        currentFilter = "RAPPLER";
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChipWidget(
                    label: "GMA NEWS",
                    isSelected: currentFilter == "GMA NEWS",
                    onSelected: () {
                      setState(() {
                        currentFilter = "GMA NEWS";
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChipWidget(
                    label: "ABS-CBN",
                    isSelected: currentFilter == "ABS-CBN",
                    onSelected: () {
                      setState(() {
                        currentFilter = "ABS-CBN";
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // News List
            Expanded(
              child: ListView.builder(
                itemCount: filteredNewsItems.length,
                itemBuilder: (context, index) {
                  final news = filteredNewsItems[index];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewsDetailScreen(
                            source: news["source"]!,
                            title: news["title"]!,
                            author: news["author"]!,
                            date: news["date"]!,
                            description: news["description"]!,
                            heroTag:
                                "news_${index}", // Unique tag based on index
                          ),
                        ),
                      );
                    },
                    child: NewsCardWidget(
                      source: news["source"]!,
                      title: news["title"]!,
                      author: news["author"]!,
                      date: news["date"]!,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

// Custom Widget for Filter Chips
class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const FilterChipWidget({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[800],
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.grey[300],
      selectedColor: Colors.teal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

// Custom Widget for News Cards
class NewsCardWidget extends StatelessWidget {
  final String source;
  final String title;
  final String author;
  final String date;

  const NewsCardWidget({
    required this.source,
    required this.title,
    required this.author,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 50, height: 50, color: Colors.grey[300]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(source,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 4),
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text("$author • $date",
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Detail Screen for News
class NewsDetailScreen extends StatelessWidget {
  final String source;
  final String title;
  final String author;
  final String date;
  final String description;
  final String? heroTag;

  const NewsDetailScreen({
    required this.source,
    required this.title,
    required this.author,
    required this.date,
    required this.description,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    // Fallback for invalid or missing heroTag
    final resolvedHeroTag =
        heroTag ?? 'default-${DateTime.now().millisecondsSinceEpoch}';

    return Scaffold(
      appBar: AppBar(title: Text(source)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: resolvedHeroTag,
              child: Material(
                color: Colors.transparent,
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text("By $author • $date",
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Text(description, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
