import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdWidget extends StatefulWidget {
  const AdWidget({super.key});

  @override
  State<AdWidget> createState() => _AdWidgetState();
}

class _AdWidgetState extends State<AdWidget> {
  RewardedAd? _rewardedAd;

  final String _adUnitId = 'ca-app-pub-7114747566054370/9395364972';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              setState(() {
                ad.dispose();
                _rewardedAd = null;
                _loadAd();
              });
            },
          );

          setState(() {
            _rewardedAd = ad;
          });
        },
        onAdFailedToLoad: (err) {
          debugPrint('Failed to load a rewarded ad: ${err.message}');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_rewardedAd != null) {
      return ElevatedButton(
        onPressed: () {
          _rewardedAd?.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
              // Handle reward
            },
          );
        },
        child: const Text('Show Rewarded Ad'),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }
}
