import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../modules/timer/ui/timer_screen.dart';
import '../modules/poses/ui/poses_screen.dart';
import '../modules/drills/ui/drills_screen.dart';
import '../modules/workouts/ui/workouts_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'StrikeSense',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome message
            Card(
              color: AppTheme.cardColor,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(Icons.sports_mma, size: 64, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'Welcome to StrikeSense',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your comprehensive martial arts training companion',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Module navigation cards
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildModuleCard(
                    context,
                    title: 'Timer',
                    subtitle: 'Training Timer',
                    icon: Icons.timer,
                    color: Colors.blue,
                    onTap: () => _navigateToTimer(context),
                  ),
                  _buildModuleCard(
                    context,
                    title: 'Shadow',
                    subtitle: 'Tech. Coaching',
                    icon: Icons.accessibility_new,
                    color: Colors.green,
                    onTap: () => _navigateToPoses(context),
                  ),
                  _buildModuleCard(
                    context,
                    title: 'Drills',
                    subtitle: 'Training Exercises',
                    icon: Icons.fitness_center,
                    color: Colors.orange,
                    onTap: () => _navigateToDrills(context),
                  ),
                  _buildModuleCard(
                    context,
                    title: 'Workouts',
                    subtitle: 'Complete Routines',
                    icon: Icons.sports,
                    color: Colors.purple,
                    onTap: () => _navigateToWorkouts(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppTheme.cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToTimer(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const TimerScreen()));
  }

  void _navigateToPoses(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const PosesScreen()));
  }

  void _navigateToDrills(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const DrillsScreen()));
  }

  void _navigateToWorkouts(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const WorkoutsScreen()));
  }
}
