import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/get_trips_res.dart';
import 'package:mobile_miniproject_app/models/response/trips_idx_get_res.dart';

class TripPage extends StatefulWidget {
  int idx = 0;
  TripPage({super.key, required this.idx});

  @override
  State<TripPage> createState() => _TripPageState();
}

class _TripPageState extends State<TripPage> {
  String url = '';
  late TripIdxGetResponse trip;

  late Future<void> loadData;

  @override
  void initState() {
    super.initState();
    // log(widget.idx.toString());
    loadData = loadDataAsync();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder(
          future: loadData,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return SingleChildScrollView(
                child: Column(
              children: [
                Text(trip.name),
                Image.network(trip.coverimage),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(trip.price.toString()),
                    Text(trip.destinationZone)
                  ],
                ),
                Column(
                  children: [
                    Text(trip.detail.toString()),
                    FilledButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TripPage(idx: trip.idx),
                            ));
                      },
                      child: const Text('จองเลย!!!'),
                    ),
                  ],
                )
              ],
            ));
          }),
    );
  }

  Future<void> loadDataAsync() async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    var res = await http.get(Uri.parse("$url/trips/${widget.idx}"));
    trip = tripIdxGetResponseFromJson(res.body);
  }
}
