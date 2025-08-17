import 'package:flutter/material.dart';

class DailyTipCard extends StatelessWidget {
  const DailyTipCard({super.key});

  // List of helpful tips for parents
  static const List<Map<String, String>> tips = [
    {
      'title': '📚 Stay Calm & Encouraging',
      'content':
          'Remember, it\'s okay not to know everything! Your positive attitude helps your child feel confident about learning together.',
    },
    {
      'title': '🎯 Break It Down',
      'content':
          'If a problem seems overwhelming, break it into smaller steps. Each small victory builds confidence for the next challenge.',
    },
    {
      'title': '🔍 Ask Questions Together',
      'content':
          'Instead of giving answers, ask "What do you think comes next?" This helps your child develop problem-solving skills.',
    },
    {
      'title': '🎉 Celebrate Progress',
      'content':
          'Acknowledge effort, not just correct answers. "You\'re working really hard on this!" builds a growth mindset.',
    },
    {
      'title': '⏰ Take Breaks',
      'content':
          'If frustration builds up, take a 5-minute break. Fresh minds solve problems better than tired ones.',
    },
    {
      'title': '🤝 Learn Together',
      'content':
          'Show your child that learning never stops. Say "Let\'s figure this out together" instead of "I don\'t know."',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Get today's tip based on the day of the year
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    final todayTip = tips[dayOfYear % tips.length];

    return Card(
      elevation: 1,
      color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Daily Tip',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              todayTip['title']!,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              todayTip['content']!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
