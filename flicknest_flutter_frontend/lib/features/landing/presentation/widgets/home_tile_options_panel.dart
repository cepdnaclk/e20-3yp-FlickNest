import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeTileOptionsPanel extends ConsumerWidget {
  const HomeTileOptionsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
        children: [
          SizedBox(
            height: 150,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
              ],
            ),
          )
        ]
    );
  }
}
