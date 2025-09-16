import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../modules/timer/core/timer_bloc.dart';
import '../modules/timer/services/audio_service.dart';
import '../modules/timer/models/timer_config.dart';
import '../screens/home_screen.dart';
import 'theme.dart';

class StrikeSenseApp extends StatelessWidget {
  const StrikeSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = TimerBloc();

        // Start audio service listening
        AudioService().startListening();

        // Initialize with default timer configuration
        bloc.add(InitializeTimer(TimerConfig.round()));

        return bloc;
      },
      child: MaterialApp(
        title: 'StrikeSense',
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
