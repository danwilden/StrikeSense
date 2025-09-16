import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/timer_bloc.dart';
import '../core/timer_bloc_state.dart';
import '../models/timer_config.dart';
import '../models/timer_mode.dart';
import '../models/timer_preset.dart';
import '../models/timer_state.dart';
import '../services/preset_storage_service.dart';
import '../../../app/theme.dart';
import 'preset_screen.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  TimerPreset? _currentPreset;
  final PresetStorageService _presetService = PresetStorageService();

  @override
  void initState() {
    super.initState();
    _initializePresetService();
  }

  Future<void> _initializePresetService() async {
    await _presetService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Training Timer',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark, color: Colors.white),
            onPressed: _openPresetScreen,
          ),
        ],
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
                  color: AppTheme.cardColor,
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
                  color: AppTheme.cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Current Mode and Preset
                        Column(
                          children: [
                            Text(
                              state.config?.mode.displayName ?? 'No Timer',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (_currentPreset != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(
                                    _currentPreset!.category.colorValue,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _currentPreset!.category.iconName,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _currentPreset!.name,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
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
                                  ? AppTheme.workColor
                                  : AppTheme.restColor,
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
                                    ? AppTheme.workColor
                                    : AppTheme.restColor,
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
                  color: AppTheme.cardColor,
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

  void _openPresetScreen() {
    final currentConfig = context.read<TimerBloc>().state.config;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PresetScreen(
          currentConfig: currentConfig,
          onPresetSelected: _onPresetSelected,
        ),
      ),
    );
  }

  void _onPresetSelected(TimerPreset preset) {
    setState(() {
      _currentPreset = preset;
    });

    // Initialize timer with the selected preset
    context.read<TimerBloc>().add(InitializeTimer(preset.timerConfig));

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded preset: ${preset.name}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
