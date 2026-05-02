import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CareerJourneyScreen extends StatefulWidget {
  const CareerJourneyScreen({super.key});

  @override
  State<CareerJourneyScreen> createState() => _CareerJourneyScreenState();
}

class _CareerJourneyScreenState extends State<CareerJourneyScreen> {
  int completedIndex = -1;

  @override
  Widget build(BuildContext context) {
    bool assessmentDone = completedIndex >= 5; // All 6 tests completed

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Stack(
        children: [
          Positioned(
            top: -100, right: -50,
            child: CircleAvatar(radius: 150, backgroundColor: AppTheme.student.withOpacity(0.03)),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildCustomAppBar(context),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _buildHeaderInfo(),
                        const SizedBox(height: 30),

                        _buildPhaseSection("PHASE 1: FOUNDATION", [
                          _testData(0, "Basic Assessment", "The Starting Point", Icons.explore_rounded),
                        ]),

                        _buildPhaseSection("PHASE 2: DISCOVERY", [
                          _testData(1, "Personality", "Who are you truly?", Icons.psychology_rounded),
                          _testData(2, "Emotional Quotient", "Your emotional intelligence", Icons.sentiment_satisfied_rounded),
                          _testData(3, "Orientation Style", "Your work style preference", Icons.public_rounded),
                          _testData(4, "Career Interests", "Natural inclinations", Icons.interests_rounded),
                        ]),

                        _buildPhaseSection("PHASE 3: PERFORMANCE", [
                          _testData(5, "Aptitude", "Logic & Mental agility", Icons.biotech_rounded),
                        ]),

                        const SizedBox(height: 40),
                        _buildFinalAction(assessmentDone),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UPDATED FINAL ACTION LOGIC ---
  Widget _buildFinalAction(bool isReady) {
    return Container(
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: isReady ? const LinearGradient(colors: [Color(0xFF0056D2), Color(0xFF00C2FF)]) : null,
        color: isReady ? null : Colors.grey.shade300,
        boxShadow: isReady ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))] : [],
      ),
      child: ElevatedButton(
        onPressed: isReady ? () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("All Assessments Complete!"),
              backgroundColor: Colors.green,
            ),
          );
        } : null,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        child: const Text("ALL ASSESSMENTS COMPLETE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }

  // (Keeping previous AppBar, HeaderInfo, PhaseHeader, JourneyTile helpers...)
  // Note: Just ensure the vertical line in _buildPhaseSection uses the student blue.

  Widget _buildCustomAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20)),
          const Text("MY PATHWAY", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2)),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("The Road to\nDiscovery", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1)),
        const SizedBox(height: 10),
        Text("Complete all 6 assessments to unlock your AI-generated Career Roadmap.", style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildPhaseSection(String phaseTitle, List<Map<String, dynamic>> tests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPhaseHeader(phaseTitle),
        Stack(
          children: [
            Positioned(left: 33, top: 0, bottom: 0, child: Container(width: 2, color: AppTheme.student.withOpacity(0.1))),
            Column(children: tests.map((data) => _buildJourneyTile(data)).toList()),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPhaseHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 20, top: 10),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.student, fontSize: 11, letterSpacing: 1.5)),
    );
  }

  Widget _buildJourneyTile(Map<String, dynamic> data) {
    int index = data['index'];
    bool isUnlocked = index == 0 || index <= completedIndex + 1;
    bool isDone = index <= completedIndex;
    Color doneColor = const Color(0xFF00C2FF);

    return GestureDetector(
      onTap: isUnlocked ? () => setState(() => completedIndex = index) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            Container(
              width: 68,
              alignment: Alignment.center,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: isDone ? doneColor : (isUnlocked ? Colors.white : Colors.grey.shade200),
                  shape: BoxShape.circle,
                  border: Border.all(color: isUnlocked ? AppTheme.student.withOpacity(0.1) : Colors.transparent, width: 4),
                ),
                child: Icon(isDone ? Icons.check : (isUnlocked ? data['icon'] : Icons.lock_rounded), size: 18, color: isDone ? Colors.white : (isUnlocked ? AppTheme.student : Colors.grey.shade400)),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isUnlocked ? Colors.white : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: isDone ? doneColor.withOpacity(0.3) : Colors.white),
                  boxShadow: isUnlocked ? [BoxShadow(color: AppTheme.student.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))] : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['title'], style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isUnlocked ? Colors.black : Colors.grey.shade400)),
                    const SizedBox(height: 4),
                    Text(data['subtitle'], style: TextStyle(fontSize: 12, color: isUnlocked ? Colors.blueGrey.shade300 : Colors.grey.shade300)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _testData(int idx, String t, String s, IconData i) {
    return {'index': idx, 'title': t, 'subtitle': s, 'icon': i};
  }
}