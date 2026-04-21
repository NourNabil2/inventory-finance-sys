import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:flutter/material.dart';
import '../errors/failure_message_mapper.dart';
import '../errors/failures.dart';
import '../utils/enums.dart';
import '../utils/app_size.dart';


class ErrorStateWidget extends StatelessWidget {
  final Failure failure;
  final VoidCallback onRetry;
  final bool showAppBar;

  const ErrorStateWidget({
    Key? key,
    required this.failure,
    required this.onRetry,
    this.showAppBar = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sizeV = AppSizeVertical.instance;
    final sizeH = AppSizeHorizontal.instance;

    // Get error info using FailureMessageMapper
    final errorType = FailureMessageMapper.mapFailureToErrorType(failure);
    final title = FailureMessageMapper.mapFailureToMessage(failure);
    final subtitle = FailureMessageMapper.getSubtitle(failure);
    final actionLabel = FailureMessageMapper.getActionMessage(failure);

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      )
          : null,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(sizeH.s32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIconForErrorType(errorType),
                size: 80,
                color: _getColorForErrorType(errorType),
              ),
              SizedBox(height: sizeV.s24),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: sizeV.s12),
              Text(
                subtitle,
                maxLines: 2,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColorsManager.miscellaneous,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: sizeV.s32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: sizeH.s40,
                    vertical: sizeV.s14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForErrorType(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.server:
        return Icons.error_outline;
      case ErrorType.auth:
        return Icons.lock_outline;
      case ErrorType.cache:
        return Icons.storage;
      case ErrorType.validation:
        return Icons.warning_amber;
      case ErrorType.unknown:
        return Icons.error_outline;
    }
  }

  Color _getColorForErrorType(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Colors.orange[400]!;
      case ErrorType.server:
        return Colors.red[400]!;
      case ErrorType.auth:
        return Colors.red[400]!;
      case ErrorType.cache:
        return Colors.blue[400]!;
      case ErrorType.validation:
        return Colors.amber[600]!;
      case ErrorType.unknown:
        return Colors.grey[400]!;
    }
  }
}

// Extension for easy usage
extension FailureWidgetExtension on Failure {
  Widget toErrorWidget({
    required VoidCallback onRetry,
    bool showAppBar = false,
  }) {
    return ErrorStateWidget(
      failure: this,
      onRetry: onRetry,
      showAppBar: showAppBar,
    );
  }
}