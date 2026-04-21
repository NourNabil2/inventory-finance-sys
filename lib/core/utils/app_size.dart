import 'package:flutter_screenutil/flutter_screenutil.dart';

class SizeApp {
  static double radius = 16.0.r;
  static double radiusMed = 16.0.r;
  static double radiusSmall = 8.0.r;
  static double padding = 16.0.w;
  static double iconSize = 24.0.w;
  static double iconSizeSmall = 16.0.w;
  static double s2 = 2.0.w;
  static double s4 = 4.0.w;
  static double s5 = 5.0.w;
  static double s6 = 6.0.w;
  static double s8 = 8.0.w;
  static double s10 = 10.0.w;
  static double s12 = 12.0.w;
  static double s16 = 16.0.w;
  static double s20 = 20.0.w;
  static double s24 = 24.0.w;
  static double s30 = 30.0.w;
  static double s32 = 32.0.w;
  static double s40 = 40.0.h;
  static double s44 = 44.0.w;
  static double s48 = 48.0.w;
  static double s50 = 50.0.h;
  static double s60 = 60.0.w;
  static double s70 = 70.0.w;
  static double s110 = 110.0.h;

  static double expandedHeight = 240.0.h;
  static double collapsedHeight = 80.0.h;
}

abstract class AppSizeBase {
  double get s1;
  double get s2;
  double get s3;
  double get s4;
  double get s5;
  double get s6;
  double get s7;
  double get s8;
  double get s9;
  double get s10;
  double get s12;
  double get s14;
  double get s16;
  double get s18;
  double get s20;
  double get s24;
  double get s32;
  double get s40;
  double get s50;
  double get s60;
  double get s70;
  double get s80;
  double get s85;
  double get s90;
  double get s100;
  double get s230;
}

class AppSizeVertical extends AppSizeBase {
  AppSizeVertical._();
  static final AppSizeVertical instance = AppSizeVertical._();

  @override double get s1 => 1.h;
  @override double get s2 => 2.h;
  @override double get s3 => 3.h;
  @override double get s4 => 4.h;
  @override double get s5 => 5.h;
  @override double get s6 => 6.h;
  @override double get s7 => 7.h;
  @override double get s8 => 8.h;
  @override double get s9 => 9.h;
  @override double get s10 => 10.h;
  @override double get s12 => 12.h;
  @override double get s14 => 14.h;
  @override double get s16 => 16.h;
  @override double get s18 => 18.h;
  @override double get s20 => 20.h;
  @override double get s24 => 24.h;
  @override double get s32 => 32.h;
  @override double get s40 => 40.h;
  @override double get s50 => 50.h;
  @override double get s60 => 60.h;
  @override double get s70 => 70.h;
  @override double get s80 => 80.h;
  @override double get s85 => 85.h;
  @override double get s90 => 90.h;
  @override double get s100 => 100.h;
  @override double get s230 => 230.h;
}

class AppSizeHorizontal extends AppSizeBase {
  AppSizeHorizontal._();
  static final AppSizeHorizontal instance = AppSizeHorizontal._();

  @override double get s1 => 1.w;
  @override double get s2 => 2.w;
  @override double get s3 => 3.w;
  @override double get s4 => 4.w;
  @override double get s5 => 5.w;
  @override double get s6 => 6.w;
  @override double get s7 => 7.w;
  @override double get s8 => 8.w;
  @override double get s9 => 9.w;
  @override double get s10 => 10.w;
  @override double get s12 => 12.w;
  @override double get s14 => 14.w;
  @override double get s16 => 16.w;
  @override double get s18 => 18.w;
  @override double get s20 => 20.w;
  @override double get s24 => 24.w;
  @override double get s32 => 32.w;
  @override double get s40 => 40.w;
  @override double get s50 => 50.w;
  @override double get s60 => 60.w;
  @override double get s70 => 70.w;
  @override double get s80 => 80.w;
  @override double get s85 => 85.w;
  @override double get s90 => 90.w;
  @override double get s100 => 100.w;
  @override double get s230 => 230.w;
}

class TextSizeApp extends AppSizeBase {
  TextSizeApp._();
  static final TextSizeApp instance = TextSizeApp._();

  @override double get s1 => 1.sp;
  @override double get s2 => 2.sp;
  @override double get s3 => 3.sp;
  @override double get s4 => 4.sp;
  @override double get s5 => 5.sp;
  @override double get s6 => 6.sp;
  @override double get s7 => 7.sp;
  @override double get s8 => 8.sp;
  @override double get s9 => 9.sp;
  @override double get s10 => 10.sp;
  @override double get s12 => 12.sp;
  @override double get s14 => 14.sp;
  @override double get s16 => 16.sp;
  @override double get s18 => 18.sp;
  @override double get s20 => 20.sp;
  @override double get s24 => 24.sp;
  @override double get s32 => 32.sp;
  @override double get s40 => 40.sp;
  @override double get s50 => 50.sp;
  @override double get s60 => 60.sp;
  @override double get s70 => 70.sp;
  @override double get s80 => 80.sp;
  @override double get s85 => 85.sp;
  @override double get s90 => 90.sp;
  @override double get s100 => 100.sp;
  @override double get s230 => 230.sp;
}