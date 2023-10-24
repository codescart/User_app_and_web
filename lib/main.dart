import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:emarket_user/helper/responsive_helper.dart';
import 'package:emarket_user/helper/router_helper.dart';
import 'package:emarket_user/utill/color_change.dart';
import 'package:emarket_user/utill/dimensions.dart';
import 'package:emarket_user/utill/routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:emarket_user/localization/app_localization.dart';
import 'package:emarket_user/notification/my_notification.dart';
import 'package:emarket_user/provider/auth_provider.dart';
import 'package:emarket_user/provider/banner_provider.dart';
import 'package:emarket_user/provider/cart_provider.dart';
import 'package:emarket_user/provider/category_provider.dart';
import 'package:emarket_user/provider/chat_provider.dart';
import 'package:emarket_user/provider/coupon_provider.dart';
import 'package:emarket_user/provider/localization_provider.dart';
import 'package:emarket_user/provider/notification_provider.dart';
import 'package:emarket_user/provider/order_provider.dart';
import 'package:emarket_user/provider/location_provider.dart';
import 'package:emarket_user/provider/product_provider.dart';
import 'package:emarket_user/provider/language_provider.dart';
import 'package:emarket_user/provider/onboarding_provider.dart';
import 'package:emarket_user/provider/profile_provider.dart';
import 'package:emarket_user/provider/search_provider.dart';
import 'package:emarket_user/provider/splash_provider.dart';
import 'package:emarket_user/provider/theme_provider.dart';
import 'package:emarket_user/provider/wishlist_provider.dart';
import 'package:emarket_user/theme/dark_theme.dart';
import 'package:emarket_user/theme/light_theme.dart';
import 'package:emarket_user/utill/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_strategy/url_strategy.dart';
import 'di_container.dart' as di;
import 'provider/news_provider.dart';
import 'package:http/http.dart' as http;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  if(ResponsiveHelper.isMobilePhone()) {
    HttpOverrides.global = new MyHttpOverrides();
  }
  setPathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await di.init();
  int _orderID;
  try {
    if (!kIsWeb) {
      final RemoteMessage remoteMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (remoteMessage != null) {
        _orderID = remoteMessage.notification.titleLocKey != null ? int.parse(remoteMessage.notification.titleLocKey) : null;
      }
      await MyNotification.initialize(flutterLocalNotificationsPlugin);
      FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
    }
  }catch(e) {}

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => di.sl<ThemeProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<SplashProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<LanguageProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<OnBoardingProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<CategoryProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<BannerProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<ProductProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<LocalizationProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<AuthProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<LocationProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<LocalizationProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<CartProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<OrderProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<ChatProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<ProfileProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<NotificationProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<CouponProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<WishListProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<NewsLetterProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<SearchProvider>()),
    ],
    child: MyApp(orderId: _orderID, isWeb: !kIsWeb),
  ));
}

class MyApp extends StatefulWidget {
  final int orderId;
  final bool isWeb;
  MyApp({@required this.orderId, @required this.isWeb});

  static final navigatorKey = new GlobalKey<NavigatorState>();

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GlobalKey<ScaffoldMessengerState> _globalKey = GlobalKey();

  @override
  void initState() {

    leader();
    super.initState();
    Provider.of<SplashProvider>(context, listen: false).initSharedData();
    RouterHelper.setupRouter();

    if(kIsWeb) {
      Provider.of<SplashProvider>(context, listen: false).initSharedData();
      Provider.of<CartProvider>(context, listen: false).getCartData();
      _route();
    }

  }
  void _route() {
    Provider.of<SplashProvider>(context, listen: false).initConfig(_globalKey).then((bool isSuccess) async {
      if (isSuccess) {
        if (Provider.of<AuthProvider>(context, listen: false).isLoggedIn()) {
          Provider.of<AuthProvider>(context, listen: false).updateToken();
          await Provider.of<WishListProvider>(context, listen: false).initWishList(
            context, Provider.of<LocalizationProvider>(context, listen: false).locale.languageCode,
          );
        }
      }
    });
  }

  var map;
  var back='#9675cd';
  Future leader() async{

    final response = await http.get(
      Uri.parse('https://backend.foundercodes.com/frontend_get.php?pid=28&gid=2'),

    );
    var data = jsonDecode(response.body)['data'];
    print(data);
    if (response.statusCode == 200) {
      setState(() {
       back= data['bg_color'];
      });
      final prefs1 = await SharedPreferences.getInstance();
      prefs1.setString("namef", data['name']);
      prefs1.setString('logof', data['logo']);
      prefs1.setString('emailf', data['email']);
      prefs1.setString('comp_namef', data['comp_name']);
      prefs1.setString('font_colorf', data['font_color']);
      prefs1.setString('bg_colorf', data['bg_color']);
      prefs1.setString('hover_colorf', data['hover_color']);
      prefs1.setString('addressf', data['address']);
    }
  }



  @override
  Widget build(BuildContext context) {
    List<Locale> _locals = [];
    AppConstants.languages.forEach((language) {
      _locals.add(Locale(language.languageCode, language.countryCode));
    });
    return Consumer<SplashProvider>(
      builder: (context, splashProvider, child){
        return (kIsWeb && splashProvider.configModel == null) ? SizedBox() : MaterialApp(

          initialRoute: ResponsiveHelper.isMobilePhone() ? widget.orderId == null ? Routes.getSplashRoute()
              : Routes.getOrderDetailsRoute(widget.orderId) : splashProvider.configModel.maintenanceMode? Routes.getMaintainRoute():Routes.getMainRoute(),
          onGenerateRoute: RouterHelper.router.generator,

          title: splashProvider.configModel != null ? splashProvider.configModel.ecommerceName ?? '' : AppConstants.APP_NAME,
          debugShowCheckedModeBanner: false,
          navigatorKey: MyApp.navigatorKey,
          theme: Provider.of<ThemeProvider>(context).darkTheme ? ThemeData(
            fontFamily: 'Rubik',
            primaryColor: back.toColor(),
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Color(0xFF2C2C2C),
            cardColor: Color(0xFF252525),
            hintColor: Color(0xFFE7F6F8),
            focusColor: Color(0xFFADC4C8),
            textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(
              primary: Colors.white, textStyle: TextStyle(color: Colors.white),
            )),
            textTheme: TextTheme(
              button: TextStyle(color: Color(0xFF252525)),

              headline1: TextStyle(fontWeight: FontWeight.w300, fontSize: Dimensions.FONT_SIZE_DEFAULT),
              headline2: TextStyle(fontWeight: FontWeight.w400, fontSize: Dimensions.FONT_SIZE_DEFAULT),
              headline3: TextStyle(fontWeight: FontWeight.w500, fontSize: Dimensions.FONT_SIZE_DEFAULT),
              headline4: TextStyle(fontWeight: FontWeight.w600, fontSize: Dimensions.FONT_SIZE_DEFAULT),
              headline5: TextStyle(fontWeight: FontWeight.w700, fontSize: Dimensions.FONT_SIZE_DEFAULT),
              headline6: TextStyle(fontWeight: FontWeight.w800, fontSize: Dimensions.FONT_SIZE_DEFAULT),
              caption: TextStyle(fontWeight: FontWeight.w900, fontSize: Dimensions.FONT_SIZE_DEFAULT),

              subtitle1: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w500),
              bodyText2: TextStyle(fontSize: 12.0),
              bodyText1: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
            ),
          )

           : ThemeData(
            fontFamily: 'Rubik',
            primaryColor: back.toColor(),
            brightness: Brightness.light,
            cardColor: Colors.white,
            focusColor: Color(0xFFADC4C8),
            hintColor: Color(0xFF52575C),
            textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(
              primary: Colors.black, textStyle: TextStyle(color: Colors.black),
            )),
            textTheme: TextTheme(
              button: TextStyle(color: Colors.white),

              headline1: TextStyle(fontWeight: FontWeight.w300, fontSize: Dimensions.FONT_SIZE_DEFAULT),
              headline2: TextStyle(fontWeight: FontWeight.w400, fontSize: Dimensions.FONT_SIZE_DEFAULT),
              headline3: TextStyle(fontWeight: FontWeight.w500, fontSize: Dimensions.FONT_SIZE_DEFAULT),
              headline4: TextStyle(fontWeight: FontWeight.w600, fontSize: Dimensions.FONT_SIZE_DEFAULT),
              headline5: TextStyle(fontWeight: FontWeight.w700, fontSize: Dimensions.FONT_SIZE_DEFAULT),
              headline6: TextStyle(fontWeight: FontWeight.w800, fontSize: Dimensions.FONT_SIZE_DEFAULT),
              caption: TextStyle(fontWeight: FontWeight.w900, fontSize: Dimensions.FONT_SIZE_DEFAULT),



              subtitle1: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w500),
              bodyText2: TextStyle(fontSize: 12.0),
              bodyText1: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
            ),
          ),
          locale: Provider.of<LocalizationProvider>(context).locale,
          localizationsDelegates: [
            AppLocalization.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: _locals,
          scrollBehavior: MaterialScrollBehavior().copyWith(dragDevices: {
            PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.stylus, PointerDeviceKind.unknown
          }),
        );
      },

    );
  }



}
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

