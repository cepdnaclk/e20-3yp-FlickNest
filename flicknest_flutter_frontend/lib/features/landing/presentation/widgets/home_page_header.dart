import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../styles/styles.dart';

class HomePageHeader extends StatelessWidget {
  const HomePageHeader({super.key});

  String _getFirstName() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.displayName != null) {
      return currentUser!.displayName!.split(' ')[0];
    }
    return 'Guest';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _getFirstName();
    
    return Padding(
      padding: HomeAutomationStyles.mediumPadding
          .copyWith(bottom: 0, left: HomeAutomationStyles.mediumSize),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome',
                style: Theme.of(context).textTheme.headlineMedium!
                    .copyWith(color: Theme.of(context).colorScheme.secondary),
              ),
              Text(
                firstName,
                style: Theme.of(context).textTheme.headlineLarge!
                    .copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold
                ),
              )
            ].animate(
                interval: 200.ms
            ).slideX(
              begin: 0.5, end: 0,
              duration: 0.5.seconds,
              curve: Curves.easeInOut,
            ).fadeIn(
                duration: 0.5.ms,
                curve: Curves.easeInOut
            ),
          ),
        ],
      ),
    );
  }
}
