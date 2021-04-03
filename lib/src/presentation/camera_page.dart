import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:camera_camera/src/core/camera_bloc.dart';
import 'package:camera_camera/src/core/camera_service.dart';
import 'package:camera_camera/src/core/camera_status.dart';
import 'package:camera_camera/src/presentation/widgets/camera_preview.dart';
import 'package:camera_camera/src/shared/entities/camera_side.dart';
import 'package:flutter/material.dart';

import 'controller/camera_camera_controller.dart';

class CameraCamera extends StatefulWidget {
  ///Define your prefer resolution
  final ResolutionPreset resolutionPreset;

  ///CallBack function returns File your photo taken
  final void Function(File file) onFile;

  ///Define types of camera side is enabled
  final CameraSide cameraSide;

  ///Define your FlashMode accepteds
  final List<FlashMode> flashModes;

  ///Enable zoom camera ( default = true )
  final bool enableZoom;

  final Widget? back;

  final Widget? flash;

  final Function(CameraCameraController controller, CameraBloc bloc) onCreated;

  CameraCamera({
    Key? key,
    this.resolutionPreset = ResolutionPreset.ultraHigh,
    required this.onFile,
    this.cameraSide = CameraSide.all,
    this.flashModes = FlashMode.values,
    this.enableZoom = true,
    this.back,
    this.flash,
    required this.onCreated,
  }) : super(key: key);

  @override
  _CameraCameraState createState() => _CameraCameraState();
}

class _CameraCameraState extends State<CameraCamera> {
  late CameraBloc bloc;
  late StreamSubscription _subscription;

  @override
  void initState() {
    bloc = CameraBloc(
      flashModes: widget.flashModes,
      service: CameraServiceImpl(),
      onPath: (path) => widget.onFile(File(path)),
      cameraSide: widget.cameraSide,
    );
    bloc.init();
    _subscription = bloc.statusStream.listen((state) {
      return state.when(
          orElse: () {},
          selected: (camera) async {
            bloc.startPreview(widget.resolutionPreset);
          });
    });
    super.initState();
  }

  @override
  void dispose() {
    bloc.dispose();
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: StreamBuilder<CameraStatus>(
        stream: bloc.statusStream,
        initialData: CameraStatusEmpty(),
        builder: (_, snapshot) => snapshot.data!.when(
            preview: (controller) {
              widget.onCreated.call(controller, bloc);
              return SafeArea(
                child: Stack(
                  children: [
                    CameraCameraPreview(
                      enableZoom: widget.enableZoom,
                      key: UniqueKey(),
                      controller: controller,
                    ),
                    if (widget.back != null)
                      Positioned(
                        top: 8.0,
                        left: 15.0,
                        child: widget.back!,
                      ),
                    if (widget.flash != null)
                      Positioned(
                        top: 8.0,
                        right: 15.0,
                        child: widget.flash!,
                      ),
                  ],
                ),
              );
            },
            failure: (message, _) => Container(
                  color: Colors.black,
                  child: Text(message),
                ),
            orElse: () => Container(
                  color: Colors.black,
                )),
      ),
    );
  }
}
