# customization_svg

A Flutter plugin to show svgs created by three_dart. This also allows for color changing of the image.

## Getting started

To get started with customization_svg add the package to your pubspec.yaml file.

### Generate an SVG from network
Generate an svg mesh form a network url pointing to the svg. Give the size of the space the svg will be in and the list of colors you want the svg to be leave null to use the colors in the svg.
```dart
SizedBox(
  width: 240,
  child: SVGImage.fromNetwork(
    Size(240,120), 
    'svg_url', 
    [Colors.white,Colors.black]
  )
),
```

### Generate an SVG from string
Generate an svg mesh from a string created locally using three_dart or from a path svg. Give the size of the space the svg will be in and the list of colors you want the svg to be leave null to use the colors in the svg.
```dart
SizedBox(
  width: 240,
  child: SVGImage.fromString(
    Size(240,120), 
    'String from path or created by three_dart'
  )
),
```

### Generate an SVG from mesh
Generate an svg mesh from a string or url them place into a List, local or global variable to change the colors later.
```dart
SizedBox(
  width: 240,
  child: SVGImage.fromString(
    mesh,
    Size(240,120)
  )
),
```

## Contributing

Feel free to propose changes by creating a pull request.
