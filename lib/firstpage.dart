import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opencv_4/factory/pathfrom.dart';
import 'package:opencv_4/opencv_4.dart';
import 'package:pdf/pdf.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';

class Firstpage extends StatefulWidget {
  const Firstpage({Key? key}) : super(key: key);

  @override
  _FirstpageState createState() => _FirstpageState();
}

class _FirstpageState extends State<Firstpage> {
  final picker = ImagePicker();
  final pdf = pw.Document();
  List<Uint8List> image = [];
  File? _image;
  Uint8List? _byte;
  String _versionOpenCV = 'OpenCV';
  bool _visible = false;
  bool _isPdfGenerated = false;
  bool _isLoading = false;
  List<File> _pdfFiles = [];

  @override
  void initState() {
    super.initState();
    _getOpenCVVersion();
  }

  Future<void> _getOpenCVVersion() async {
    String? versionOpenCV = await Cv2.version();
    setState(() {
      _versionOpenCV = 'OpenCV: ' + versionOpenCV!;
    });
  }

  Future<void> getImageFromGallery() async {
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      for (var pickedFile in pickedFiles) {
        File imageFile = File(pickedFile.path);

        final croppedFile = await ImageCropper().cropImage(
          sourcePath: imageFile.path,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9
          ],
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Recadrer l\'image',
              toolbarColor: Colors.grey[600],
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              minimumAspectRatio: 1.0,
            )
          ],
        );

        if (croppedFile != null) {
          imageFile = File(croppedFile.path);
          _image = imageFile;
          await processImageWithOpenCV();
        }
      }
    }
    // setState(() {
    //   _isLoading = true;
    // });
  }

  Future<void> getImageFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recadrer l\'image',
            toolbarColor: Colors.grey[600],
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            minimumAspectRatio: 1.0,
          )
        ],
      );

      if (croppedFile != null) {
        imageFile = File(croppedFile.path);
        _image = imageFile;
        await processImageWithOpenCV();
      }
    }
  }

  Future<void> processImageWithOpenCV() async {
    try {
      _byte = await Cv2.threshold(
        pathFrom: CVPathFrom.GALLERY_CAMERA,
        pathString: _image!.path,
        maxThresholdValue: 150,
        thresholdType: Cv2.THRESH_BINARY,
        thresholdValue: 120,
      );

      setState(() {
        image.add(_byte!);
        _visible = true;
        _isLoading = false; // Désactiver l'indicateur de chargement
      });
    } on PlatformException catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (kDebugMode) {
        print("OpenCV error: ${e.message}");
      }
    }
  }

  Future<Uint8List> generateDocument(
    PdfPageFormat format,
    int imageLength,
    List<Uint8List> images,
  ) async {
    setState(() {
      _isLoading = false;
    });

    final doc = pw.Document(pageMode: PdfPageMode.outlines);

    final font1 = await PdfGoogleFonts.openSansRegular();
    final font2 = await PdfGoogleFonts.openSansBold();
    final PdfColor transparentColor = PdfColor.fromInt(0x00000000);

    for (var i = 0; i < images.length; i++) {
      var im = images[i];

      // Convertir l'Uint8List en image
      img.Image imgImage = img.decodeImage(im)!;
      img.adjustColor(imgImage, brightness: 30);
      Uint8List adjustedImage = img.encodePng(imgImage);

      final showimage = pw.MemoryImage(adjustedImage);

      doc.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: format.copyWith(
              marginBottom: 0,
              marginLeft: 0,
              marginRight: 0,
              marginTop: 0,
            ),
            orientation: pw.PageOrientation.portrait,
            theme: pw.ThemeData.withFont(
              base: font1,
              bold: font2,
            ),
          ),
          build: (context) {
            return pw.Stack(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(20),
                  child: pw.Center(
                    child: pw.Container(
                      width: format.width,
                      height: format.height,
                      color: transparentColor,
                      child: pw.Image(
                        showimage,
                        fit: pw.BoxFit.fill,
                      ),
                    ),
                  ),
                ),
                pw.Positioned(
                  bottom: 10,
                  left: 550,
                  child: pw.Text(
                    'Page ${i + 1}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Libérer la mémoire des images
      imgImage.clear();
    }

    final Uint8List pdfBytes = await doc.save();
    await savePdf(pdfBytes);
    return pdfBytes;
  }

  Future<void> savePdf(Uint8List pdfBytes) async {
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final String dateTime = DateTime.now().millisecondsSinceEpoch.toString();
      final String path = '${directory.path}/mon_fichier_$dateTime.pdf';
      final File file = File(path);
      await file.writeAsBytes(pdfBytes);
      _pdfFiles.add(file);
    } catch (e) {
      print('Erreur lors de l\'enregistrement du PDF : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erreur lors de l\'enregistrement du PDF')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('PDF Generated: $_isPdfGenerated');

    return Scaffold(
      body: Stack(
        children: [
          image.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 100),
                        Text(
                          "Générer un document PDF à partir de vos photos",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.indigo[900],
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                )
              : PdfPreview(
                  maxPageWidth: 1000,
                  canChangeOrientation: true,
                  canDebug: false,
                  build: (format) => generateDocument(
                    format,
                    image.length,
                    image,
                  ),
                ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Visibility(
            visible: _visible,
            child: FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  image.clear();
                  _visible = false;
                  _isPdfGenerated = false;
                });
              },
              label: const Text(''),
              icon: const Icon(Icons.refresh),
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: getImageFromGallery,
            tooltip: 'Sélectionner depuis la galerie',
            heroTag: 'gallery',
            child: const Icon(Icons.photo_library),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: getImageFromCamera,
            tooltip: 'Prendre une photo',
            heroTag: 'camera',
            child: const Icon(Icons.camera_alt),
          ),
        ],
      ),
    );
  }
}
