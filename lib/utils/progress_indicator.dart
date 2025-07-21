import 'package:flutter/material.dart';
import 'dart:async';

/// Enhanced progress indicator with multiple styles and features
class ProgressIndicator extends StatefulWidget {
  final double progress;
  final String? message;
  final ProgressStyle style;
  final Color? primaryColor;
  final Color? backgroundColor;
  final double? height;
  final bool showPercentage;
  final bool animated;
  final Duration animationDuration;
  final String? title;
  final Widget? leading;
  final Widget? trailing;

  const ProgressIndicator({
    Key? key,
    required this.progress,
    this.message,
    this.style = ProgressStyle.linear,
    this.primaryColor,
    this.backgroundColor,
    this.height,
    this.showPercentage = true,
    this.animated = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.title,
    this.leading,
    this.trailing,
  }) : super(key: key);

  @override
  State<ProgressIndicator> createState() => _ProgressIndicatorState();
}

class _ProgressIndicatorState extends State<ProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.animated) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(ProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: oldWidget.progress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));

      if (widget.animated) {
        _animationController.reset();
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.primaryColor;
    final backgroundColor = widget.backgroundColor ?? theme.dividerColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.title!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        _buildProgressIndicator(primaryColor, backgroundColor),
        if (widget.message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              widget.message!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressIndicator(Color primaryColor, Color backgroundColor) {
    switch (widget.style) {
      case ProgressStyle.linear:
        return _buildLinearProgress(primaryColor, backgroundColor);
      case ProgressStyle.circular:
        return _buildCircularProgress(primaryColor, backgroundColor);
      case ProgressStyle.stepped:
        return _buildSteppedProgress(primaryColor, backgroundColor);
      case ProgressStyle.gradient:
        return _buildGradientProgress(primaryColor, backgroundColor);
    }
  }

  Widget _buildLinearProgress(Color primaryColor, Color backgroundColor) {
    return Row(
      children: [
        if (widget.leading != null) ...[
          widget.leading!,
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Container(
            height: widget.height ?? 8,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: widget.animated
                  ? AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: _animation.value,
                          backgroundColor: Colors.transparent,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(primaryColor),
                        );
                      },
                    )
                  : LinearProgressIndicator(
                      value: widget.progress,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
            ),
          ),
        ),
        if (widget.showPercentage) ...[
          const SizedBox(width: 8),
          Text(
            '${(widget.progress * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (widget.trailing != null) ...[
          const SizedBox(width: 8),
          widget.trailing!,
        ],
      ],
    );
  }

  Widget _buildCircularProgress(Color primaryColor, Color backgroundColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: widget.height ?? 60,
          height: widget.height ?? 60,
          child: Stack(
            children: [
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(backgroundColor),
              ),
              widget.animated
                  ? AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return CircularProgressIndicator(
                          value: _animation.value,
                          strokeWidth: 4,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(primaryColor),
                        );
                      },
                    )
                  : CircularProgressIndicator(
                      value: widget.progress,
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
              if (widget.showPercentage)
                Center(
                  child: Text(
                    '${(widget.progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSteppedProgress(Color primaryColor, Color backgroundColor) {
    const int steps = 5;
    final int completedSteps = (widget.progress * steps).round();

    return Row(
      children: List.generate(steps, (index) {
        final isCompleted = index < completedSteps;
        return Expanded(
          child: Container(
            height: widget.height ?? 8,
            margin: EdgeInsets.only(right: index < steps - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: isCompleted ? primaryColor : backgroundColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGradientProgress(Color primaryColor, Color backgroundColor) {
    return Container(
      height: widget.height ?? 8,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
            FractionallySizedBox(
              widthFactor: widget.progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.7),
                      primaryColor,
                      primaryColor.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Progress dialog for showing operations in progress
class ProgressDialog extends StatelessWidget {
  final String title;
  final String? message;
  final double progress;
  final bool canCancel;
  final VoidCallback? onCancel;
  final ProgressStyle style;

  const ProgressDialog({
    Key? key,
    required this.title,
    this.message,
    required this.progress,
    this.canCancel = false,
    this.onCancel,
    this.style = ProgressStyle.linear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProgressIndicator(
            progress: progress,
            message: message,
            style: style,
          ),
          if (message != null) const SizedBox(height: 16),
        ],
      ),
      actions: [
        if (canCancel)
          TextButton(
            onPressed: onCancel,
            child: const Text('Batal'),
          ),
      ],
    );
  }

  /// Show progress dialog
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    String? message,
    required Stream<double> progressStream,
    ProgressStyle style = ProgressStyle.linear,
    bool canCancel = false,
    VoidCallback? onCancel,
  }) async {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StreamBuilder<double>(
        stream: progressStream,
        builder: (context, snapshot) {
          final progress = snapshot.data ?? 0.0;
          return ProgressDialog(
            title: title,
            message: message,
            progress: progress,
            canCancel: canCancel,
            onCancel: onCancel,
            style: style,
          );
        },
      ),
    );
  }
}

/// Different styles of progress indicators
enum ProgressStyle {
  linear,
  circular,
  stepped,
  gradient,
}

/// Progress manager for tracking multiple operations
class ProgressManager {
  final Map<String, double> _operations = {};
  final StreamController<Map<String, double>> _controller =
      StreamController.broadcast();

  Stream<Map<String, double>> get stream => _controller.stream;

  void updateProgress(String operationId, double progress) {
    _operations[operationId] = progress.clamp(0.0, 1.0);
    _controller.add(Map.from(_operations));
  }

  void completeOperation(String operationId) {
    _operations.remove(operationId);
    _controller.add(Map.from(_operations));
  }

  double getProgress(String operationId) {
    return _operations[operationId] ?? 0.0;
  }

  bool hasOperation(String operationId) {
    return _operations.containsKey(operationId);
  }

  double get overallProgress {
    if (_operations.isEmpty) return 0.0;
    final totalProgress =
        _operations.values.fold(0.0, (sum, progress) => sum + progress);
    return totalProgress / _operations.length;
  }

  void dispose() {
    _controller.close();
  }
}
