import 'package:dio/dio.dart';

class Abc {
  static Future<Response> postData(String url, dynamic body) async {
    Dio dio = Dio();

    try {
      Response response = await dio.post(url, data: body);
      return response;
    } on DioError catch (e) {
      throw Exception(e.response!.data.toString());
    }
  }
}
