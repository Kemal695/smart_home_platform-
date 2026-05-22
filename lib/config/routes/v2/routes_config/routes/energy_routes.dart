import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:thingsboard_app/modules/energy/energy_page.dart';

class EnergyRoutes {
  static const energy = '/energy';
}

final energyRoutes = [
  GoRoute(
    path: EnergyRoutes.energy,
    builder: (context, state) => EnergyPage(key: ValueKey(state.uri)),
  ),
];
