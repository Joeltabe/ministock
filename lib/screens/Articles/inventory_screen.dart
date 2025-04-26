import 'package:flutter/material.dart';
import 'package:ministock/services/DatabaseHelper.dart';
import 'package:ministock/models/article.dart';
import 'package:ministock/screens/Articles/AddEditArticleScreen.dart';

class InventoryScreen extends StatefulWidget {
  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Article> articles = [];
  bool isLoading = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    refreshArticles();
  }

  Future refreshArticles() async {
    setState(() => isLoading = true);
    this.articles = await DatabaseHelper.instance.readAllArticles();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final filteredArticles = articles.where((article) =>
      article.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
      article.reference.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddEditArticleScreen()),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text('Inventory'),
            floating: true,
            actions: [
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: ArticleSearch(articles),
                  );
                },
              ),
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: isLoading
                ? SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : filteredArticles.isEmpty
                    ? SliverFillRemaining(
                        child: Center(child: Text('No articles found')),
                      )
                    : SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.3,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildArticleCard(filteredArticles[index]),
                          childCount: filteredArticles.length,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(Article article) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditArticleScreen(article: article),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: article.image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          article.image!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.inventory_2_rounded,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
              SizedBox(height: 12),
              Text(
                article.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Text(
                article.reference,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${article.priceTTC.toStringAsFixed(2)} cfa',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.indigo,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      article.category ?? 'General',
                      style: TextStyle(
                        color: Colors.indigo,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArticleSearch extends SearchDelegate<Article?> {
  final List<Article> articles;

  ArticleSearch(this.articles);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = articles.where((article) =>
      article.title.toLowerCase().contains(query.toLowerCase()) ||
      article.reference.toLowerCase().contains(query.toLowerCase())
    ).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final article = results[index];
        return ListTile(
          leading: article.image != null
              ? CircleAvatar(
                  backgroundImage: MemoryImage(article.image!),
                )
              : CircleAvatar(
                  child: Icon(Icons.inventory_2_rounded),
                ),
          title: Text(article.title),
          subtitle: Text(article.reference),
          trailing: Text('${article.priceTTC.toStringAsFixed(2)} €'),
          onTap: () {
            close(context, article);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditArticleScreen(article: article),
              ),
            );
          },
        );
      },
    );
  }
}