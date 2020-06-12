import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gramyshare/models/user.dart';
import 'package:gramyshare/screens/home.dart';
import 'package:gramyshare/widget/loading.dart';
import 'package:image/image.dart' as Img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class UploadScreen extends StatefulWidget {
  final User currentUser;

  UploadScreen({
    this.currentUser,
  });

  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with AutomaticKeepAliveClientMixin<UploadScreen> {
  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();
  File file;
  bool isUploading = false;
  String postId = Uuid().v4();

  takePhoto() async {
    Navigator.pop(context);
    // ignore: deprecated_member_use
    File file = await ImagePicker.pickImage(
        source: ImageSource.camera, maxHeight: 600, maxWidth: 900);
    setState(() {
      this.file = file;
    });
  }

  choosePhoto() async {
    Navigator.pop(context);
    // ignore: deprecated_member_use
    File file = await ImagePicker.pickImage(
        source: ImageSource.gallery, maxHeight: 600, maxWidth: 900);
    setState(() {
      this.file = file;
    });
  }

  uploadPhoto(parContext) {
    return showDialog(
        context: parContext,
        builder: (context) {
          return SimpleDialog(
            title: Text('Create Post'),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: choosePhoto,
                child: Text(
                  'From Gallery',
                ),
              ),
              SimpleDialogOption(
                onPressed: takePhoto,
                child: Text(
                  'From Camera',
                ),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                ),
              ),
            ],
          );
        });
  }

  Container splashScreen() {
    final height = MediaQuery.of(context).size.height;
    final Orientation orientation = MediaQuery.of(context).orientation;

    return Container(
      color: Colors.pink[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset(
            'assets/images/upload.svg',
            height:
                orientation == Orientation.portrait ? height / 2.5 : height / 3,
          ),
          Padding(
            padding: EdgeInsets.only(top: 25),
            child: RaisedButton(
              onPressed: () => uploadPhoto(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                'Upload Photo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 25),
              color: Colors.lightBlue,
              elevation: 5,
              animationDuration: Duration(seconds: 2),
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
          ),
        ],
      ),
    );
  }

  clearPhoto() {
    setState(() {
      file = null;
    });
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Img.Image imageFile = Img.decodeImage(
      file.readAsBytesSync(),
    );
    final compressImg = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(
        Img.encodeJpg(
          imageFile,
          quality: 80,
        ),
      );
    setState(() {
      file = compressImg;
    });
  }

  Future<String> uploadPhotoToFirebase(imageFile) async {
    StorageUploadTask uploadTask =
        storageRef.child('post_$postId.jpg').putFile(imageFile);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  uploadPost() async {
    setState(() {
      isUploading = true;
    });
    await compressImage();
    String mediaUrl = await uploadPhotoToFirebase(file);
    createPost(
      mediaUrl: mediaUrl,
      description: captionController.text,
      location: locationController.text,
    );
  }

  createPost({String mediaUrl, String location, String description}) {
    postsRef
        .document(widget.currentUser.id)
        .collection('userPosts')
        .document(postId)
        .setData({
      'postId': postId,
      'ownerId': widget.currentUser.id,
      'username': widget.currentUser.username,
      'mediaUrl': mediaUrl,
      'description': description,
      'location': location,
      'timestamp': timestamp,
      'likes': {},
    });
    captionController.clear();
    locationController.clear();
    setState(() {
      file = null;
      isUploading = false;
      postId = Uuid().v4();
    });
  }

  Scaffold uploadForm() {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white70,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: clearPhoto,
        ),
        title: Text(
          'Caption Post',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        actions: <Widget>[
          FlatButton(
            onPressed: isUploading ? null : uploadPost,
            child: Text(
              'Post',
              style: TextStyle(
                color: Colors.lightBlue,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        children: <Widget>[
          isUploading ? linearProgress() : Text(''),
          Container(
            width: 400,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(
                        file,
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          ListTile(
            leading: CircleAvatar(
              // backgroundColor: Colors.grey,
              backgroundImage:
                  CachedNetworkImageProvider(widget.currentUser.photoUrl),
            ),
            title: Container(
              width: 250,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                    hintText: 'Type a caption...', border: InputBorder.none),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.pin_drop,
              color: Colors.orange,
              size: 35,
            ),
            title: Container(
              width: 300,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                  hintText: 'From Where ?',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            height: 90,
            width: 200,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              padding: EdgeInsets.symmetric(horizontal: 30),
              color: Colors.lightBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: getUserLocation,
              label: Text(
                'Select your Loction',
                style: TextStyle(color: Colors.white),
              ),
              icon: Icon(
                Icons.my_location,
                color: Colors.orange,
              ),
            ),
          )
        ],
      ),
    );
  }

  getUserLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark = placemarks[0];
    String completeAddress =
        '${placemark.subThoroughfare} ${placemark.thoroughfare}, ${placemark.subLocality} ${placemark.locality}, ${placemark.subAdministrativeArea}, ${placemark.administrativeArea} ${placemark.postalCode}, ${placemark.country}';
    print(completeAddress);
    String formattedAddress = "${placemark.locality}, ${placemark.country}";
    locationController.text = formattedAddress;
  }

  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return file == null ? splashScreen() : uploadForm();
  }
}
