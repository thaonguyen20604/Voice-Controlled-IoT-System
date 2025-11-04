import 'package:shared_preferences/shared_preferences.dart';
class SharedPrefService {
  Future write({required String key,required String value}) async{
    final SharedPreferences pref = await SharedPreferences.getInstance();
    bool isSaved = await pref.setString(key,value);
  }
  Future read({required String key}) async{
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String? value = pref.getString(key);
    if(value != null){
      return value.toString();
    }
    return null;
  }
  Future remove({required String key})async{
    final SharedPreferences pref = await SharedPreferences.getInstance();
    bool isCleared = await pref.clear();
    return isCleared;
  }
}