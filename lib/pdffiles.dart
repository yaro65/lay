import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

class PdfListPage extends StatefulWidget {
  const PdfListPage({Key? key}) : super(key: key);

  @override
  _PdfListPageState createState() => _PdfListPageState();
}

class _PdfListPageState extends State<PdfListPage> {
  List<File> _pdfFiles = [];

  @override
  void initState() {
    super.initState();
    _listOfPdfFiles();
  }

  Future<void> _listOfPdfFiles() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      List<FileSystemEntity> files = appDocDir.listSync(recursive: false);

      setState(() {
        _pdfFiles = files
            .whereType<File>()
            .where((file) => file.path.endsWith('.pdf'))
            .toList();
      });
    } catch (e) {
      print('Error while listing PDF files: $e');
    }
  }

  Future<void> _renamePdfFile(File pdfFile) async {
    TextEditingController controller = TextEditingController();
    controller.text = pdfFile.path.split('/').last.replaceAll('.pdf', '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer le fichier PDF'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nom du fichier'),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Renommer'),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                String newName = '${controller.text}.pdf';
                try {
                  File newFile = await pdfFile.rename(
                    '${pdfFile.parent.path}/$newName',
                  );
                  setState(() {
                    _pdfFiles[_pdfFiles.indexOf(pdfFile)] = newFile;
                  });
                  Navigator.pop(context);
                } catch (e) {
                  print('Error renaming PDF file: $e');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deletePdfFile(File pdfFile) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le fichier PDF'),
        content:
            const Text('Êtes-vous sûr de vouloir supprimer ce fichier PDF ?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Supprimer'),
            onPressed: () async {
              try {
                await pdfFile.delete();
                setState(() {
                  _pdfFiles.remove(pdfFile);
                });
                Navigator.pop(context);
              } catch (e) {
                print('Error deleting PDF file: $e');
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _savePdfFileToDevice(File pdfFile) async {
    try {
      // Lire le contenu du fichier PDF en tant que tableau d'octets
      final bytes = await pdfFile.readAsBytes();

      // Permettre à l'utilisateur de choisir le dossier
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory == null) {
        // L'utilisateur a annulé la sélection
        return;
      }

      // Créer un nouveau fichier dans le dossier sélectionné
      final file = File('$selectedDirectory/${pdfFile.path.split('/').last}');

      // Écrire le contenu du fichier PDF dans le nouveau fichier
      await file.writeAsBytes(bytes);

      // Afficher un message de succès à l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fichier PDF enregistré dans $selectedDirectory'),
        ),
      );
    } catch (e) {
      // En cas d'erreur, afficher un message d'erreur
      print('Error saving PDF file to device: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'enregistrement du fichier PDF'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des fichiers PDF'),
      ),
      body: _pdfFiles.isEmpty
          ? const Center(
              child: Text('Aucun fichier PDF trouvé.'),
            )
          : ListView.builder(
              itemCount: _pdfFiles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_pdfFiles[index].path.split('/').last),
                  leading: const Icon(Icons.picture_as_pdf),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PdfViewerPage(
                          pdfPath: _pdfFiles[index].path,
                        ),
                      ),
                    );
                  },
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Renommer'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('Supprimer'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'saveToDevice',
                        child: ListTile(
                          leading: Icon(Icons.save_alt),
                          title: Text('Enregistrer sur l\'appareil'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: ListTile(
                          leading: Icon(Icons.share),
                          title: Text('Partager'),
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'rename':
                          _renamePdfFile(_pdfFiles[index]);
                          break;
                        case 'delete':
                          _deletePdfFile(_pdfFiles[index]);
                          break;
                        case 'saveToDevice':
                          _savePdfFileToDevice(_pdfFiles[index]);
                          break;
                        case 'share':
                          _sharePdfFile(_pdfFiles[index]);
                          break;
                        default:
                      }
                    },
                  ),
                );
              },
            ),
    );
  }

  Future<void> _sharePdfFile(File pdfFile) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${pdfFile.path.split('/').last}');
      await tempFile.writeAsBytes(bytes);

      final result = await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'Partage de fichier PDF',
        subject: 'Sujet du fichier PDF',
      );
    } catch (e) {
      print('Erreur lors du partage du fichier PDF : $e');
    }
  }
}

class PdfViewerPage extends StatelessWidget {
  final String pdfPath;

  const PdfViewerPage({Key? key, required this.pdfPath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visualisation du PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: () {
              Navigator.pop(context); // Retour à la liste des PDF
            },
          ),
        ],
      ),
      body: PDFView(
        filePath: pdfPath,
        onPageChanged: (page, total) {
          print('Page changée: $page/$total');
        },
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: PdfListPage(),
  ));
}
