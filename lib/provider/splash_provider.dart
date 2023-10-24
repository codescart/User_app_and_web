import 'package:emarket_user/utill/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:emarket_user/data/model/response/base/api_response.dart';
import 'package:emarket_user/data/model/response/config_model.dart';
import 'package:emarket_user/data/repository/splash_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashProvider extends ChangeNotifier {
  final SplashRepo splashRepo;
  final SharedPreferences sharedPreferences;
  SplashProvider({@required this.splashRepo, this.sharedPreferences});

  ConfigModel _configModel;
  BaseUrls _baseUrls;
  DateTime _currentTime = DateTime.now();

  ConfigModel get configModel => _configModel;
  BaseUrls get baseUrls => _baseUrls;
  DateTime get currentTime => _currentTime;

  Future<bool> initConfig(GlobalKey<ScaffoldMessengerState> globalKey) async {
    ApiResponse apiResponse = await splashRepo.getConfig();
    bool isSuccess;
    if (apiResponse.response != null && apiResponse.response.statusCode == 200) {
      _configModel = ConfigModel.fromJson(apiResponse.response.data);
      _baseUrls = ConfigModel.fromJson(apiResponse.response.data).baseUrls;
      isSuccess = true;
      notifyListeners();
    } else {
      isSuccess = false;
      String _error;
      if(apiResponse.error is String) {
        _error = apiResponse.error;
      }else {
        _error = apiResponse.error.errors[0].message;
      }
      print(_error);
      globalKey.currentState.showSnackBar(SnackBar(content: Text(_error), backgroundColor: Colors.red));
    }
    return isSuccess;
  }

  Future<bool> initSharedData() {
    return splashRepo.initSharedData();
  }

  Future<bool> removeSharedData() {
    return splashRepo.removeSharedData();
  }

  bool showLang() {
    return splashRepo.showLang()??true;
  }

  void disableLang() {
    splashRepo.disableLang();
  }


}