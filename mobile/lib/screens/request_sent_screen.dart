import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../widgets/primary_button.dart';
import '../widgets/success_message.dart';
import 'home_screen.dart';

class RequestSentScreen extends StatelessWidget {
  final String opponentName;

  const RequestSentScreen({
    super.key,
    required this.opponentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.requestSentTitle,
          style:
              TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Column(
            children: [
              // Widget呼び出し
              Expanded(
                child: SuccessMessage(opponentName: opponentName),
              ),

              PrimaryButton(
                label: AppStrings.returnToHome,
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
