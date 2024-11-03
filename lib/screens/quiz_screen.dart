import 'dart:async';
import 'package:flutter/material.dart';
import '../models/answer.dart';
import '../models/question.dart';
import '../models/quiz.dart';
import '../services/quiz_service.dart';

class QuizScreen extends StatefulWidget {
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Quiz> _quizzes = [];
  List<Question> _questions = [];
  List<Answer> _answers = [];
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  int _score = 0;
  bool _isAnswerChecked = false;
  int _secondsRemaining = 30;
  Timer? _timer;
  int _selectedOption = -1;
  bool _isQuizStarted = false;
  Quiz? _selectedQuiz;
  int _selectedNumberOfQuestions = 0;

  @override
  void initState() {
    super.initState();
    fetchQuizzes();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchQuizzes() async {
    try {
      _quizzes = await QuizService.fetchQuizzes();
      setState(() => _isLoading = false);
    } catch (e) {
      showErrorDialog('Failed to load quizzes');
    }
  }

  Future<void> fetchData(int quizId, int numberOfQuestions) async {
    try {
      _questions = (await QuizService.fetchQuestions(quizId))
          .take(numberOfQuestions)
          .toList();
      _answers = await QuizService.fetchAnswers();

      setState(() {
        _isLoading = false;
        _isQuizStarted = true;
      });
      startTimer();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isQuizStarted = false;
      });
      showErrorDialog('Failed to load data');
    }
  }

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
        showTimeoutDialog();
      } else {
        if (mounted) {
          setState(() => _secondsRemaining--);
        }
      }
    });
  }

  void showTimeoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Time\'s Up!'),
        content: Text('You ran out of time.'),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.pop(context);
              _onNextPressed();
            },
          ),
        ],
      ),
    );
  }

  void startQuiz(Quiz quiz) {
    setState(() {
      _selectedQuiz = quiz;
      _selectedOption = -1;
      _secondsRemaining = 30;
      _currentQuestionIndex = 0;
      _score = 0;
      _isAnswerChecked = false;
      _isLoading = true;
      _isQuizStarted = false;
    });
    showQuestionCountDialog();
  }

  void showQuestionCountDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Choose Questions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isQuizStarted = false;
                  _isLoading = false;
                });
              },
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Select how many questions you would like to answer:',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
            ),
            _buildQuestionCountOption('5 Questions', 5),
            _buildQuestionCountOption('10 Questions', 10),
            _buildQuestionCountOption('15 Questions', 15),
            _buildQuestionCountOption('20 Questions', 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCountOption(String title, int count) {
    return Card(
      color: Colors.blueGrey[50], // Light background for contrast
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(Icons.question_answer, color: Colors.blueAccent),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
        ),
        onTap: () {
          Navigator.pop(context);
          _selectedNumberOfQuestions = count;
          fetchData(_selectedQuiz!.id, _selectedNumberOfQuestions);
        },
      ),
    );
  }

  void resetQuiz() {
    setState(() {
      _selectedOption = -1;
      _secondsRemaining = 30;
      _currentQuestionIndex = 0;
      _score = 0;
      _isAnswerChecked = false;
      _isQuizStarted = false;
      _selectedQuiz = null;
      _selectedNumberOfQuestions = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.indigo.shade50],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.indigo))
                : !_isQuizStarted
                    ? Center(
                        child:
                            _buildQuizSelection()) // Centering the quiz selection
                    : _questions.isEmpty
                        ? _buildNoQuestions()
                        : _buildQuizContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizSelection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center, // Center vertically
      crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
      children: [
        Text(
          'Choose a Quiz',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade900,
          ),
        ),
        SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _quizzes.length,
            itemBuilder: (context, index) => _buildQuizCard(_quizzes[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizCard(Quiz quiz) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => startQuiz(quiz),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.quiz, color: Colors.indigo),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      'Score: $_score',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer, color: Colors.red),
                      SizedBox(width: 4),
                      Text(
                        '$_secondsRemaining s',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / _questions.length,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                minHeight: 8,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizContent() {
    return Column(
      children: [
        _buildHeader(),
        SizedBox(height: 24),
        _buildQuestion(),
        SizedBox(height: 24),
        _buildOptions(),
        if (_isAnswerChecked) ...[
          SizedBox(height: 24),
          _buildNextButton(),
        ],
      ],
    );
  }

  Widget _buildQuestion() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          _questions[_currentQuestionIndex].questionText,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildOptions() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: _answers
              .where((answer) =>
                  answer.questionId == _questions[_currentQuestionIndex].id)
              .map((answer) => _buildOption(answer))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildOption(Answer answer) {
    bool isSelected = _selectedOption == answer.id;
    bool isDisabled = _isAnswerChecked && !isSelected;
    bool isCorrectAnswer = answer.isCorrect && _isAnswerChecked;

    Color getBackgroundColor() {
      if (isSelected && _isAnswerChecked) {
        return answer.isCorrect ? Colors.green.shade50 : Colors.red.shade50;
      }
      if (isCorrectAnswer) return Colors.green.shade50;
      return isDisabled ? Colors.grey.shade100 : Colors.white;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: isDisabled ? null : () => _onOptionSelected(answer),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: getBackgroundColor(),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? (answer.isCorrect ? Colors.green : Colors.red)
                  : isCorrectAnswer
                      ? Colors.green
                      : Colors.grey.shade300,
              width: 2,
            ),
            boxShadow: [
              if (!isDisabled)
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
            ],
          ),
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  answer.answerText,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDisabled ? Colors.grey : Colors.black87,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected || isCorrectAnswer)
                Icon(
                  isCorrectAnswer ? Icons.check_circle : Icons.cancel,
                  color: isCorrectAnswer ? Colors.green : Colors.red,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return Padding(
      padding: EdgeInsets.only(top: 16),
      child: ElevatedButton(
        onPressed: _onNextPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          minimumSize: Size(200, 50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          'Next Question',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildNoQuestions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 64,
            color: Colors.orange,
          ),
          SizedBox(height: 16),
          Text(
            'No questions available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: resetQuiz,
            child: Text('Go Back'),
          ),
        ],
      ),
    );
  }

  void _onOptionSelected(Answer answer) {
    if (!_isAnswerChecked) {
      _timer?.cancel();
      setState(() {
        _selectedOption = answer.id;
        _isAnswerChecked = true;
      });
    }
  }

  void _onNextPressed() {
    bool isCorrect = _answers
        .firstWhere((answer) => answer.id == _selectedOption,
            orElse: () => Answer(
                id: -1, questionId: -1, answerText: '', isCorrect: false))
        .isCorrect;
    if (isCorrect) {
      setState(() => _score++);
    }

    _timer?.cancel();
    setState(() {
      _selectedOption = -1;
      _secondsRemaining = 30;
      _isAnswerChecked = false;
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
      } else {
        showFinalScoreDialog();
      }
    });
    startTimer();
  }

  void showFinalScoreDialog() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 30;
      _isAnswerChecked = false;
      _isQuizStarted = false;
      _selectedQuiz = null;
      _selectedNumberOfQuestions = 0;
    });
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental closure
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(16), // Rounded corners for a modern look
        ),
        title: Column(
          children: [
            Icon(
              Icons.emoji_events, // Trophy icon for celebration
              size: 64,
              color: Colors.amber,
            ),
            SizedBox(height: 16),
            Text(
              'Congratulations!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
        content: Text(
          'You scored $_score out of ${_questions.length}!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              'OK',
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              resetQuiz();
            },
          ),
        ],
      ),
    );
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
