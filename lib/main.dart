import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'features/learning/presentations/screens/main_navigation.dart';
import 'firebase_options.dart';
import 'data/datasources/local/auth_local_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/models/user_model.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/register_usecase.dart';
import 'domain/usecases/logout_usecase.dart';
import 'features/learning/presentations/providers/auth_provider.dart';
import 'features/learning/presentations/screens/splash_screen.dart';
import 'services/rewards/reward_service.dart';
import 'services/stats/stats_service.dart';
import 'services/lives/lives_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  Hive.registerAdapter(UserModelAdapter());

  final rewardService = RewardService();
  await rewardService.init();

  final statsService = StatsService();
  await statsService.init();

  final livesService = LivesService();
  await livesService.init();

  runApp(MyApp(
    rewardService: rewardService,
    statsService: statsService,
    livesService: livesService,
  ));
}

class MyApp extends StatelessWidget {
  final RewardService rewardService;
  final StatsService statsService;
  final LivesService livesService;
  const MyApp({
    super.key,
    required this.rewardService,
    required this.statsService,
    required this.livesService,
  });

  @override
  Widget build(BuildContext context) {
    final authLocalDataSource = AuthLocalDataSource();
    final authRepository = AuthRepositoryImpl(authLocalDataSource);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            loginUseCase: LoginUseCase(authRepository),
            registerUseCase: RegisterUseCase(authRepository),
            logoutUseCase: LogoutUseCase(authRepository),
            authRepository: authRepository,
          ),
        ),
        ChangeNotifierProvider<RewardService>.value(value: rewardService),
        ChangeNotifierProvider<StatsService>.value(value: statsService),
        ChangeNotifierProvider<LivesService>.value(value: livesService),
      ],
      child: MaterialApp(
        title: 'Bilbil',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.isLoading) {
              return const SplashScreen();
            }
            if (authProvider.isLoggedIn) {
              return const MainNavigation();
            }
            return const SplashScreen();
          },
        ),
      ),
    );
  }
}