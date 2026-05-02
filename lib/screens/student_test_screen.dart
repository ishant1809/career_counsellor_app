import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/assessment_service.dart';
import 'question_screen.dart';
import 'ai_recommendations_screen.dart';

class StudentTestScreen extends StatefulWidget {
  const StudentTestScreen({super.key});

  @override
  State<StudentTestScreen> createState() => _StudentTestScreenState();
}

class _StudentTestScreenState extends State<StudentTestScreen> {
  final AssessmentService _apiService = AssessmentService();

  int currentStep = 0;
  bool _isLoadingProgress = true;
  String? studentCurrentClass;

  final List<Map<String, String>> steps = [
    {"title": "Basic Assessment", "subtitle": "The Starting Point", "phase": "PHASE 1: FOUNDATION"},
    {"title": "Personality", "subtitle": "Who are you truly?", "phase": "PHASE 2: THE DISCOVERY"},
    {"title": "Emotional Quotient", "subtitle": "Your emotional intelligence", "phase": "PHASE 2: THE DISCOVERY"},
    {"title": "Orientation Style", "subtitle": "Your work style preference", "phase": "PHASE 2: THE DISCOVERY"},
    {"title": "Career Interests", "subtitle": "Natural inclinations", "phase": "PHASE 2: THE DISCOVERY"},
    {"title": "Aptitude", "subtitle": "Logic & Mental agility", "phase": "PHASE 3: PERFORMANCE"},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProgress();
  }

  // --- FETCH PROGRESS ON LOAD ---
  Future<void> _loadUserProgress() async {
    try {
      final profile = await _apiService.getUserProfile();
      final progress = profile['progress'] ?? {};

      int stepIndex = 0;

      if (progress['profile_done'] == true || progress['basic_assessment_done'] == true) stepIndex = 1;
      if (stepIndex == 1 && progress['personality_done'] == true) stepIndex = 2;

      // EQ/Orientation/Interests — check top-level data fields, not progress flags
      if (stepIndex == 2 && profile['eq_data'] != null) stepIndex = 3;
      if (stepIndex == 3 && profile['orientation_data'] != null) stepIndex = 4;
      if (stepIndex == 4 && profile['career_interest_data'] != null) stepIndex = 5;

      if (stepIndex == 5 && progress['aptitude_done'] == true) stepIndex = 6;

      if (mounted) {
        setState(() {
          currentStep = stepIndex;
          _isLoadingProgress = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading progress: $e");
      if (mounted) setState(() => _isLoadingProgress = false);
    }
  }

  void _completeStep(int index) async {
    final stepTitle = steps[index]['title']!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.student)),
    );

    try {
      final data = await _apiService.fetchQuestions(stepTitle, currentClass: studentCurrentClass);
      if (!mounted) return;
      Navigator.pop(context);

      final String testKey = AssessmentService.moduleMapping[stepTitle] ?? stepTitle.toLowerCase();

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuestionScreen(
            title: stepTitle,
            data: data,
            testKey: testKey,
            currentClass: studentCurrentClass,
          ),
        ),
      );

      if (result != null && result['success'] == true) {
        // ✅ FIX: result['answers'] is a List for psychometric modules and a Map
        // for standard modules. Safely cast to Map only when it actually is one.
        final dynamic rawAnswers = result['answers'];
        final Map<String, dynamic> answers = (rawAnswers is Map)
            ? Map<String, dynamic>.from(rawAnswers)
            : {};

        // Save class if Basic Assessment
        if (stepTitle == "Basic Assessment" && answers.containsKey('current_class')) {
          setState(() {
            studentCurrentClass = answers['current_class']?.toString();
          });
        }

        // Advance step — uses steps.length (not steps.length - 1) so the
        // final step (Aptitude) also advances currentStep to 6, marking it complete
        if (index == currentStep && currentStep < steps.length) {
          setState(() => currentStep++);
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProgress) {
      return const Scaffold(
        backgroundColor: Color(0xFFF0F4FD),
        body: Center(child: CircularProgressIndicator(color: AppTheme.student)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FD),
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildHeroSection(),
                  const SizedBox(height: 30),
                  ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: steps.length,
                    itemBuilder: (context, index) {
                      final step = steps[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (step['phase']!.isNotEmpty) _buildPhaseHeader(step['phase']!),
                          _buildModernJourneyStep(index, step['title']!, step['subtitle']!),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildGenerateButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xFFF0F4FD),
      elevation: 0,
      pinned: true,
      centerTitle: true,
      title: const Text(
        "MY PATHWAY",
        style: TextStyle(
          color: Color(0xFF8E99AF),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    double progress = currentStep >= steps.length ? 1.0 : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "The Road to\nDiscovery",
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, height: 1.1, color: Color(0xFF1A2138)),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.student.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: AppTheme.student),
              const SizedBox(width: 8),
              Text(
                "${(progress * 100).toInt()}% COMPLETED",
                style: const TextStyle(color: AppTheme.student, fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    bool isReady = currentStep >= steps.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        gradient: isReady
            ? const LinearGradient(
                colors: [AppTheme.student, Color(0xFF6A5AE0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isReady ? null : AppTheme.student.withOpacity(0.15),
        borderRadius: BorderRadius.circular(22),
        boxShadow: isReady
            ? [BoxShadow(color: AppTheme.student.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 10))]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isReady
              ? () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: AppTheme.student),
                              const SizedBox(height: 16),
                              const Text("Generating Your Discovery Report...", style: TextStyle(fontWeight: FontWeight.bold)),
                              const Text("Our AI is analyzing your profile", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );

                  try {
                    final recommendations = await _apiService.getAIRecommendations();
                    if (!mounted) return;
                    Navigator.pop(context); // Close loading dialog

                    final selectedCareer = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AIRecommendationsScreen(
                          aiData: recommendations,
                          apiService: _apiService,
                        ),
                      ),
                    );

                    if (selectedCareer != null) {
                      // If a career was selected, maybe refresh or go to roadmap
                      _loadUserProgress();
                    }
                  } catch (e) {
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("AI Error: $e"), backgroundColor: Colors.red),
                    );
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(22),
          child: Center(
            child: Text(
              isReady ? "ALL ASSESSMENTS COMPLETE" : "COMPLETE ALL ASSESSMENTS",
              style: TextStyle(
                color: isReady ? Colors.white : AppTheme.student.withOpacity(0.5),
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernJourneyStep(int index, String title, String subtitle) {
    bool isCompleted = index < currentStep;
    bool isCurrent = index == currentStep;
    bool isLocked = index > currentStep;

    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF00D293)
                      : (isCurrent ? AppTheme.student : Colors.white),
                  shape: BoxShape.circle,
                  boxShadow: isCurrent
                      ? [BoxShadow(color: AppTheme.student.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]
                      : [],
                  border: isLocked ? Border.all(color: Colors.grey.shade300, width: 2) : null,
                ),
                child: Icon(
                  isCompleted ? Icons.check : (isLocked ? Icons.lock_outline : Icons.play_arrow_rounded),
                  size: 16,
                  color: isLocked ? Colors.grey.shade400 : Colors.white,
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isCompleted ? const Color(0xFF00D293).withOpacity(0.4) : Colors.grey.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: isCurrent ? () => _completeStep(index) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isCurrent
                      ? const LinearGradient(colors: [AppTheme.student, Color(0xFF6A5AE0)])
                      : null,
                  color: isCurrent ? null : (isLocked ? Colors.white.withOpacity(0.5) : Colors.white),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isCurrent
                      ? [BoxShadow(color: AppTheme.student.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]
                      : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                  border: Border.all(
                    color: isCurrent
                        ? Colors.white.withOpacity(0.2)
                        : (isLocked ? Colors.transparent : Colors.white),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: isCurrent
                                  ? Colors.white
                                  : (isLocked ? Colors.grey.shade400 : const Color(0xFF1A2138)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: isCurrent ? Colors.white.withOpacity(0.7) : Colors.blueGrey.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrent) const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      child: Text(
        title,
        style: const TextStyle(color: Color(0xFF8E99AF), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
      ),
    );
  }
}