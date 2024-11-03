// lib/models/quiz.dart
class Quiz {
  final int id;
  final String title;

  Quiz({required this.id, required this.title});

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      title: json['title'],
    );
  }
}