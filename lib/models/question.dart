// lib/models/question.dart
class Question {
  final int id;
  final int quizId;
  final String questionText;

  Question({required this.id, required this.quizId, required this.questionText});

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      quizId: json['quiz'],
      questionText: json['question_text'],
    );
  }
}