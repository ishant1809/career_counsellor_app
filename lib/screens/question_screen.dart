import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../services/assessment_service.dart';

class QuestionScreen extends StatefulWidget {
  final String title;
  final Map<String, dynamic> data;
  final String? currentClass;
  final String testKey;

  const QuestionScreen({
    super.key,
    required this.title,
    required this.data,
    required this.testKey,
    this.currentClass,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  final PageController _pageController = PageController();
  final AssessmentService _apiService = AssessmentService();
  
  int _currentIndex = 0;
  bool _isSubmitting = false;
  bool _isLoadingProgress = true;
  
  List<dynamic> _questions = [];
  Map<String, dynamic> _answers = {};
  
  // For standard modules that use field_configs
  Map<String, dynamic> _configs = {};

  @override
  void initState() {
    super.initState();
    _initializeTest();
  }

  Future<void> _initializeTest() async {
    try {
      // 1. Prepare questions list
      if (widget.testKey == "eq" || widget.testKey == "orientation" || widget.testKey == "interest") {
        _questions = widget.data['questions'] ?? [];
      } else {
        final Map<String, dynamic> rawQuestions = widget.data['questions'] ?? {};
        _configs = (rawQuestions['field_configs'] is Map)
            ? Map<String, dynamic>.from(rawQuestions['field_configs'])
            : (widget.data['field_configs'] is Map)
                ? Map<String, dynamic>.from(widget.data['field_configs'])
                : {};

        final entries = rawQuestions.entries.where((e) =>
            e.key != "null" &&
            e.key.isNotEmpty &&
            e.value != null &&
            e.key != "field_configs").toList();
            
        _questions = entries.map((e) => {"id": e.key, ... (e.value is Map ? e.value : {"text": e.value.toString()})}).toList();
      }

      // 2. Load saved progress from backend
      final progress = await _apiService.getTestProgress(widget.testKey);
      if (progress != null && progress['in_progress'] == true) {
        setState(() {
          _answers = Map<String, dynamic>.from(progress['answers'] ?? {});
          _currentIndex = progress['current_index'] ?? 0;
          _isLoadingProgress = false;
        });
        
        // Jump to saved index after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(_currentIndex);
          }
        });
      } else {
        setState(() => _isLoadingProgress = false);
      }
    } catch (e) {
      debugPrint("Error initializing test: $e");
      setState(() => _isLoadingProgress = false);
    }
  }

  void _saveProgress() {
    _apiService.saveTestProgress(
      testKey: widget.testKey,
      sessionQuestions: _questions,
      answers: _answers,
      currentIndex: _currentIndex,
    );
  }

  void _handleAnswer(String questionId, dynamic value) {
    setState(() {
      _answers[questionId] = value;
    });
    _saveProgress();
    
    // Auto-advance for multiple choice/Likert after a short delay
    if (_currentIndex < _questions.length - 1) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProgress) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.student)),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text("No questions available.")),
      );
    }

    final double progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.title.toUpperCase(),
              style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
            const SizedBox(height: 4),
            Text(
              "${_currentIndex + 1} of ${_questions.length}",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress bar
          Container(
            height: 4,
            width: double.infinity,
            color: Colors.grey.shade100,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.student, Color(0xFF6A5AE0)]),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Force using buttons for control
              itemCount: _questions.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final q = _questions[index];
                return _buildQuestionPage(q);
              },
            ),
          ),
          
          _buildNavigationFooter(),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(dynamic q) {
    final String qId = q['id']?.toString() ?? "";
    final String text = q['text'] ?? q['question_text'] ?? "No question text";
    final category = q['category'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (category != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.student.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category.toString().toUpperCase(),
                style: const TextStyle(color: AppTheme.student, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
            
          Text(
            text,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A2138), height: 1.3),
          ),
          
          const SizedBox(height: 40),
          
          Expanded(
            child: SingleChildScrollView(
              child: _buildInputForQuestion(qId, q),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputForQuestion(String qId, dynamic q) {
    final bool isPsychometric = widget.testKey == "eq" || widget.testKey == "orientation" || widget.testKey == "interest";
    
    if (isPsychometric) {
      return _buildLikertInput(qId);
    }

    // Aptitude Logic
    if (widget.testKey == "aptitude") {
      return _buildAptitudeOptions(qId, q['text'] ?? "");
    }

    // Standard Assessment Logic (Basic / Personality)
    final config = _configs[qId] ?? {};
    final String type = config['type'] ?? _inferTypeFromKey(qId);
    
    if (type == "selection") {
      final List<String> options = List<String>.from(config['options'] ?? ["Yes", "No"]);
      return Column(
        children: options.map((opt) => _buildOptionCard(qId, opt, opt)).toList(),
      );
    } else if (type == "number") {
      return TextField(
        keyboardType: TextInputType.number,
        decoration: _inputDecoration(hint: "Enter number..."),
        onChanged: (val) => _answers[qId] = int.tryParse(val),
      );
    } else {
      return TextField(
        decoration: _inputDecoration(hint: "Your answer..."),
        onChanged: (val) => _answers[qId] = val,
      );
    }
  }

  Widget _buildLikertInput(String qId) {
    final List<String> labels = ["Strongly Disagree", "Disagree", "Neutral", "Agree", "Strongly Agree"];
    final currentVal = _answers[qId];

    return Column(
      children: List.generate(5, (i) {
        final int score = i + 1;
        final bool isSelected = currentVal == score;
        return _buildOptionCard(qId, labels[i], score, isSelected: isSelected);
      }),
    );
  }

  Widget _buildAptitudeOptions(String qId, String rawText) {
    // Basic parser for A) B) C) D) format
    final a = RegExp(r"A\) (.*?)(?=B\)|$)").firstMatch(rawText.replaceAll('\n', ' '))?.group(1)?.trim();
    final b = RegExp(r"B\) (.*?)(?=C\)|$)").firstMatch(rawText.replaceAll('\n', ' '))?.group(1)?.trim();
    final c = RegExp(r"C\) (.*?)(?=D\)|$)").firstMatch(rawText.replaceAll('\n', ' '))?.group(1)?.trim();
    final d = RegExp(r"D\) (.*?)(?=Correct|Explanation|$)").firstMatch(rawText.replaceAll('\n', ' '))?.group(1)?.trim();

    if (a == null || b == null || c == null || d == null) {
      return const Text("Format Error in question text.");
    }

    final options = {"A": a, "B": b, "C": c, "D": d};
    return Column(
      children: options.entries.map((e) => _buildOptionCard(qId, "${e.key}) ${e.value}", e.key)).toList(),
    );
  }

  Widget _buildOptionCard(String qId, String label, dynamic value, {bool? isSelected}) {
    final bool selected = isSelected ?? (_answers[qId] == value);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _handleAnswer(qId, value),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: selected ? AppTheme.student.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppTheme.student : Colors.grey.shade200,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppTheme.student : const Color(0xFF1A2138),
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppTheme.student, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationFooter() {
    final bool isLast = _currentIndex == _questions.length - 1;
    final bool canGoBack = _currentIndex > 0;
    final bool isAnswered = _answers.containsKey(_questions[_currentIndex]['id']?.toString());

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          if (canGoBack)
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("PREVIOUS", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          if (canGoBack) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: !isAnswered || _isSubmitting ? null : (isLast ? _handleSubmit : () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.student,
                minimumSize: const Size(0, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(isLast ? "SUBMIT" : "NEXT", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit() async {
    setState(() => _isSubmitting = true);
    try {
      final bool isPsychometric = widget.testKey == "eq" || widget.testKey == "orientation" || widget.testKey == "interest";
      
      bool success;
      if (isPsychometric) {
        final List<Map<String, dynamic>> answerList = _answers.entries
            .map((e) => {"question_id": int.tryParse(e.key) ?? 0, "score": e.value})
            .toList();
        success = await _apiService.submitAnswers(widget.title, {}, psychometricAnswers: answerList);
      } else {
        success = await _apiService.submitAnswers(widget.title, _answers);
      }

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          Navigator.pop(context, {"success": true, "answers": _answers});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Submission failed.")));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  String _inferTypeFromKey(String key) {
    if (key.contains("gender") || key.contains("class") || key.contains("school") || key.contains("medium")) return "selection";
    return "text";
  }

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade50,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(20),
      );
}