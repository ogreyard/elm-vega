# elm-vega

<img src="https://raw.githubusercontent.com/gicentre/elm-vega/master/images/banner.jpg" alt="elm-vega" width="600" />

_Declarative visualization for Elm_

This library allows you to create Vega-Lite specifications in Elm providing a pure functional interface to declarative visualization construction.

The library does not generate graphical output directly, but instead it allows you to create a JSON _specification_ that can be sent to the Vega-Lite runtime to create the output.
This is therefore a 'pure' Elm package without any external non-Elm dependencies.

## Example

A simple scatterplot encoding engine power and efficiency as x- and y-position and country of origin with colour:

```elm
let
    cars =
        dataFromUrl "https://vega.github.io/vega-lite/data/cars.json" []

    enc =
        encoding
            << position X [ pName "Horsepower", pMType Quantitative ]
            << position Y [ pName "Miles_per_Gallon", pMType Quantitative ]
            << color [ mName "Origin", mTType Nominal ]
in
toVegaLite [ cars, circle [], enc [] ]
```

This generates a JSON specification that when sent to the Vega-Lite runtime produces the following output:

![alt text](https://raw.githubusercontent.com/gicentre/elm-vega/master/images/simpleScatterplot.png "Simple scatterplot")

The specification generated by elm-vega for this example looks like this:

```javascript
{
  "$schema": "https://vega.github.io/schema/vega-lite/v2.json",
  "data": {
    "url": "https://vega.github.io/vega-lite/data/cars.json",
    "format": {
      "type": "json"
    }
  },
  "mark": "circle",
  "encoding": {
    "x": {
      "field": "Horsepower",
      "type": "quantitative"
    },
    "y": {
      "field": "Miles_per_Gallon",
      "type": "quantitative"
    },
    "color": {
      "field": "Origin",
      "type": "nominal"
    }
  }
}
```

## Why elm-vega?

### A rationale for Elm programmers

There is a [demand for good visualization packages](https://github.com/elm-lang/projects#data-visualization) with Elm.
And there are certainly plenty of data visualization packages available, ranging from low level [SVG rendering](http://package.elm-lang.org/packages/elm-lang/svg/latest) through a host of charting packages (e.g. [Charty](http://package.elm-lang.org/packages/juanedi/charty/latest) and [elm-charts](http://package.elm-lang.org/packages/simonh1000/elm-charts/latest)) to elegant, [opinionated chart construction](http://package.elm-lang.org/packages/terezka/elm-plot/latest) and more [comprehensive visualization libraries](http://package.elm-lang.org/packages/gampleman/elm-visualization/latest).
The designs of each reflects a trade-off between concise expression, generalisability and comprehensive functionality.

Despite the numbers of libraries, there is a space for a higher level data visualization package (avoiding, for example the need for explicit construction of chart axes) but one that offers the flexibility to create a wide range data visualization types and styles.
In particular no existing libraries offer easily constructed interaction and view composition (building 'dashboards' comprising many chart types).
elm-vega is designed to fill that gap.

**Characteristics of elm-vega**

*   Built upon the widely used [Vega](https://vega.github.io/vega/) and [Vega-Lite](https://vega.github.io/vega-lite/) specifications that have an academic robustness and momentum behind its development (Vega-Lite is itself built upon the hugely influential [Grammar of Graphics](http://www.springer.com/gb/book/9780387245447)).

*   High-level declarative specification (a chart can be fully specified in as few as five lines of code)

*   Extensive use of _union types_ means "the compiler is your friend" when building and debugging complex visualizations.

*   Flexible interaction for selecting, filtering and zooming built-in to the specification.

*   Hierarchical view composition allows complex visualization dashboards to be built from trees of simpler views.

### A rationale for data visualisers

[Vega-Lite](https://vega.github.io/vega-lite/) hits the sweet spot of abstraction between lower-level specifications such as [D3](https://d3js.org) and higher level visualization software such as [Tableau](https://www.tableau.com).
By using JSON to fully encode a visualization specification Vega and Vega-Lite are portable across a range of platforms and sits well in the JavaScript / Web ecosystem.
Yet JSON is really an interchange format rather than one suited directly for visualization design and construction.

By wrapping Vega and Vega-Lite within the Elm language, we can avoid working with JSON directly and instead take advantage of a typed functional programming environment for improved error support and customisation.
This greatly improves reusability of code (for example, it is easy to create custom chart types such as box-and-whisker plots that can be used with a range of datasets) and integration with larger programming projects.

Elm and elm-vega provide an ideal environment for educators wishing to teach Data Visualization combining the beginner-friendly design of Elm with the robust and theoretically underpinned design of a grammar of graphics.

## Limitations

*   elm-vega does not render graphics directly, but instead generates data visualization specifications that may be passed to JavaScript for rendering.

*   elm-vega is currently limited to the Vega-Lite specification (and a small amount of the Vega specification) so is focussed on Cartesian coordinate systems (e.g. no pie charts or rose diagrams).
    However, full Vega integration is currently under development and will be released shortly.

*   While limited animation is possible through interaction and dynamic data generation, there is no direct support for animated transitions (unlike D3 for example).

## Further Reading

*   To get started with your first Elm-Vega program, see [Creating your first Elm-Vega visualization](https://github.com/gicentre/elm-vega/tree/master/docs/helloWorld/README.md).
*   For a more thorough set of examples/tutorial, see the [elm-vega walkthrough](https://github.com/gicentre/elm-vega/tree/master/docs/walkthrough/README.md).
*   For the elm-vega API documentation see <http://package.elm-lang.org/packages/gicentre/elm-vega/latest>
*   Further examples can be found in the [elm-vega vlExamples folder](https://github.com/gicentre/elm-vega/tree/master/vlExamples)
