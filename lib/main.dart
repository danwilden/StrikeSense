import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'modules/timer/core/timer_bloc.dart';
import 'modules/timer/core/timer_bloc_state.dart';
import 'modules/timer/models/timer_config.dart';
import 'modules/timer/models/timer_mode.dart';
import 'modules/timer/models/timer_state.dart';
import 'modules/timer/services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize audio service
  try {
    await AudioService().initialize();
    print('Audio service initialized successfully');
  } catch (e) {
    print('Warning: Failed to initialize audio service: $e');
    // Continue without audio - app will still work
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StrikeSense Timer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2C3E50), // Dark blue-grey
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(
          0xFF1A1A1A,
        ), // Very dark background
      ),
      home: BlocProvider(
        create: (context) {
          final bloc = TimerBloc();

          // Start audio service listening
          AudioService().startListening();

          // Initialize with default timer configuration
          bloc.add(InitializeTimer(TimerConfig.round()));

          return bloc;
        },
        child: const TimerDemoPage(),
      ),
    );
  }
}

class TimerDemoPage extends StatelessWidget {
  const TimerDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        title: const Text(
          'StrikeSense Timer',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: BlocBuilder<TimerBloc, TimerBlocState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timer Mode Selection
                Card(
                  color: const Color(0xFF2C3E50),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Timer Mode',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _onRoundPressed(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      state.config?.mode == TimerMode.round
                                      ? Colors.blue
                                      : Colors.blue[800],
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Round'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _onIntervalPressed(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      state.config?.mode == TimerMode.interval
                                      ? Colors.green
                                      : Colors.green[800],
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Interval'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _onTabataPressed(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      state.config?.mode == TimerMode.tabata
                                      ? Colors.orange
                                      : Colors.orange[800],
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Tabata'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Timer Display
                Card(
                  color: const Color(0xFF2C3E50),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Current Mode
                        Text(
                          state.config?.mode.displayName ?? 'No Timer',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Round Information
                        if (state.config != null) ...[
                          Text(
                            'Round ${state.currentRound} of ${state.config!.rounds}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            state.isWorkPeriod ? 'Work' : 'Rest',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: state.isWorkPeriod
                                  ? Colors.red[300]
                                  : Colors.green[300],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Time Display
                        Text(
                          _formatDuration(state.currentPeriodRemaining),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Progress Bar
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.grey[300],
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: state.progress,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: state.isWorkPeriod
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Progress Text
                        Text(
                          '${(state.progress * 100).toStringAsFixed(1)}% Complete',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Control Buttons
                Card(
                  color: const Color(0xFF2C3E50),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: state.state == TimerState.running
                                    ? () => _onPausePressed(context)
                                    : () => _onStartPressed(context),
                                icon: Icon(
                                  state.state == TimerState.running
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                ),
                                label: Text(
                                  state.state == TimerState.running
                                      ? 'Pause'
                                      : 'Start',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      state.state == TimerState.running
                                      ? Colors.orange[600]
                                      : Colors.green[600],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _onStopPressed(context),
                                icon: const Icon(Icons.stop),
                                label: const Text('Stop'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[600],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _onResetPressed(context),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reset'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _onSkipPressed(context),
                                icon: const Icon(Icons.skip_next),
                                label: const Text('Skip'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple[600],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Error Display
                if (state.error != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.red[900],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error: ${state.error}',
                        style: TextStyle(color: Colors.red[200]),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _onRoundPressed(BuildContext context) {
    context.read<TimerBloc>().add(InitializeTimer(TimerConfig.round()));
  }

  void _onIntervalPressed(BuildContext context) {
    context.read<TimerBloc>().add(InitializeTimer(TimerConfig.interval()));
  }

  void _onTabataPressed(BuildContext context) {
    context.read<TimerBloc>().add(InitializeTimer(TimerConfig.tabata()));
  }

  void _onStartPressed(BuildContext context) {
    context.read<TimerBloc>().add(StartTimer());
  }

  void _onPausePressed(BuildContext context) {
    context.read<TimerBloc>().add(PauseTimer());
  }

  void _onStopPressed(BuildContext context) {
    context.read<TimerBloc>().add(StopTimer());
  }

  void _onResetPressed(BuildContext context) {
    context.read<TimerBloc>().add(ResetTimer());
  }

  void _onSkipPressed(BuildContext context) {
    context.read<TimerBloc>().add(SkipTimer());
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}
