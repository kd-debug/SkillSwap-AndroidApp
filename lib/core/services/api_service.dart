import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/api_demo/model/post_model.dart';

class ApiService {
  final String baseUrl = 'https://jsonplaceholder.typicode.com';

  Future<List<PostModel>> getPosts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/posts'));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<PostModel> posts = body
            .map(
              (dynamic item) => PostModel.fromJson(item),
            )
            .toList();
        return posts;
      } else {
        throw Exception('Failed to load posts');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  Future<PostModel> createPost(String title, String body, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'title': title,
          'body': body,
          'userId': userId,
        }),
      );

      if (response.statusCode == 201) {
        return PostModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create post');
      }
    } catch (e) {
      throw Exception('Error creating post: $e');
    }
  }

  Future<void> deletePost(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/posts/$id'),
      );

      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception('Failed to delete post');
      }
    } catch (e) {
      throw Exception('Error deleting post: $e');
    }
  }
}
