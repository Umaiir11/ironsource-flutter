import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ad_controller.dart';

class RewardedAdScreen extends StatelessWidget {
  const RewardedAdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RewardedAdController());
    return Scaffold(
      backgroundColor: Colors.grey[900],
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
              Obx(
                () => ElevatedButton.icon(
                  onPressed: controller.isAdReady.value
                      ? controller.showAd
                      : null,
                  icon: const Icon(Icons.play_circle),
                  label: const Text('Watch Ad'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 56),
                    backgroundColor: controller.isAdReady.value
                        ? Colors.deepPurple
                        : Colors.grey[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
