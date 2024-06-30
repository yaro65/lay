import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:image_gallery_saver/image_gallery_saver.dart';

import 'package:scribble/scribble.dart';

class Thirdpage extends StatefulWidget {
  const Thirdpage({Key? key}) : super(key: key);

  @override
  State<Thirdpage> createState() => _ThirdpageState();
}

class _ThirdpageState extends State<Thirdpage> {
  late ScribbleNotifier notifier;
  File? filei;
  ImagePicker image = ImagePicker();
  Color backgroundColor = Colors.black;

  @override
  void initState() {
    notifier = ScribbleNotifier();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          backgroundColor, // Utilisation de la couleur de fond sélectionnée
      appBar: AppBar(
        title: const Text(
          "Enregistrer",
          style: TextStyle(
            fontSize: 25,
          ),
        ),
        backgroundColor: Colors.grey[600],
        actions: [
          IconButton(
            icon: const Icon(
              Icons.save,
              size: 30,
            ),
            tooltip: "Save to Image",
            onPressed: () => _saveImage(context),
          ),
          _buildBackgroundColorButton(
              Icons.circle, Colors.black), // Bouton noir
          _buildBackgroundColorButton(
              Icons.circle, Colors.white), // Bouton blanc
        ],
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 2,
          child: Stack(
            children: [
              Container(
                height: MediaQuery.of(context).size.height *
                    0.2, // Définir la hauteur du Container
                child: Scribble(
                  notifier: notifier,
                  drawPen: true,
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Column(
                  children: [
                    _buildColorToolbar(context),
                    const Divider(
                      height: 32,
                    ),
                    _buildStrokeToolbar(context),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundColorButton(IconData icon, Color color) {
    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: () {
        setState(() {
          backgroundColor = color; // Mettre à jour la couleur de fond

          // Changer la couleur opposée
          if (color == Colors.black) {
            // Si la couleur sélectionnée est noire, le fond blanc devient noir
            backgroundColor = Colors.white;
          } else {
            // Sinon, le fond noir devient blanc
            backgroundColor = Colors.black;
          }
        });
      },
    );
  }

  Future<void> _saveImage(BuildContext context) async {
    final image = await notifier.renderImage();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: MaterialButton(
          onPressed: () async {
            await ImageGallerySaver.saveImage(
              image.buffer.asUint8List(),
              quality: 100,
            );
            print("Image enregistrée dans la galerie");
            Navigator.pop(context);
          },
          child: Text(
            "ENREGISTRER",
            style: TextStyle(
              color: Colors.blue[900],
            ),
          ),
        ),
        content: Container(
          color: Colors.black,
          child: Image.memory(
            image.buffer.asUint8List(),
            colorBlendMode: BlendMode.screen,
          ),
        ),
      ),
    );
  }

  Widget _buildStrokeToolbar(BuildContext context) {
    return ValueListenableBuilder<ScribbleState>(
      valueListenable: notifier,
      builder: (context, state, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          for (final w in notifier.widths)
            _buildStrokeButton(
              context,
              strokeWidth: w,
              state: state,
            ),
        ],
      ),
    );
  }

  Widget _buildStrokeButton(
    BuildContext context, {
    required double strokeWidth,
    required ScribbleState state,
  }) {
    final selected = state.selectedWidth == strokeWidth;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Colors.white,
        elevation: selected ? 4 : 0,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () => notifier.setStrokeWidth(strokeWidth),
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: kThemeAnimationDuration,
            width: strokeWidth * 2,
            height: strokeWidth * 2,
            decoration: BoxDecoration(
                color: state.map(
                  drawing: (s) => Color(s.selectedColor),
                  erasing: (_) => Colors.transparent,
                ),
                border: state.map(
                  drawing: (_) => null,
                  erasing: (_) => Border.all(width: 1),
                ),
                borderRadius: BorderRadius.circular(50.0)),
          ),
        ),
      ),
    );
  }

  Widget _buildColorToolbar(BuildContext context) {
    return ValueListenableBuilder<ScribbleState>(
      valueListenable: notifier,
      builder: (context, state, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildUndoButton(context),
          const Divider(
            height: 1.0,
          ),
          _buildRedoButton(context),
          const Divider(
            height: 1.0,
          ),
          _buildClearButton(context),
          const Divider(
            height: 1.0,
          ),
          _buildPointerModeSwitcher(context,
              penMode:
                  state.allowedPointersMode == ScribblePointerMode.penOnly),
          const Divider(
            height: 1.0,
          ),
          _buildEraserButton(context, isSelected: state is Erasing),
          if (backgroundColor ==
              Colors
                  .white) // Condition pour afficher le bouton noir si fond blanc
            _buildColorButton(context, color: Colors.black, state: state),
          if (backgroundColor ==
              Colors
                  .black) // Condition pour afficher le bouton blanc si fond noir
            _buildColorButton(context, color: Colors.white, state: state),
          _buildColorButton(context, color: Colors.red, state: state),
          _buildColorButton(context, color: Colors.green, state: state),
          _buildColorButton(context, color: Colors.blue, state: state),
          _buildColorButton(context, color: Colors.yellow, state: state),
        ],
      ),
    );
  }

  Widget _buildPointerModeSwitcher(BuildContext context,
      {required bool penMode}) {
    return FloatingActionButton.small(
      onPressed: () => notifier.setAllowedPointersMode(
        penMode ? ScribblePointerMode.all : ScribblePointerMode.penOnly,
      ),
      tooltip:
          "Switch drawing mode to ${penMode ? "all pointers" : "pen only"}",
      child: AnimatedSwitcher(
        duration: kThemeAnimationDuration,
        child: !penMode
            ? const Icon(
                Icons.touch_app,
                key: ValueKey(true),
              )
            : const Icon(
                Icons.do_not_touch,
                key: ValueKey(false),
              ),
      ),
    );
  }

  Widget _buildEraserButton(BuildContext context, {required bool isSelected}) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: FloatingActionButton.small(
        tooltip: "Erase",
        backgroundColor: const Color(0xFFF7FBFF),
        elevation: isSelected ? 10 : 2,
        shape: !isSelected
            ? const CircleBorder()
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
        onPressed: notifier.setEraser,
        child: const Icon(
          Icons.clear,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildColorButton(
    BuildContext context, {
    required Color color,
    required ScribbleState state,
  }) {
    final isSelected = state is Drawing && state.selectedColor == color.value;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: FloatingActionButton.small(
          backgroundColor: color,
          elevation: isSelected ? 10 : 2,
          shape: !isSelected
              ? const CircleBorder()
              : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
          child: Container(),
          onPressed: () => notifier.setColor(color)),
    );
  }

  Widget _buildUndoButton(
    BuildContext context,
  ) {
    return FloatingActionButton.small(
      tooltip: "Undo",
      onPressed: notifier.canUndo ? notifier.undo : null,
      disabledElevation: 0,
      backgroundColor: notifier.canUndo ? Colors.blueGrey : Colors.grey,
      child: const Icon(
        Icons.undo_rounded,
        color: Colors.white,
      ),
    );
  }

  Widget _buildRedoButton(
    BuildContext context,
  ) {
    return FloatingActionButton.small(
      tooltip: "Redo",
      onPressed: notifier.canRedo ? notifier.redo : null,
      disabledElevation: 0,
      backgroundColor: notifier.canRedo ? Colors.blueGrey : Colors.grey,
      child: const Icon(
        Icons.redo_rounded,
        color: Colors.white,
      ),
    );
  }

  Widget _buildClearButton(BuildContext context) {
    return FloatingActionButton.small(
      tooltip: "Clear",
      onPressed: notifier.clear,
      disabledElevation: 0,
      backgroundColor: Colors.blueGrey,
      child: const Icon(Icons.delete),
    );
  }
}
