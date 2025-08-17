import 'package:flutter/material.dart';

class DailyTipCard extends StatefulWidget {
  const DailyTipCard({super.key});

  // List of helpful tips for parents (20 comprehensive tips)
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
    {
      'title': '🌟 Focus on Understanding',
      'content':
          'Ask "Do you understand why this works?" rather than just checking if the answer is correct. Deep understanding matters more than speed.',
    },
    {
      'title': '🎨 Use Visual Learning',
      'content':
          'Draw pictures, use objects, or create diagrams. Many children learn better when they can see and touch concepts.',
    },
    {
      'title': '💪 Build Confidence Daily',
      'content':
          'Start with something your child knows well before tackling harder problems. Success breeds more success.',
    },
    {
      'title': '🗣️ Encourage Explanation',
      'content':
          'Ask your child to teach you what they learned. Teaching others is one of the best ways to reinforce knowledge.',
    },
    {
      'title': '📝 Make Mistakes Learning Opportunities',
      'content':
          'When errors happen, say "Great! Now we know what doesn\'t work. What should we try next?" Mistakes are part of learning.',
    },
    {
      'title': '🏠 Create a Learning Environment',
      'content':
          'Set up a quiet, well-lit space for homework. Remove distractions and have supplies ready to help focus.',
    },
    {
      'title': '⭐ Use Real-World Examples',
      'content':
          'Connect homework to daily life. "We use fractions when cooking!" helps make abstract concepts concrete.',
    },
    {
      'title': '🔄 Practice Patience',
      'content':
          'Learning takes time. Some days will be harder than others. Your patience teaches your child that struggling is normal.',
    },
    {
      'title': '🎯 Set Small Goals',
      'content':
          'Instead of "finish all homework," try "let\'s solve these 3 problems first." Small achievements feel manageable.',
    },
    {
      'title': '🌈 Find Their Learning Style',
      'content':
          'Some kids learn by listening, others by doing. Notice what works best for your child and adapt your help accordingly.',
    },
    {
      'title': '🤔 Ask "What If" Questions',
      'content':
          'Encourage critical thinking with questions like "What if we tried this differently?" or "What patterns do you notice?"',
    },
    {
      'title': '💝 Show Interest in Their Work',
      'content':
          'Ask about what they\'re learning, not just if homework is done. "Tell me about this math concept" shows you value learning.',
    },
    {
      'title': '🎵 Make Learning Fun',
      'content':
          'Use songs, games, or stories when appropriate. Fun memories help children remember concepts better.',
    },
    {
      'title': '🏆 Celebrate Learning Process',
      'content':
          'Praise the journey: "You didn\'t give up when it got hard!" Values effort over natural ability and builds resilience.',
    },
  ];

  @override
  State<DailyTipCard> createState() => _DailyTipCardState();
}

class _DailyTipCardState extends State<DailyTipCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Start with today's tip based on the day of the year
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    _currentPage = dayOfYear % DailyTipCard.tips.length;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Parenting Tips',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Text(
                  '${_currentPage + 1}/${DailyTipCard.tips.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          
          // Carousel
          SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: DailyTipCard.tips.length,
              itemBuilder: (context, index) {
                final tip = DailyTipCard.tips[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip['title']!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            tip['content']!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  height: 1.4,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Page Indicators and Navigation
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Previous button
                IconButton(
                  onPressed: _currentPage > 0
                      ? () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  icon: Icon(
                    Icons.chevron_left,
                    color: _currentPage > 0
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                
                // Dot indicators
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      DailyTipCard.tips.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: _currentPage == index ? 8 : 6,
                        height: _currentPage == index ? 8 : 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Next button
                IconButton(
                  onPressed: _currentPage < DailyTipCard.tips.length - 1
                      ? () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  icon: Icon(
                    Icons.chevron_right,
                    color: _currentPage < DailyTipCard.tips.length - 1
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
