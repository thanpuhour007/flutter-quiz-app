// lib/services/quiz_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/answer.dart';
import '../models/question.dart';
import '../models/quiz.dart';

class QuizService {
  static Future<List<Quiz>> fetchQuizzes() async {
    final response = await http.get(Uri.parse('http://localhost:5000/api/quizzes/'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((quiz) => Quiz.fromJson(quiz)).toList();
    } else {
      throw Exception('Failed to load quizzes');
    }
  }

  static Future<List<Question>> fetchQuestions(int quizId) async {
    final response = await http.get(Uri.parse('http://localhost:5000/api/quizzes/$quizId/questions/'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((question) => Question.fromJson(question)).toList();
    } else {
      throw Exception('Failed to load questions');
    }
  }

  static Future<List<Answer>> fetchAnswers() async {
    final response = await http.get(Uri.parse('http://localhost:5000/api/answers/'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((answer) => Answer.fromJson(answer)).toList();
    } else {
      throw Exception('Failed to load answers');
    }
  }
}