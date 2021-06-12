import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path/path.dart' as Path;

class AddImage extends StatefulWidget {
  @override
  _AddImageState createState() => _AddImageState();
}

class _AddImageState extends State<AddImage> {

  bool uploading = false;
  double val = 0;

  late CollectionReference imgRef;
  late firebase_storage.Reference ref;

  List<File> _image = [];
  final picker = ImagePicker();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Image'),
        actions: [FlatButton(onPressed: () {
          uploadFile().whenComplete(() => Navigator.of(context).pop());
        },
            child: Text('upload'))],
      ),
      body: Stack(
        children:[
        GridView.builder(
          itemCount: _image.length+1,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
          itemBuilder: (context, index) {
            return index == 0
                ? Center(
                    child: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      chooseImage();
                    },
                  ))
                : Container(
              margin: EdgeInsets.all(3),
              decoration: BoxDecoration(image: DecorationImage(image: FileImage(_image[index-1]), fit: BoxFit.cover )),
            );
          },
        ),
          uploading ? Center(child: CircularProgressIndicator()): Center(child: Text('Uploaded'))
        ]
      ),
    );
  }

  chooseImage() async {
    
    final pickerFile = await picker.getImage(source: ImageSource.gallery);
    setState(() {
      _image.add(File(pickerFile!.path));
    });
    if(pickerFile!.path == null) retrieveLostData();
  }

  Future<void> retrieveLostData() async {
    final LostData response = await picker.getLostData();
    if(response.isEmpty){
      return;
    }
    if(response.file != null){
      setState(() {
        _image.add(File(response.file!.path));
      });
    }
    else{
      print(response.file);
    }
  }

  Future uploadFile() async {
    for(var img in _image){
        ref = firebase_storage.FirebaseStorage.instance.ref().child('images/${Path.basename(img.path)}');
        await ref.putFile(img).whenComplete(() async {
            await ref.getDownloadURL().then((value){
                imgRef.add({'url': value});
            });
        });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    imgRef = FirebaseFirestore.instance.collection('imageUrls');

  }
}
