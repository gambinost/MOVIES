import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

void main() => runApp(const MovieApp());

class MovieApp extends StatelessWidget {
  const MovieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Movie Recommender',
        home: const MovieRecommendationPage(),
        theme: ThemeData.dark().copyWith(
            primaryColor: Colors.tealAccent,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            textTheme: ThemeData.dark().textTheme.apply(
                  fontFamily: 'Roboto',
                  bodyColor: Colors.white,
                  displayColor: Colors.white,
                )));
  }
}

class MovieRecommendationPage extends StatefulWidget {
  const MovieRecommendationPage({super.key});

  @override
  _MovieRecommendationPageState createState() =>
      _MovieRecommendationPageState();
}

class _MovieRecommendationPageState extends State<MovieRecommendationPage> {
  List<dynamic> recommendations = [];
  bool isLoading = false;
  final TextEditingController controller = TextEditingController();
  final List<String> genres = [
    'Action',
    'Comedy',
    'Drama',
    'Horror',
    'Romance',
    'Science Fiction',
    'Adventure'
  ];
  String selectedGenre = 'Action';

  Future<void> fetchRecommendations(String title) async {
    setState(() => isLoading = true);
    final uri = Uri.parse(
        'http://192.168.1.8:5000/recommend_by_movie?title=$title&k=10');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      setState(() {
        recommendations = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load recommendations')));
    }
  }

  Future<void> fetchByGenre() async {
    setState(() => isLoading = true);
    final uri = Uri.parse(
        'http://192.168.1.8:5000/recommend_by_genre?genre=$selectedGenre&top_n=10');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      setState(() {
        recommendations = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load genre recommendations')));
    }
  }

  Widget buildMovieCard(movie) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Column(
        children: [
          CachedNetworkImage(
            imageUrl: movie['poster_path'],
            placeholder: (context, url) => const SizedBox(
                height: 200, child: Center(child: CircularProgressIndicator())),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            height: 500,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(movie['title'],
                    style:
                        const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (movie['tagline'] != "unknown")
                  Text(movie['tagline'],
                      style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[400])),
                const SizedBox(height: 6),
                Text(movie['overview'], style: const TextStyle(fontSize: 14)),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Movie Recommendations")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Enter a movie title',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => fetchRecommendations(controller.text),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  hintText: 'Search for a movie',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: selectedGenre,
                      items: genres.map((genre) {
                        return DropdownMenuItem(
                            value: genre, child: Text(genre));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedGenre = value);
                        }
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: fetchByGenre,
                    child: const Text("Get Top by Genre"),
                  )
                ],
              ),
            ),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : recommendations.isEmpty
                    ? const Center(
                        child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text("No recommendations yet."),
                      ))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recommendations.length,
                        itemBuilder: (context, index) =>
                            buildMovieCard(recommendations[index]),
                      ),
          ],
        ),
      ),
    );
  }
}
