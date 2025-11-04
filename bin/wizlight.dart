// Dart port of wizlightcpp - https://github.com/srisham/wizlightcpp
// CLI entry point for WizLight package.
// See LICENSE file for licensing details.

import 'package:logging/logging.dart';
import 'package:wizlight/src/wiz_control.dart';

void main(List<String> arguments) async {
  final wiz = WizControl.getInstance();

  // Show usage if no arguments
  if (arguments.isEmpty) {
    WizControl.printUsage();
    return;
  }

  // Handle --help as first argument
  if (arguments.isNotEmpty && arguments[0] == '--help') {
    WizControl.printUsage();
    return;
  }

  // Handle --verbose flag
  var args = List<String>.from(arguments);
  if (args.contains('--verbose')) {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      print(
          '${record.time} ${record.loggerName}(${record.level.name}): ${record.message}');
    });
    args.remove('--verbose');
  }

  // Check if command is supported
  if (args.isEmpty || !wiz.isCmdSupported(args[0])) {
    WizControl.printUsage();
    return;
  }

  // Execute command
  if (args.length == 1) {
    // Interactive mode
    final result = await wiz.performWizRequest(args[0]);
    if (result.isNotEmpty) {
      print(result);
    }
  } else {
    // CLI mode with arguments
    await wiz.validateArgsUsage(args);
  }
}
