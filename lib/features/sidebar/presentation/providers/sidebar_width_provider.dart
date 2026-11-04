import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// The width the user dragged the Home sidebar to. The sidebar is rebuilt
/// every time Home is shown again, so the width is kept here.
class SidebarWidthNotifier extends Notifier<double> {
  @override
  double build() => ResizableSidebar.defaultWidth;

  void setWidth(double width) => state = width;
}

final sidebarWidthProvider = NotifierProvider<SidebarWidthNotifier, double>(
  SidebarWidthNotifier.new,
);
