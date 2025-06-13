import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ironsource_mediation/ironsource_mediation.dart';
import 'main.dart';

class RewardedAdController extends GetxController with LevelPlayRewardedAdListener, LevelPlayInitListener {
  static const String _appKeyAndroid = '85460dcd';
  static const String _appKeyIos = '8545d445';
  static const String _rewardedAdUnitIdAndroid = '76yy3nay3ceui2a3';
  static const String _rewardedAdUnitIdIos = 'qwouvdrkuwivay5q';
  static const String _appUserId = '[YOUR_UNIQUE_APP_USER_ID]';

  final RxBool isAdReady = false.obs;
  final RxBool isInitialized = false.obs;
  LevelPlayRewardedAd? _rewardedAd;
  Timer? _snackbarDebounce;
  Timer? _retryTimer;
  bool _isShowingAd = false;

  String get appKey => Platform.isAndroid
      ? _appKeyAndroid
      : Platform.isIOS
      ? _appKeyIos
      : throw Exception("Unsupported Platform for App Key");

  String get rewardedAdUnitId => Platform.isAndroid
      ? _rewardedAdUnitIdAndroid
      : Platform.isIOS
      ? _rewardedAdUnitIdIos
      : throw Exception("Unsupported Platform for Rewarded Ad Unit ID");

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _snackbarDebounce?.cancel();
    _retryTimer?.cancel();
    _rewardedAd = null; // Clear reference to allow garbage collection
    super.onClose();
  }

  Future<void> _initialize() async {
    if (isInitialized.value) return;

    try {
      IronSource.setFlutterVersion('3.32.3');
      await IronSource.setAdaptersDebug(true);
      IronSource.validateIntegration();

      if (Platform.isIOS) {
        final status = await ATTrackingManager.getTrackingAuthorizationStatus();
        if (status == ATTStatus.NotDetermined) {
          await ATTrackingManager.requestTrackingAuthorization();
        }
      }

      final initRequest = LevelPlayInitRequest.builder(appKey).withUserId(_appUserId).build();
      await LevelPlay.init(initRequest: initRequest, initListener: this);
    } catch (e) {
      _showSnackBar('Initialization failed: $e', isError: true);
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 5), () {
      if (!isInitialized.value) _initialize();
    });
  }

  void loadAd() {
    if (!isInitialized.value || _rewardedAd != null) return;
    _rewardedAd = LevelPlayRewardedAd(adUnitId: rewardedAdUnitId)..setListener(this);
    _rewardedAd?.loadAd();
  }

  Future<void> showAd() async {
    if (_isShowingAd || !(await _rewardedAd?.isAdReady() ?? false)) {
      _showSnackBar('Ad not ready yet!', isError: true);
      return;
    }
    _isShowingAd = true;
    _rewardedAd?.showAd(placementName: 'Default');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (Get.isSnackbarOpen) return;

    _snackbarDebounce?.cancel();
    _snackbarDebounce = Timer(const Duration(milliseconds: 100), () {
      final context = RewardedAdApp.navigatorKey.currentContext;
      if (context == null) return;

      Get.snackbar(
        '',
        message,
        icon: Icon(Icons.info, color: Colors.white),
        backgroundColor: isError ? Colors.red[700] : Colors.deepPurple[700],
        snackPosition: SnackPosition.BOTTOM,
        borderRadius: 8,
        margin: const EdgeInsets.all(16),
        snackStyle: SnackStyle.FLOATING,
        duration: const Duration(seconds: 3),
        colorText: Colors.white,
      );
    });
  }

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {
    isAdReady.value = true;
    _showSnackBar('Ad loaded successfully');
  }

  @override
  void onAdLoadFailed(LevelPlayAdError error) {
    isAdReady.value = false;
    _showSnackBar('Failed to load ad: ${error.errorMessage}', isError: true);
    _scheduleRetry();
  }

  @override
  void onAdRewarded(LevelPlayReward reward, LevelPlayAdInfo adInfo) {
    _isShowingAd = false;
    _rewardedAd = null; // Clear ad after reward to allow new instance
    loadAd();
  }

  @override
  void onAdClosed(LevelPlayAdInfo adInfo) {
    isAdReady.value = false;
    _isShowingAd = false;
    _rewardedAd = null; // Clear ad after close to allow new instance
    loadAd();
  }

  @override
  void onInitSuccess(LevelPlayConfiguration configuration) {
    isInitialized.value = true;
    loadAd();
  }

  @override
  void onInitFailed(LevelPlayInitError error) {
    isInitialized.value = false;
    _showSnackBar('SDK initialization failed: ${error.errorMessage}', isError: true);
    _scheduleRetry();
  }

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {}
  @override
  void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) {
    _isShowingAd = false;
    _showSnackBar('Ad display failed: ${error.errorMessage}', isError: true);
    _rewardedAd = null; // Clear ad on display failure
    loadAd();
  }
  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {}
  @override
  void onAdInfoChanged(LevelPlayAdInfo adInfo) {}
}