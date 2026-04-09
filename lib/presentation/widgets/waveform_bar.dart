import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class WaveformBar extends StatelessWidget {
  const WaveformBar({super.key});

  @override
  Widget build(BuildContext context) {
    final List<double> bars = <double>[
      0.30,
      0.62,
      0.18,
      0.72,
      0.46,
      0.82,
      0.28,
      0.55,
      0.90,
      0.38,
      0.66,
      0.24,
      0.74,
      0.42,
      0.58,
      0.20,
      0.80,
      0.34,
    ];

    return SizedBox(
      height: 76,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars
            .map(
              (double value) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: <Color>[
                          AppColors.primary,
                          AppColors.primaryLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: SizedBox(height: 76 * value),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
