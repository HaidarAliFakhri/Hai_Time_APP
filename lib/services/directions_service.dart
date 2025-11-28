// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class DirectionsService {
//   static const String _apiKey = "AIzaSyDk_IqTjxDnhlwFcVf8bYfNR0qBtEGAyJw";

//   static Future<Map<String, dynamic>?> getDirections({
//     required double originLat,
//     required double originLng,
//     required double destLat,
//     required double destLng,
//     String mode = "driving",
//   }) async {
//     final url =
//         "https://maps.googleapis.com/maps/api/directions/json?origin=$originLat,$originLng&destination=$destLat,$destLng&mode=$mode&key=$_apiKey";

//     final response = await http.get(Uri.parse(url));

//     if (response.statusCode != 200) return null;

//     final data = jsonDecode(response.body);

//     if (data["status"] != "OK") return null;

//     final leg = data["routes"][0]["legs"][0];

//     return {
//       "distance": leg["distance"]["text"],
//       "duration": leg["duration"]["text"],
//     };
//   }
// }
