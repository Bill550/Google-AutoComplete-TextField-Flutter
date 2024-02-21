library google_places_flutter;

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_places_flutter/constants/app_constants.dart';
import 'package:google_places_flutter/model/place_details.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:dio/dio.dart';
import 'package:rxdart/rxdart.dart';
import 'DioErrorHandler.dart';

class GooglePlaceAutoCompleteTextField extends StatefulWidget {
  InputDecoration inputDecoration;
  ItemClick? itemClick;
  GetPlaceDetailswWithLatLng? getPlaceDetailWithLatLng;
  bool isLatLngRequired = true;

  TextStyle textStyle;
  String googleAPIKey;
  int debounceTime = 600;
  List<String>? countries = [];
  TextEditingController textEditingController = TextEditingController();
  ListItemBuilder? itemBuilder;
  Widget? seperatedBuilder;
  void clearData;
  BoxDecoration? boxDecoration;
  bool isCrossBtnShown;
  bool showError;
  double? containerHorizontalPadding;
  double? containerVerticalPadding;

  // My Chnages
  ////////////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////////////
  final void Function(String)? onSubmit;
  String? Function(String?)? validator;
  bool? autofocus = true, enabled = true;

  ////////////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////////////

  GooglePlaceAutoCompleteTextField({
    required this.textEditingController,
    required this.googleAPIKey,
    this.debounceTime = 600,
    this.inputDecoration = const InputDecoration(),
    this.itemClick,
    this.isLatLngRequired = true,
    this.textStyle = const TextStyle(),
    this.countries,
    this.getPlaceDetailWithLatLng,
    this.itemBuilder,
    this.boxDecoration,
    this.isCrossBtnShown = true,
    this.seperatedBuilder,
    this.showError = true,
    this.containerHorizontalPadding,
    this.containerVerticalPadding,
    this.onSubmit,
    this.validator,
    this.autofocus,
    this.enabled,
  });

  @override
  _GooglePlaceAutoCompleteTextFieldState createState() => _GooglePlaceAutoCompleteTextFieldState();
}

class _GooglePlaceAutoCompleteTextFieldState extends State<GooglePlaceAutoCompleteTextField> {
  final subject = new PublishSubject<String>();
  OverlayEntry? _overlayEntry;
  List<Prediction> alPredictions = [];
  // My Chnages
  ////////////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////////////
  List<Prediction> finalPredictions = [];
  FocusNode searchFocusNode = FocusNode();
  bool isSelected = false;
  ////////////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////////////

  TextEditingController controller = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  bool isSearched = false;
  bool isCrossBtn = true;
  late var _dio;

  CancelToken? _cancelToken = CancelToken();

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.containerHorizontalPadding ?? 0,
          vertical: widget.containerVerticalPadding ?? 0,
        ),
        alignment: Alignment.centerLeft,
        decoration: widget.boxDecoration ??
            BoxDecoration(
              shape: BoxShape.rectangle,
              border: Border.all(
                color: Colors.grey,
                width: 0.6,
              ),
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextFormField(
                // My Chnages
                ////////////////////////////////////////////////////////////////////////////////////////
                ////////////////////////////////////////////////////////////////////////////////////////
                ////////////////////////////////////////////////////////////////////////////////////////
                enabled: widget.enabled,
                textCapitalization: TextCapitalization.words,
                focusNode: searchFocusNode,
                autofocus: widget.autofocus == null ? true : widget.autofocus!,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
                validator: widget.validator,
                onFieldSubmitted: (value) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  String newValue = "";
                  log("onSaved(newValue) 2: ");
                  log("onSaved(newValue) 2: $isSelected");
                  setState(() {
                    newValue = value;
                    isSelected = true;
                  });
                  log("onSaved(newValue) 2: ");
                  log("onSaved(newValue) 2: $isSelected");
                  clearData();
                  Future.delayed(Duration(seconds: 1)).then((value) {
                    widget.onSubmit!(newValue);
                    log("onSaved(newValue) 2: ");
                    log("onSaved(newValue) 2: $isSelected");
                  });
                },
                onSaved: (newValue) {
                  log("onSaved(newValue) 1: $newValue");
                },
                onEditingComplete: () {
                  log("onSaved(newValue) 7: ");
                  log("onSaved(newValue) 7: $isSelected");
                  setState(() {
                    isSelected = true;
                  });
                  log("onSaved(newValue) 7: ");
                  log("onSaved(newValue) 7: $isSelected");
                },
                ////////////////////////////////////////////////////////////////////////////////////////
                ////////////////////////////////////////////////////////////////////////////////////////
                ////////////////////////////////////////////////////////////////////////////////////////
                decoration: widget.inputDecoration,
                style: widget.textStyle,
                controller: widget.textEditingController,
                onChanged: (string) {
                  subject.add(string);
                  if (widget.isCrossBtnShown) {
                    isCrossBtn = string.isNotEmpty ? true : false;
                    setState(() {});
                  }
                },
              ),
            ),
            (!widget.isCrossBtnShown)
                ? SizedBox()
                : isCrossBtn && _showCrossIconWidget()
                    ? IconButton(
                        onPressed: clearData,
                        icon: Icon(
                          Icons.close,
                          color: Color(0xff96B5C3),
                        ),
                      )
                    : SizedBox()
          ],
        ),
      ),
    );
  }

  getLocation(String text) async {
    // My Chnages
    ////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////
    String url = "";
    if (text.length < 2) {
      url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$text&types=%28cities%29&key=${widget.googleAPIKey}";
    } else {
      url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$text, TX, USA&key=${widget.googleAPIKey}";
    }
    log("url: $url");
    ////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////

    if (widget.countries != null) {
      // in
      for (int i = 0; i < widget.countries!.length; i++) {
        String country = widget.countries![i];
        if (i == 0) {
          url = url + "&components=country:$country";
        } else {
          url = url + "|" + "country:" + country;
        }
      }
    }

    if (_cancelToken?.isCancelled == false) {
      _cancelToken?.cancel();
      _cancelToken = CancelToken();
    }

    try {
      Response response = await _dio.get(url);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      Map map = response.data;
      if (map.containsKey("error_message")) {
        throw response.data;
      }

      PlacesAutocompleteResponse subscriptionResponse = PlacesAutocompleteResponse.fromJson(response.data);

      if (text.length == 0) {
        if (_overlayEntry != null) {
          alPredictions.clear();
          finalPredictions.clear();
          this._overlayEntry!.remove();
        }
        return;
      }

      isSearched = false;
      alPredictions.clear();
      if (subscriptionResponse.predictions!.length > 0 && (widget.textEditingController.text.toString().trim()).isNotEmpty) {
        // alPredictions.addAll(subscriptionResponse.predictions!);
        log("message: 1");
        alPredictions.clear();
        finalPredictions.clear();

        List<String> filteredNameList =
            AppConstants().appCitiesList.where((item) => item.toLowerCase().startsWith(text.toLowerCase())).toList();
        List<String> filteredZipCodeList = AppConstants().appZipCodeList.where((item) => item.startsWith(text)).toList();

        log("filteredNameList: ${filteredNameList.length}");

        // final zipCodePattern = RegExp(r'^\d{5}(?:-\d{4})?$');
        final numbersOnlyPattern = RegExp(r'^[0-9]+$');

        if (numbersOnlyPattern.hasMatch(text)) {
          for (var i = 0; i < filteredZipCodeList.length; i++) {
            alPredictions.add(
              Prediction(
                description: filteredZipCodeList[i],
                id: "",
                lat: "",
                lng: "",
                matchedSubstrings: [],
                placeId: "",
                reference: "",
                structuredFormatting: StructuredFormatting(
                  mainText: "",
                  secondaryText: "",
                ),
                terms: [],
                types: [],
              ),
            );
          }
        } else {
          log("message: 2");

          for (var i = 0; i < filteredNameList.length; i++) {
            alPredictions.add(
              Prediction(
                description: filteredNameList[i],
                id: "",
                lat: "",
                lng: "",
                matchedSubstrings: [],
                placeId: "",
                reference: "",
                structuredFormatting: StructuredFormatting(
                  mainText: "",
                  secondaryText: "",
                ),
                terms: [],
                types: [],
              ),
            );
          }
        }

        for (var i = 0; i < subscriptionResponse.predictions!.length; i++) {
          if (subscriptionResponse.predictions![i].description!.contains("TX") == true) {
            log("message: 3");

            for (var a = 0; a < alPredictions.length; a++) {
              log("message: 4");

              log("subscriptionResponse.predictions![i].description!: ${alPredictions[a].description!.contains(subscriptionResponse.predictions![i].description!)}");
              if (alPredictions[a].description!.contains(subscriptionResponse.predictions![i].description!) == false) {
                alPredictions.add(subscriptionResponse.predictions![i]);
              }
            }
          }
        }
      } else {
        alPredictions.clear();
        finalPredictions.clear();
        final numbersOnlyPattern = RegExp(r'^[0-9]+$');

        if (numbersOnlyPattern.hasMatch(text)) {
          for (var i = 0; i < AppConstants().appZipCodeList.length; i++) {
            alPredictions.add(
              Prediction(
                description: AppConstants().appZipCodeList[i],
                id: "",
                lat: "",
                lng: "",
                matchedSubstrings: [],
                placeId: "",
                reference: "",
                structuredFormatting: StructuredFormatting(
                  mainText: "",
                  secondaryText: "",
                ),
                terms: [],
                types: [],
              ),
            );
          }
        }
      }

      finalPredictions = alPredictions.toSet().toList();

      log("finalPredictions: $finalPredictions");

      this._overlayEntry = null;
      this._overlayEntry = this._createOverlayEntry();
      if (mounted) {
        Overlay.of(context).insert(this._overlayEntry!);
      }
    } catch (e) {
      var errorHandler = ErrorHandler.internal().handleError(e);
      _showSnackBar("${errorHandler.message}");
    }
  }

  @override
  void initState() {
    super.initState();
    _dio = Dio();
    subject.stream.distinct().debounceTime(Duration(milliseconds: widget.debounceTime)).listen(textChanged);
  }

  textChanged(String text) async {
    getLocation(text);
  }

  OverlayEntry? _createOverlayEntry() {
    if (mounted) {
      if (context.findRenderObject() != null) {
        RenderBox renderBox = context.findRenderObject() as RenderBox;
        var size = renderBox.size;
        var offset = renderBox.localToGlobal(Offset.zero);
        return OverlayEntry(
          builder: (context) => isSelected
              ? const SizedBox()
              : Positioned(
                  left: offset.dx,
                  top: size.height + offset.dy,
                  width: size.width,
                  child: CompositedTransformFollower(
                    showWhenUnlinked: false,
                    link: this._layerLink,
                    offset: Offset(0.0, size.height + 5.0),
                    child: Material(
                      elevation: 0.0,
                      borderRadius: BorderRadius.circular(8.0),
                      color: Color(0xffFFFFFF),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.24,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: finalPredictions.length,
                          itemBuilder: (BuildContext context, int index) {
                            return InkWell(
                              onTap: () {
                                var selectedData = finalPredictions[index];
                                if (index < finalPredictions.length) {
                                  widget.itemClick!(selectedData);
                                  setState(() {
                                    isSelected = true;
                                  });
                                  if (!widget.isLatLngRequired) return;
                                  removeOverlay();
                                }
                              },
                              child: widget.itemBuilder != null
                                  ? widget.itemBuilder!(context, index, finalPredictions[index])
                                  : Container(
                                      padding: EdgeInsets.all(10),
                                      child: Text(
                                        finalPredictions[index].description!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
        );
      }
    }
    return null;
  }

  removeOverlay() {
    alPredictions.clear();
    finalPredictions.clear();

    this._overlayEntry = this._createOverlayEntry();
    // if (_overlayEntry != null) {
    //   if (mounted) {
    Overlay.of(context).insert(this._overlayEntry!);
    // }
    this._overlayEntry!.markNeedsBuild();
    // }
  }

  void clearData() {
    widget.textEditingController.clear();
    if (_cancelToken?.isCancelled == false) {
      _cancelToken?.cancel();
    }

    setState(() {
      alPredictions.clear();
      finalPredictions.clear();
      isCrossBtn = false;
    });

    if (this._overlayEntry != null) {
      try {
        this._overlayEntry?.remove();
      } catch (e) {}
    }
  }

  _showCrossIconWidget() {
    return (widget.textEditingController.text.isNotEmpty);
  }

  _showSnackBar(String errorData) {
    if (widget.showError) {
      final snackBar = SnackBar(
        content: Text("$errorData"),
      );

      // Find the ScaffoldMessenger in the widget tree
      // and use it to show a SnackBar.
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
}

PlacesAutocompleteResponse parseResponse(Map responseBody) {
  return PlacesAutocompleteResponse.fromJson(responseBody as Map<String, dynamic>);
}

PlaceDetails parsePlaceDetailMap(Map responseBody) {
  return PlaceDetails.fromJson(responseBody as Map<String, dynamic>);
}

typedef ItemClick = void Function(Prediction postalCodeResponse);
typedef GetPlaceDetailswWithLatLng = void Function(Prediction postalCodeResponse);

typedef ListItemBuilder = Widget Function(BuildContext context, int index, Prediction prediction);
