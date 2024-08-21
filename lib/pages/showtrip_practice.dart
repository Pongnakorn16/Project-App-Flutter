import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/get_trips_res.dart';
import 'package:mobile_miniproject_app/pages/profile.dart';
import 'package:mobile_miniproject_app/pages/trip.dart';

class ShowtripPracticePage extends StatefulWidget {
  int idx = 0;
  ShowtripPracticePage({super.key, required this.idx});

  @override
  State<ShowtripPracticePage> createState() => _ShowtripPracticePageState();
}

class _ShowtripPracticePageState extends State<ShowtripPracticePage> {
  String url = '';
  List<TripsGetRespones> trips = [];
//3. dclare async object
  late Future<void> loadData;

  @override
  void initState() {
    super.initState();
    //4.Create object loadData
    loadData = loadDataAsync();
    // getTrips();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการทริป'),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              log(value);
              if (value == 'profile') {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(idx: widget.idx),
                    ));
              } else if (value == 'logout') {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'profile',
                child: Text('ข้อมูลส่วนตัว'),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('ออกจากระบบ'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 2.0, left: 16.0),
                  child: Text('ปลายทาง'),
                ),
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: FilledButton(
                    onPressed: () => getTrips(null),
                    child: const Text('ทั้งหมด'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: FilledButton(
                    onPressed: () => getTrips("เอเชีย"),
                    child: const Text('เอเชีย'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: FilledButton(
                    onPressed: () => getTrips("ยุโรป"),
                    child: const Text('ยุโรป'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: FilledButton(
                    onPressed: () => getTrips("เอเชียตะวันออกเฉียงใต้"),
                    child: const Text('อาเซียน'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: FilledButton(
                    onPressed: () => getTrips("อเมริกาเหนือ"),
                    child: const Text('อเมริกาเหนือ'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: FilledButton(
                    onPressed: () => getTrips("อเมริกาใต้"),
                    child: const Text('อเมริกาใต้'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: FilledButton(
                    onPressed: () => getTrips("แอฟริกา"),
                    child: const Text('แอฟริกา'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: FilledButton(
                    onPressed: () => getTrips("แอนตาร์กติกา"),
                    child: const Text('แอนตาร์กติกา'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: FilledButton(
                    onPressed: () => getTrips("ประเทศไทย"),
                    child: const Text('ประเทศไทย'),
                  ),
                ),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: FutureBuilder(
                    //5.call function
                    future: loadData,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      return SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: trips
                              .map(
                                (trip) => Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(9.0),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              trip.name,
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  width: 95,
                                                  height: 100,
                                                  child: Image.network(
                                                    trip.coverimage,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      'ประเทศ ${trip.country}'),
                                                  Text(
                                                      'ระยะเวลา ${trip.duration} วัน'),
                                                  Text(
                                                      'ราคา ${trip.price} บาท'),
                                                  FilledButton(
                                                    onPressed: () {
                                                      Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                TripPage(
                                                                    idx: trip
                                                                        .idx),
                                                          ));
                                                    },
                                                    child: const Text(
                                                        'รายละเอียดเพิ่มเติม'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Card(
                                //   child: Text(trip.name),
                                // ),
                              )
                              .toList(),
                          // children: [
                          //   Card(
                          //     child: Padding(
                          //       padding: const EdgeInsets.all(9.0),
                          //       child: Column(
                          //         children: [
                          //           const Row(
                          //             mainAxisAlignment: MainAxisAlignment.start,
                          //             children: [
                          //               Text(
                          //                 'อันซีนสวิตเซอร์แลนด์',
                          //                 style: TextStyle(
                          //                     fontSize: 20,
                          //                     fontWeight: FontWeight.bold),
                          //               ),
                          //             ],
                          //           ),
                          //           Row(
                          //             children: [
                          //               Column(
                          //                 crossAxisAlignment:
                          //                     CrossAxisAlignment.start,
                          //                 children: [
                          //                   SizedBox(
                          //                     width: 160,
                          //                     height: 150,
                          //                     child: Image.asset(
                          //                       'assets/images/Unseen.jpg',
                          //                     ),
                          //                   ),
                          //                 ],
                          //               ),
                          //               Padding(
                          //                 padding: const EdgeInsets.all(8.0),
                          //                 child: Column(
                          //                   crossAxisAlignment:
                          //                       CrossAxisAlignment.start,
                          //                   children: [
                          //                     const Text('ประเทศสวิตเซอร์แลนด์'),
                          //                     const Text('ระยะเวลา 10 วัน'),
                          //                     const Text('ราคา 119900 บาท'),
                          //                     FilledButton(
                          //                       onPressed: () {},
                          //                       child:
                          //                           const Text('รายละเอียดเพิ่มเติม'),
                          //                     ),
                          //                   ],
                          //                 ),
                          //               ),
                          //             ],
                          //           ),
                          //         ],
                          //       ),
                          //     ),
                          //   ),
                          //   Card(
                          //     child: Padding(
                          //       padding: const EdgeInsets.all(9.0),
                          //       child: Column(
                          //         children: [
                          //           const Row(
                          //             mainAxisAlignment: MainAxisAlignment.start,
                          //             children: [
                          //               Text(
                          //                 'Three Natural Bridges',
                          //                 style: TextStyle(
                          //                     fontSize: 20,
                          //                     fontWeight: FontWeight.bold),
                          //               ),
                          //             ],
                          //           ),
                          //           Row(
                          //             children: [
                          //               Column(
                          //                 crossAxisAlignment:
                          //                     CrossAxisAlignment.start,
                          //                 children: [
                          //                   SizedBox(
                          //                     width: 160,
                          //                     height: 150,
                          //                     child: Image.asset(
                          //                       'assets/images/ThreeNatural.jpg',
                          //                     ),
                          //                   ),
                          //                 ],
                          //               ),
                          //               Padding(
                          //                 padding: const EdgeInsets.all(8.0),
                          //                 child: Column(
                          //                   crossAxisAlignment:
                          //                       CrossAxisAlignment.start,
                          //                   children: [
                          //                     const Text('ประเทศจีน'),
                          //                     const Text('ระยะเวลา 10 วัน'),
                          //                     const Text('ราคา 119900 บาท'),
                          //                     FilledButton(
                          //                       onPressed: () {},
                          //                       child:
                          //                           const Text('รายละเอียดเพิ่มเติม'),
                          //                     ),
                          //                   ],
                          //                 ),
                          //               ),
                          //             ],
                          //           ),
                          //         ],
                          //       ),
                          //     ),
                          //   ),
                          //   Card(
                          //     child: Padding(
                          //       padding: const EdgeInsets.all(9.0),
                          //       child: Column(
                          //         children: [
                          //           const Row(
                          //             mainAxisAlignment: MainAxisAlignment.start,
                          //             children: [
                          //               Text(
                          //                 'Petra',
                          //                 style: TextStyle(
                          //                     fontSize: 20,
                          //                     fontWeight: FontWeight.bold),
                          //               ),
                          //             ],
                          //           ),
                          //           Row(
                          //             children: [
                          //               Column(
                          //                 crossAxisAlignment:
                          //                     CrossAxisAlignment.start,
                          //                 children: [
                          //                   SizedBox(
                          //                     width: 160,
                          //                     height: 150,
                          //                     child: Image.asset(
                          //                       'assets/images/Petra.jpg',
                          //                     ),
                          //                   ),
                          //                 ],
                          //               ),
                          //               Padding(
                          //                 padding: const EdgeInsets.all(8.0),
                          //                 child: Column(
                          //                   crossAxisAlignment:
                          //                       CrossAxisAlignment.start,
                          //                   children: [
                          //                     const Text('ประเทศจอร์แดน'),
                          //                     const Text('ระยะเวลา 10 วัน'),
                          //                     const Text('ราคา 119900 บาท'),
                          //                     FilledButton(
                          //                       onPressed: () {},
                          //                       child:
                          //                           const Text('รายละเอียดเพิ่มเติม'),
                          //                     ),
                          //                   ],
                          //                 ),
                          //               ),
                          //             ],
                          //           ),
                          //         ],
                          //       ),
                          //     ),
                          //   ),
                          //   Card(
                          //     child: Padding(
                          //       padding: const EdgeInsets.all(9.0),
                          //       child: Column(
                          //         children: [
                          //           const Row(
                          //             mainAxisAlignment: MainAxisAlignment.start,
                          //             children: [
                          //               Text(
                          //                 'Cinque Terre',
                          //                 style: TextStyle(
                          //                     fontSize: 20,
                          //                     fontWeight: FontWeight.bold),
                          //               ),
                          //             ],
                          //           ),
                          //           Row(
                          //             children: [
                          //               Column(
                          //                 crossAxisAlignment:
                          //                     CrossAxisAlignment.start,
                          //                 children: [
                          //                   SizedBox(
                          //                     width: 160,
                          //                     height: 150,
                          //                     child: Image.asset(
                          //                       'assets/images/Cinque.jpg',
                          //                     ),
                          //                   ),
                          //                 ],
                          //               ),
                          //               Padding(
                          //                 padding: const EdgeInsets.all(8.0),
                          //                 child: Column(
                          //                   crossAxisAlignment:
                          //                       CrossAxisAlignment.start,
                          //                   children: [
                          //                     const Text('ประเทศอิตาลี'),
                          //                     const Text('ระยะเวลา 10 วัน'),
                          //                     const Text('ราคา 119900 บาท'),
                          //                     FilledButton(
                          //                       onPressed: () {},
                          //                       child:
                          //                           const Text('รายละเอียดเพิ่มเติม'),
                          //                     ),
                          //                   ],
                          //                 ),
                          //               ),
                          //             ],
                          //           ),
                          //         ],
                          //       ),
                          //     ),
                          //   ),
                          //   Card(
                          //     child: Padding(
                          //       padding: const EdgeInsets.all(9.0),
                          //       child: Column(
                          //         children: [
                          //           const Row(
                          //             mainAxisAlignment: MainAxisAlignment.start,
                          //             children: [
                          //               Text(
                          //                 'Glass Beach',
                          //                 style: TextStyle(
                          //                     fontSize: 20,
                          //                     fontWeight: FontWeight.bold),
                          //               ),
                          //             ],
                          //           ),
                          //           Row(
                          //             children: [
                          //               Column(
                          //                 crossAxisAlignment:
                          //                     CrossAxisAlignment.start,
                          //                 children: [
                          //                   SizedBox(
                          //                     width: 160,
                          //                     height: 150,
                          //                     child: Image.asset(
                          //                       'assets/images/GlassBeach.jpg',
                          //                     ),
                          //                   ),
                          //                 ],
                          //               ),
                          //               Padding(
                          //                 padding: const EdgeInsets.all(8.0),
                          //                 child: Column(
                          //                   crossAxisAlignment:
                          //                       CrossAxisAlignment.start,
                          //                   children: [
                          //                     const Text('แคลิฟอร์เนีย สหรัฐอเมริกา'),
                          //                     const Text('ระยะเวลา 10 วัน'),
                          //                     const Text('ราคา 119900 บาท'),
                          //                     FilledButton(
                          //                       onPressed: () {},
                          //                       child:
                          //                           const Text('รายละเอียดเพิ่มเติม'),
                          //                     ),
                          //                   ],
                          //                 ),
                          //               ),
                          //             ],
                          //           ),
                          //         ],
                          //       ),
                          //     ),
                          //   ),
                          // ],
                        ),
                      );
                    }),
              ),
            )
          ],
        ),
      ),
    );
  }

  //declare (async) function for loading  data from api

  Future<void> loadDataAsync() async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    var json = await http.get(Uri.parse("$url/trips"));
    trips = tripsGetResponesFromJson(json.body);
  }

  void getTrips(String? zone) async {
    // 1. Load url from config
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    // 2. Call Get / trips
    var json = await http.get(Uri.parse("$url/trips"));
    trips = tripsGetResponesFromJson(json.body);
    log('API response body: ${json.body}');

    // 3. Put response data to model
    List<TripsGetRespones> filteredTrips = [];
    // 3.1 Check if zone is "ทั้งหมด" (all)
    if (zone == null) {
      filteredTrips = trips; // Show all trips
    } else {
      for (var trip in trips) {
        String tripZone = destinationZoneValues.reverse[trip.destinationZone]!;
        if (tripZone == zone) {
          filteredTrips.add(trip);
        }
      }
    }

    trips = filteredTrips;

    // 4. Log number of trips
    log(trips.length.toString());
    setState(() {});
  }
}
