import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';

String localhost = "20.198.115.181";
// String localhost = "10.0.2.2:8000";
// String localhost = "192.168.1.37:8000";

Future<String> storageLocation() async {
  int sdkVersion;
  String location;

  DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  final androidInfo = await deviceInfoPlugin.androidInfo;
  sdkVersion = androidInfo.version.sdkInt;

  location = (sdkVersion <= 29)
      ? '/storage/emulated/0/Picza'
      : (await getExternalStorageDirectory()).path + '/Picza';
  return location;
}
