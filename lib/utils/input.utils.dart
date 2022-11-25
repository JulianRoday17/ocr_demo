import 'package:flutter/material.dart';

Widget textContainerWithLabel(String title, String hintText,
        TextEditingController controller, height, enable) =>
    Padding(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              title,
            ),
          ),
          SizedBox(height: 2),
          Container(
            alignment: Alignment.center,
            width: double.infinity,
            height: height,
            constraints: BoxConstraints(minHeight: 50),
            padding: EdgeInsets.only(left: 5, top: 5, bottom: 5),
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.all(Radius.circular(10))),
            child: TextField(
              style: TextStyle(color: Colors.grey.shade700),
              enabled: true,
              controller: controller,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                contentPadding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              ),
            ),
          ),
        ]));
