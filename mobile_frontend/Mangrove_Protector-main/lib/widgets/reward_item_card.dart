import 'package:flutter/material.dart';
import 'package:mangrove_protector/models/reward_model.dart';
import 'package:mangrove_protector/utils/app_theme.dart';

class RewardItemCard extends StatelessWidget {
  final RewardItem rewardItem;
  final int userPoints;
  final VoidCallback onRedeem;

  const RewardItemCard({
    super.key,
    required this.rewardItem,
    required this.userPoints,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final bool canRedeem = userPoints >= rewardItem.pointsCost && rewardItem.availableQuantity > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reward image or icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: rewardItem.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            rewardItem.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.card_giftcard,
                                size: 40,
                                color: AppTheme.accentColor,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.card_giftcard,
                          size: 40,
                          color: AppTheme.accentColor,
                        ),
                ),
                const SizedBox(width: 16),
                // Reward details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rewardItem.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (rewardItem.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          rewardItem.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.stars,
                            size: 16,
                            color: AppTheme.accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${rewardItem.pointsCost} points',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Available: ${rewardItem.availableQuantity}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Redeem button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canRedeem ? onRedeem : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Text(
                  canRedeem
                      ? 'Redeem for ${rewardItem.pointsCost} points'
                      : userPoints < rewardItem.pointsCost
                          ? 'Need ${rewardItem.pointsCost - userPoints} more points'
                          : 'Out of stock',
                ),
              ),
            ),
            if (userPoints < rewardItem.pointsCost) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: userPoints / rewardItem.pointsCost,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
              ),
              const SizedBox(height: 4),
              Text(
                'You have $userPoints of ${rewardItem.pointsCost} points needed',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

