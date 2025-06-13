import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ironsource_mediation/ironsource_mediation.dart';

const String APP_USER_ID = '[YOUR_UNIQUE_APP_USER_ID]';
const String APP_KEY_ANDROID = '85460dcd';
const String APP_KEY_IOS = '8545d445';
const String REWARDED_AD_UNIT_ID_ANDROID = '76yy3nay3ceui2a3';
const String REWARDED_AD_UNIT_ID_IOS = 'qwouvdrkuwivay5q';

String get appKey => Platform.isAndroid
    ? APP_KEY_ANDROID
    : Platform.isIOS
    ? APP_KEY_IOS
    : throw Exception("Unsupported Platform for App Key");

String get rewardedAdUnitId => Platform.isAndroid
    ? REWARDED_AD_UNIT_ID_ANDROID
    : Platform.isIOS
    ? REWARDED_AD_UNIT_ID_IOS
    : throw Exception("Unsupported Platform for Rewarded Ad Unit ID");

void main() {
  runApp(const RewardedAdApp());
}

class RewardedAdApp extends StatelessWidget {
  const RewardedAdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.deepPurple,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.grey[900],
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.deepPurple,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        useMaterial3: true,
      ),
      home: const RewardedAdScreen(),
    );
  }
}

class RewardedAdScreen extends StatefulWidget {
  const RewardedAdScreen({super.key});

  @override
  State<RewardedAdScreen> createState() => _RewardedAdScreenState();
}

class _RewardedAdScreenState extends State<RewardedAdScreen> with LevelPlayRewardedAdListener, LevelPlayInitListener {
  late final LevelPlayRewardedAd _rewardedAd;
  bool _isAdReady = false;

  @override
  void initState() {
    super.initState();
    _rewardedAd = LevelPlayRewardedAd(adUnitId: rewardedAdUnitId)..setListener(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    try {
      IronSource.setFlutterVersion('3.16.9');
      await IronSource.setAdaptersDebug(true);
      IronSource.validateIntegration();

      if (Platform.isIOS) {
        final status = await ATTrackingManager.getTrackingAuthorizationStatus();
        if (status == ATTStatus.NotDetermined) {
          await ATTrackingManager.requestTrackingAuthorization();
        }
      }

      final initRequest = LevelPlayInitRequest.builder(appKey)
          .withUserId(APP_USER_ID)
          .build();
      await LevelPlay.init(initRequest: initRequest, initListener: this);
      _loadAd();
    } on PlatformException catch (e) {
      _showSnackBar('Initialization failed: ${e.message}');
    }
  }

  void _loadAd() => _rewardedAd.loadAd();

  Future<void> _showAd() async {
    if (await _rewardedAd.isAdReady()) {
      _rewardedAd.showAd(placementName: 'Default');
    } else {
      _showSnackBar('Ad not ready yet!');
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.info,
              color: isSuccess ? Colors.green : Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? Colors.black87 : Colors.deepPurple[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Earn Rewards!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Watch a short ad to earn coins',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isAdReady ? _showAd : null,
                icon: const Icon(Icons.play_circle),
                label: const Text('Watch Ad'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 56),
                  backgroundColor: _isAdReady ? null : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {
    setState(() => _isAdReady = true);
    _showSnackBar('Ad loaded successfully!');
  }

  @override
  void onAdLoadFailed(LevelPlayAdError error) {
    setState(() => _isAdReady = false);
    _showSnackBar('Failed to load ad: ${error.errorMessage}');
    Future.delayed(const Duration(seconds: 2), _loadAd);
  }

  @override
  void onAdRewarded(LevelPlayReward reward, LevelPlayAdInfo adInfo) {
    _showSnackBar('🎉 You earned coins!', isSuccess: true);
    _loadAd();
  }

  @override
  void onAdClosed(LevelPlayAdInfo adInfo) {
    setState(() => _isAdReady = false);
    _loadAd();
  }

  @override
  void onInitSuccess(LevelPlayConfiguration configuration) {
    _showSnackBar('SDK initialized successfully!');
  }

  @override
  void onInitFailed(LevelPlayInitError error) {
    _showSnackBar('SDK initialization failed: ${error.errorMessage}');
  }

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {}
  @override
  void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) {}
  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {}
  @override
  void onAdInfoChanged(LevelPlayAdInfo adInfo) {}
}