import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class TbProgressIndicator extends ProgressIndicator {

  const TbProgressIndicator({
    super.key,
    this.size = 36.0,
    super.valueColor,
    super.semanticsLabel,
    super.semanticsValue,
  }) : super(
          value: null,
        );
  final double size;

  @override
  State<StatefulWidget> createState() => _TbProgressIndicatorState();
}

class _TbProgressIndicatorState extends State<TbProgressIndicator> {

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/anim_loading.json',
      width: widget.size,
      height: widget.size,
      repeat: true,
      animate: true,
    );
  }
}
