import 'package:logger/logger.dart';

class ServiceLogPrinter extends LogPrinter {
  final String serviceName;

  ServiceLogPrinter(this.serviceName);

  @override
  List<String> log(LogEvent event) {
    final String level = event.level.name.toUpperCase();

    return [
      '[$serviceName] [$level] ${event.message}',
    ];
  }
}