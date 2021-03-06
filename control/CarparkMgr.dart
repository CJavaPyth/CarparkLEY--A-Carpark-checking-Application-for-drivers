import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../services/coordinate_converter.dart';
import 'GoogleMapsMgr.dart';

const googleApiKey = 'AIzaSyDz74V86brNHy9fvgk6cvBv1X2g5BRAU7M';
const uraAccessKey = '62f968e9-3534-4c1c-9250-44e04671037c';

class CarparkMgr {
  //This method uses Google Places API to give an output of all carparks near user's destination
  Future<dynamic> searchNearby(String keyword) async {
    String constant = 'car park near';
    var dio = Dio();
    var url = 'https://maps.googleapis.com/maps/api/place/textsearch/json';
    var parameters = {
      'key': googleApiKey,
      'query': constant + keyword,
      'radius': '2000',
    };
    print('querying: $constant ' + keyword);
    var response = await dio.get(url, data: parameters);
    return response.data['results'];
  }

  //This method is to get the daily token from URA, in order to use its API, because the token changes daily
  Future<String> getDailyToken() async {
    final response = await http.get(
        Uri.https('www.ura.gov.sg', '/uraDataService/insertNewToken.action'),
        headers: {'AccessKey': uraAccessKey});

    final responseJson = jsonDecode(response.body);
    final token = responseJson['Result'];

    return token;
  }

  //this method compares the coordinates in the Output of Google's search results, with the URAdataset
  //if coordinates match, display the carpark in results page
  //multiple 'If's are used to provide more extensive checking, and because some of the data in URA dataset is not consistent
  Future<dynamic> locateCarparks(String destination, String vehicleType) async {
    final response = await http.get(
      Uri.https(
        'www.ura.gov.sg',
        '/uraDataService/invokeUraDS',
        {'service': 'Car_Park_Availability'},
      ),
      headers: {
        'AccessKey': uraAccessKey,
        'Token': await getDailyToken(),
      },
    );

    final responseJson = jsonDecode(response.body);

    print(responseJson);
    Map<String, List<String>> map = Map();
    map = {};
    for (var i = 0; i < responseJson['Result'].length; i++) {
      var coordinates =
          responseJson['Result'][i]['geometries'][0]['coordinates'];
      print('this is $i th loop');
      print('coordinates = $coordinates');
      var latitude = coordinates.substring(0, 8);
      var longitude = coordinates.substring(11, 19);
      latitude = double.parse(latitude);
      longitude = double.parse(longitude);
      print('old latitude is $latitude');
      print('old longitude is $longitude');
      try {
        final newCoordinates =
            await CoordinateConverter().convert(latitude, longitude);
        print('newCoordinates is $newCoordinates');
        print('new coord = $newCoordinates');
        var convertedLat = newCoordinates['latitude'];
        var convertedLong = newCoordinates['longitude'];
        print('converted Lat = $convertedLat');
        print('converted Long = $convertedLong');
        convertedLat = convertedLat.toString();
        convertedLong = convertedLong.toString();
        var roundedLat = convertedLat.substring(0, 5);
        var roundedLong = convertedLong.substring(0, 7);
        print('rounded Lat = $roundedLat');
        print('rounded Long = $roundedLong');
        print('destination is $destination');
        var carparks = await searchNearby(destination);
        print(carparks);
        for (int x = 0; x < carparks.length; x++) {
          print('this is $x th loop');
          var googleLat = carparks[x]['geometry']['location']['lat'];
          var googleLong = carparks[x]['geometry']['location']['lng'];
          googleLat = googleLat.toString();
          googleLong = googleLong.toString();
          print('google lat is $googleLat');
          print('google long is $googleLong');
          var roundedgoogleLat = googleLat.substring(0, 5);
          var roundedgoogleLong = googleLong.substring(0, 7);
          print('rounded google lat is $roundedgoogleLat');
          print('rounded google long is $roundedgoogleLong');
          if (roundedgoogleLat == roundedLat &&
              roundedgoogleLong == roundedLong) {
            print('match found!');
            String cpNumber = responseJson['Result'][i]['carparkNo'];
            print("CP number is $cpNumber");
            String cpName = carparks[x]['name'];
            String cpAddress = carparks[x]['formatted_address'];
            print(cpName);
            cpName = cpName + ' ' + cpNumber;
            String lotsAvail = responseJson['Result'][i]['lotsAvailable'];
            print('Lots Available: $lotsAvail');

            //because some of the data in URA dataset is not consistent
            if (vehicleType == 'C' &&
                (responseJson['Result'][i]['lotType'] == vehicleType ||
                    responseJson['Result'][i]['lotType'] == 'Car' ||
                    responseJson['Result'][i]['lotType'] == 'car')) {
              String lotType = vehicleType;
              print('Lot type: $lotType');
              var distance = await GoogleMapsMgr()
                  .calculateDistance(cpAddress, destination);
              distance = distance.toString();
              print('distance is: $distance');
              List<String> lotInfo = [cpAddress, lotsAvail, lotType, distance];
              print('lotInfo list currently: $lotInfo');
              map[cpName] = lotInfo;
              print('map is currently: $map');
            }

            //because some of the data in URA dataset is not consistent
            if (vehicleType == 'M' &&
                (responseJson['Result'][i]['lotType'] == vehicleType ||
                    responseJson['Result'][i]['lotType'] == 'Motorcycle' ||
                    responseJson['Result'][i]['lotType'] == 'motorcycle')) {
              String lotType = vehicleType;
              print('Lot type: $lotType');
              var distance = await GoogleMapsMgr()
                  .calculateDistance(cpAddress, destination);
              distance = distance.toString();
              print('distance is: $distance');
              List<String> lotInfo = [cpAddress, lotsAvail, lotType, distance];
              print('lotInfo list currently: $lotInfo');
              map[cpName] = lotInfo;
              print('map is currently: $map');
            }

            //because some of the data in URA dataset is not consistent
            if (vehicleType == 'H' &&
                (responseJson['Result'][i]['lotType'] == vehicleType ||
                    responseJson['Result'][i]['lotType'] == 'Heavy Vehicle' ||
                    responseJson['Result'][i]['lotType'] == 'Heavy vehicle')) {
              String lotType = vehicleType;
              print('Lot type: $lotType');
              var distance = await GoogleMapsMgr()
                  .calculateDistance(cpAddress, destination);
              distance = distance.toString();
              print('distance is: $distance');
              List<String> lotInfo = [cpAddress, lotsAvail, lotType, distance];
              print('lotInfo list currently: $lotInfo');
              map[cpName] = lotInfo;
              print('map is currently: $map');
            }
          } else {
            print('LotType is not $vehicleType, rejected; not added to map');
          }
        }
      } catch (e) {
        print(e);
        continue;
      }
    }
    print('final map is $map');
    return map;
  }
}
