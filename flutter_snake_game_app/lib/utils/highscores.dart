import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HighScoresTile extends StatelessWidget {
  final String docId;
  const HighScoresTile({super.key, required this.docId});

  @override
  Widget build(BuildContext context) {
    //get access to the collection of high scores
    CollectionReference collection =
        FirebaseFirestore.instance.collection("highscores");
    return FutureBuilder<DocumentSnapshot>(
        future: collection.doc(docId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            //we are taking the data that we got from a particular docid as a map
            Map<String, dynamic> data =
                snapshot.data!.data() as Map<String, dynamic>;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(data["name"]), Text(data["score"].toString())],
            );
          } else {
            return Text("loading......");
          }
        });
  }
}
