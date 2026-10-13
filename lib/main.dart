import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'features/learning/presentations/screens/main_navigation.dart';
import 'firebase_options.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/register_usecase.dart';
import 'domain/usecases/logout_usecase.dart';
import 'features/learning/presentations/providers/auth_provider.dart';
import 'features/learning/presentations/screens/splash_screen.dart';
import 'services/api/api_service.dart';
import 'services/rewards/reward_service.dart';
import 'services/stats/stats_service.dart';
import 'services/lives/lives_service.dart';
import 'services/sync/account_sync.dart';
import 'services/theme/theme_service.dart';
import 'services/asr/vosk_asr_service.dart';
import 'services/asr/whisper_asr_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Hive.initFlutter();

  final apiService = ApiService();
  if (!apiService.isConfigured) {
    debugPrint('API_BASE_URL verilmedi: bulut senkronu kapalı');
  }

  final rewardService = RewardService();
  await rewardService.init();

  final statsService = StatsService();
  await statsService.init();

  final livesService = LivesService();
  await livesService.init();

  final themeService = ThemeService();
  await themeService.init();

  final voskAsrService = VoskAsrService();
  final whisperAsrService = WhisperAsrService();

  final accountSync = AccountSync(
    api: apiService,
    stats: statsService,
    rewards: rewardService,
    lives: livesService,
  );
  await accountSync.init();

  // Uygulama açılışında zaten oturum açıksa bulut verisini yükle
  final fbUser = fb.FirebaseAuth.instance.currentUser;
  if (fbUser != null) await accountSync.onSignedIn(fbUser.uid);

  runApp(MyApp(
    apiService: apiService,
    accountSync: accountSync,
    rewardService: rewardService,
    statsService: statsService,
    livesService: livesService,
    themeService: themeService,
    voskAsrService: voskAsrService,
    whisperAsrService: whisperAsrService,
  ));
}

class MyApp extends StatelessWidget {
  final ApiService apiService;
  final AccountSync accountSync;
  final RewardService rewardService;
  final StatsService statsService;
  final LivesService livesService;
  final ThemeService themeService;
  final VoskAsrService voskAsrService;
  final WhisperAsrService whisperAsrService;

  const MyApp({
    super.key,
    required this.apiService,
    required this.accountSync,
    required this.rewardService,
    required this.statsService,
    required this.livesService,
    required this.themeService,
    required this.voskAsrService,
    required this.whisperAsrService,
  });

  Future<void> _onSignedIn(String uid) => accountSync.onSignedIn(uid);

  Future<void> _onSignedOut() async => accountSync.onSignedOut();

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepositoryImpl(apiService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            loginUseCase: LoginUseCase(authRepository),
            registerUseCase: RegisterUseCase(authRepository),
            logoutUseCase: LogoutUseCase(authRepository),
            authRepository: authRepository,
            onSignedIn: _onSignedIn,
            onSignedOut: _onSignedOut,
          ),
        ),
        ChangeNotifierProvider<RewardService>.value(value: rewardService),
        ChangeNotifierProvider<StatsService>.value(value: statsService),
        ChangeNotifierProvider<LivesService>.value(value: livesService),
        ChangeNotifierProvider<ThemeService>.value(value: themeService),
        ChangeNotifierProvider<VoskAsrService>.value(value: voskAsrService),
        ChangeNotifierProvider<WhisperAsrService>.value(value: whisperAsrService),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) => MaterialApp(
          title: 'Bilbil',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true),
          home: KeyedSubtree(
            key: ValueKey(themeService.current.id),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (authProvider.isLoading) return const SplashScreen();
                if (authProvider.isLoggedIn) return const MainNavigation();
                return const SplashScreen();
              },
            ),
          ),
        ),
      ),
    );
  }
}