import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ImageViewScreen extends StatefulWidget {
  final String imageUrl;

  ImageViewScreen({required this.imageUrl});

  @override
  _ImageViewScreenState createState() => _ImageViewScreenState();
}

class _ImageViewScreenState extends State<ImageViewScreen> {
  double _textPositionX = 20.0;
  double _textPositionY = 80.0;
  double _logoPositionX = 20.0;
  double _logoPositionY = 20.0;
  final GlobalKey _repaintKey = GlobalKey();
  Color _textColor = Colors.white; // Default text color
  String? _savedName;
  String? _savedEmail;
  String? _savedPhone;
  File? _savedLogo;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedName = prefs.getString('business_name');
      _savedEmail = prefs.getString('business_email');
      _savedPhone = prefs.getString('business_mobile');
      String? logoPath = prefs.getString('business_image');
      if (logoPath != null && logoPath.isNotEmpty) {
        _savedLogo = File(logoPath);
      }
    });
  }

  void _resetPosition() {
    setState(() {
      _textPositionX = 20.0;
      _textPositionY = 80.0;
      _logoPositionX = 20.0;
      _logoPositionY = 20.0;
    });
  }

  void _openColorPicker() async {
    Color? selectedColor = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose Text Color'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorOption(color: Colors.red, label: 'Red'),
            ColorOption(color: Colors.green, label: 'Green'),
            ColorOption(color: Colors.blue, label: 'Blue'),
            ColorOption(color: Colors.black, label: 'Black'),
            ColorOption(color: Colors.white, label: 'White'),
          ],
        ),
      ),
    );

    if (selectedColor != null) {
      setState(() {
        _textColor = selectedColor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image View'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetPosition,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: RepaintBoundary(
                    key: _repaintKey,
                    child: Stack(
                      children: [
                        Image.network(
                          widget.imageUrl,
                          width: constraints.maxWidth,
                          fit: BoxFit.fitWidth,
                        ),
                        // Draggable Text
                        if (_savedName != null || _savedEmail != null || _savedPhone != null)
                          Positioned(
                            left: _textPositionX,
                            top: _textPositionY,
                            child: Draggable(
                              feedback: Material(
                                color: Colors.transparent,
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    '${_savedName ?? ''}\n${_savedEmail ?? ''}\n${_savedPhone ?? ''}',
                                    style: TextStyle(color: _textColor, fontSize: 18),
                                  ),
                                ),
                              ),
                              childWhenDragging: Container(),
                              child: Material(
                                color: Colors.transparent,
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    '${_savedName ?? ''}\n${_savedEmail ?? ''}\n${_savedPhone ?? ''}',
                                    style: TextStyle(color: _textColor, fontSize: 18),
                                  ),
                                ),
                              ),
                              onDragUpdate: (details) {
                                setState(() {
                                  _textPositionX = details.localPosition.dx - 80;
                                  _textPositionY = details.localPosition.dy - 80;
                                  if (_textPositionX < 0) _textPositionX = 0;
                                  if (_textPositionY < 0) _textPositionY = 0;
                                  if (_textPositionX > constraints.maxWidth - 80) {
                                    _textPositionX = constraints.maxWidth - 80;
                                  }
                                  if (_textPositionY > constraints.maxHeight - 80) {
                                    _textPositionY = constraints.maxHeight - 80;
                                  }
                                });
                              },
                            ),
                          ),
                        // Draggable Logo
                        if (_savedLogo != null)
                          Positioned(
                            left: _logoPositionX,
                            top: _logoPositionY,
                            child: Draggable(
                              feedback: Material(
                                color: Colors.transparent,
                                child: Image.file(
                                  _savedLogo!,
                                  width: 100,
                                  height: 100,
                                ),
                              ),
                              childWhenDragging: Container(),
                              child: Material(
                                color: Colors.transparent,
                                child: Image.file(
                                  _savedLogo!,
                                  width: 100,
                                  height: 100,
                                ),
                              ),
                              onDragUpdate: (details) {
                                setState(() {
                                  _logoPositionX = details.localPosition.dx - 50;
                                  _logoPositionY = details.localPosition.dy - 50;
                                  if (_logoPositionX < 0) _logoPositionX = 0;
                                  if (_logoPositionY < 0) _logoPositionY = 0;
                                  if (_logoPositionX > constraints.maxWidth - 100) {
                                    _logoPositionX = constraints.maxWidth - 100;
                                  }
                                  if (_logoPositionY > constraints.maxHeight - 100) {
                                    _logoPositionY = constraints.maxHeight - 100;
                                  }
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _openColorPicker,
            child: Text('Change Text Color'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveScreenshot();
            },
            child: Text('Save Image'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveScreenshot() async {
    try {
      RenderRepaintBoundary boundary =
      _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage();
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final result = await ImageGallerySaver.saveImage(Uint8List.fromList(pngBytes));
      print("Image saved to gallery: $result");

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image saved to gallery!')));
    } catch (e) {
      print("Error saving screenshot: $e");
    }
  }
}

class ColorOption extends StatelessWidget {
  final Color color;
  final String label;

  const ColorOption({Key? key, required this.color, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(color),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.all(8),
        color: color.withOpacity(0.5),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 18),
        ),
      ),
    );
  }
}
