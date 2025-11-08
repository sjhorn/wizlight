import 'package:logging/logging.dart';
import 'package:wizlight/wizlight.dart';

void main(List<String> args) async {
  Logger.root.level = Level.FINE;
  final bulb = Bulb();
  bulb.setDeviceIP('192.168.1.104');

  for (int i = 1; i < 10; i++) {
    print(await bulb.toggleLight(true));

    await Future.delayed(const Duration(milliseconds: 100));

    print(await bulb.toggleLight(false));

    await Future.delayed(const Duration(milliseconds: 100));
  }
}
