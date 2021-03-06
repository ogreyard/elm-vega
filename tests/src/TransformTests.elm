port module TransformTests exposing (elmToJS)

import Browser
import Html exposing (Html, div, pre)
import Html.Attributes exposing (id)
import Json.Encode
import Vega exposing (..)


packTest1 : Spec
packTest1 =
    let
        table =
            dataFromColumns "tree" []
                << dataColumn "id" (vStrs [ "A", "B", "C", "D", "E" ])
                << dataColumn "parent" (vStrs [ "", "A", "A", "C", "C" ])
                << dataColumn "value" (vNums [ 0, 1, 0, 1, 1 ])

        ds =
            dataSource
                [ table []
                    |> transform
                        [ trStratify (field "id") (field "parent")
                        , trPack
                            [ paField (field "value")
                            , paPadding (numSignal "padding between circles")
                            , paSize (numSignals [ "width", "height" ])
                            ]
                        ]
                ]

        si =
            signals
                << signal "padding between circles"
                    [ siValue (vNum 0)
                    , siBind (iRange [ inMin 0, inMax 10, inStep 0.1 ])
                    ]

        sc =
            scales
                << scale "cScale"
                    [ scType scOrdinal
                    , scRange (raScheme (str "category20") [])
                    ]

        mk =
            marks
                << mark symbol
                    [ mFrom [ srData (str "tree") ]
                    , mEncode
                        [ enEnter
                            [ maFill [ vScale "cScale", vField (field "id") ]
                            , maStroke [ white ]
                            ]
                        , enUpdate
                            [ maX [ vField (field "x") ]
                            , maY [ vField (field "y") ]
                            , maSize [ vSignal "4*datum.r*datum.r" ]
                            ]
                        ]
                    ]
    in
    toVega
        [ width 300, height 200, padding 5, ds, si [], sc [], mk [] ]


stackTest1 : Spec
stackTest1 =
    let
        table =
            dataFromColumns "table" []
                << dataColumn "key" (vStrs [ "a", "a", "a", "b", "b", "b", "c", "c", "c" ])
                << dataColumn "value" (vNums [ 5, 8, 3, 2, 7, 4, 1, 4, 6 ])

        ds =
            dataSource
                [ table []
                    |> transform
                        [ trStack
                            [ stField (field "value")
                            , stGroupBy [ field "key" ]
                            , stOffset (stSignal "offset")
                            , stSort [ ( fSignal "sortField", orderSignal "sortOrder" ) ]
                            ]
                        ]
                    |> on
                        [ trigger "add" [ tgInsert "add" ]
                        , trigger "rem" [ tgRemove "rem" ]
                        ]
                ]

        si =
            signals
                << signal "offset"
                    [ siValue (vStr "zero")
                    , siBind (iSelect [ inOptions (vStrs [ "zero", "center", "normalize" ]) ])
                    ]
                << signal "sortField"
                    [ siValue vNull
                    , siBind (iRadio [ inOptions (vStrs [ "null", "value" ]) ])
                    ]
                << signal "sortOrder"
                    [ siValue (vStr "ascending")
                    , siBind (iRadio [ inOptions (vStrs [ "ascending", "descending" ]) ])
                    ]
                << signal "add"
                    [ siValue (vObject [])
                    , siOn
                        [ evHandler
                            [ esObject
                                [ esType etMouseDown
                                , esConsume true
                                , esFilter [ "!event.shiftKey" ]
                                ]
                            ]
                            [ evUpdate "{key: invert('xScale', x()), value: ~~(1 + 9 * random())}" ]
                        ]
                    ]
                << signal "rem"
                    [ siValue (vObject [])
                    , siOn
                        [ evHandler
                            [ esObject
                                [ esMark rect
                                , esType etMouseDown
                                , esConsume true
                                , esFilter [ "event.shiftKey" ]
                                ]
                            ]
                            [ evUpdate "datum" ]
                        ]
                    ]

        sc =
            scales
                << scale "xScale"
                    [ scType scBand
                    , scDomain (doStrs (strs [ "a", "b", "c" ]))
                    , scRange raWidth
                    ]
                << scale "yScale"
                    [ scType scLinear
                    , scDomain (doData [ daDataset "table", daField (field "y1") ])
                    , scRange raHeight
                    , scRound true
                    ]
                << scale "cScale"
                    [ scType scOrdinal
                    , scRange (raScheme (str "category10") [])
                    ]

        mk =
            marks
                << mark rect
                    [ mFrom [ srData (str "table") ]
                    , mEncode
                        [ enEnter
                            [ maFill [ vScale "cScale", vField (field "key") ]
                            , maStroke [ white ]
                            , maStrokeWidth [ vNum 1 ]
                            , maX [ vScale "xScale", vField (field "key"), vOffset (vNum 0.5) ]
                            , maWidth [ vScale "xScale", vBand (num 1) ]
                            ]
                        , enUpdate
                            [ maY [ vScale "yScale", vField (field "y0"), vOffset (vNum 0.5) ]
                            , maY2 [ vScale "yScale", vField (field "y1"), vOffset (vNum 0.5) ]
                            ]
                        ]
                    ]
    in
    toVega
        [ width 300, height 200, autosize [ asNone ], ds, si [], sc [], mk [] ]


forceTest1 : Spec
forceTest1 =
    let
        ds =
            dataSource
                [ data "node-data"
                    [ daUrl (str "https://vega.github.io/vega/data/miserables.json")
                    , daFormat [ jsonProperty (str "nodes") ]
                    ]
                , data "link-data"
                    [ daUrl (str "https://vega.github.io/vega/data/miserables.json")
                    , daFormat [ jsonProperty (str "links") ]
                    ]
                ]

        si =
            signals
                << signal "cx" [ siUpdate "width /2" ]
                << signal "cy" [ siUpdate "height /2" ]
                << signal "collideRadius"
                    [ siValue (vNum 5)
                    , siBind (iRange [ inMin 3, inMax 20, inStep 1 ])
                    ]
                << signal "nbodyStrength"
                    [ siValue (vNum -10)
                    , siBind (iRange [ inMin -50, inMax 10, inStep 1 ])
                    ]
                << signal "linkDistance"
                    [ siValue (vNum 15)
                    , siBind (iRange [ inMin 5, inMax 100, inStep 1 ])
                    ]
                << signal "velocityDecay"
                    [ siValue (vNum 0.4)
                    , siBind (iRange [ inMin 0, inMax 1, inStep 0.01 ])
                    ]
                << signal "static"
                    [ siValue vTrue
                    , siBind (iCheckbox [])
                    ]
                << signal "fix"
                    [ siDescription "State variable for active node fix status."
                    , siValue (vNum 0)
                    , siOn
                        [ evHandler
                            [ esMerge
                                [ esObject [ esMark symbol, esType etMouseOut, esFilter [ "!event.buttons" ] ]
                                , esObject [ esSource esWindow, esType etMouseUp ]
                                ]
                            ]
                            [ evUpdate "0" ]
                        , evHandler [ esObject [ esMark symbol, esType etMouseOver ] ] [ evUpdate "fix || 1" ]
                        , evHandler
                            [ esObject
                                [ esBetween [ esMark symbol, esType etMouseDown ] [ esSource esWindow, esType etMouseUp ]
                                , esSource esWindow
                                , esType etMouseMove
                                , esConsume true
                                ]
                            ]
                            [ evUpdate "2", evForce true ]
                        ]
                    ]
                << signal "node"
                    [ siDescription "Graph node most recently interacted with."
                    , siValue vNull
                    , siOn [ evHandler [ esObject [ esMark symbol, esType etMouseOver ] ] [ evUpdate "fix === 1 ? item() : node" ] ]
                    ]
                << signal "restart"
                    [ siDescription "Flag to restart Force simulation upon data changes."
                    , siValue vFalse
                    , siOn [ evHandler [ esSelector (strSignal "fix") ] [ evUpdate "fix > 1 " ] ]
                    ]

        sc =
            scales << scale "cScale" [ scType scOrdinal, scRange (raScheme (str "category20c") []) ]

        mk =
            marks
                << mark symbol
                    [ mName "nodes"
                    , mFrom [ srData (str "node-data") ]
                    , mZIndex (num 1)
                    , mOn
                        [ trigger "fix" [ tgModifyValues "node" "fix === 1 ? {fx:node.x, fy:node.y} : {fx:x(), fy:y()}" ]
                        , trigger "!fix" [ tgModifyValues "node" "{fx: null, fy: null}" ]
                        ]
                    , mEncode
                        [ enEnter
                            [ maFill [ vScale "cScale", vField (field "group") ]
                            , maStroke [ white ]
                            ]
                        , enUpdate
                            [ maSize [ vSignal "2 * collideRadius * collideRadius" ]
                            , maCursor [ cursorValue cuPointer ]
                            ]
                        ]
                    , mTransform
                        [ trForce
                            [ fsIterations (num 300)
                            , fsVelocityDecay (numSignal "velocityDecay")
                            , fsRestart (booSignal "restart")
                            , fsStatic (booSignal "static")
                            , fsForces
                                [ foCenter (numSignal "cx") (numSignal "cy")
                                , foCollide (numSignal "collideRadius") []
                                , foNBody [ fpStrength (numSignal "nbodyStrength") ]
                                , foLink (str "link-data") [ fpDistance (numSignal "linkDistance") ]
                                ]
                            ]
                        ]
                    ]
                << mark path
                    [ mFrom [ srData (str "link-data") ]
                    , mInteractive false
                    , mEncode
                        [ enUpdate
                            [ maStroke [ vStr "#ccc" ]
                            , maStrokeWidth [ vNum 0.5 ]
                            ]
                        ]
                    , mTransform
                        [ trLinkPath
                            [ lpShape lsDiagonal
                            , lpSourceX (field "datum.source.x")
                            , lpSourceY (field "datum.source.y")
                            , lpTargetX (field "datum.target.x")
                            , lpTargetY (field "datum.target.y")
                            ]
                        ]
                    ]
    in
    toVega
        [ width 400, height 275, autosize [ asNone ], ds, si [], sc [], mk [] ]


nestTest1 : Spec
nestTest1 =
    let
        table =
            dataFromColumns "tree" []
                << dataColumn "id" (vStrs [ "A", "B", "C", "D", "E", "F", "G", "H" ])
                << dataColumn "job" (vStrs [ "Doctor", "Doctor", "Lawyer", "Lawyer", "Doctor", "Doctor", "Lawyer", "Lawyer" ])
                << dataColumn "region" (vStrs [ "East", "East", "East", "East", "West", "West", "West", "West" ])

        ds =
            dataSource
                [ table []
                    |> transform
                        [ trNest [ field "job", field "region" ] (booSignal "generate")
                        , trTree [ teMethod meTidy, teSize (numSignals [ "width", "height" ]) ]
                        ]
                , data "links" [ daSource "tree" ]
                    |> transform [ trTreeLinks, trLinkPath [] ]
                ]

        si =
            signals << signal "generate" [ siValue vTrue, siBind (iCheckbox []) ]

        sc =
            scales
                << scale "cScale"
                    [ scType scOrdinal
                    , scRange (raScheme (str "category20") [])
                    ]

        mk =
            marks
                << mark path
                    [ mFrom [ srData (str "links") ]
                    , mEncode
                        [ enUpdate
                            [ maStroke [ vStr "#ccc" ]
                            , maPath [ vField (field "path") ]
                            ]
                        ]
                    ]
                << mark symbol
                    [ mFrom [ srData (str "tree") ]
                    , mEncode
                        [ enUpdate
                            [ maFill [ vScale "cScale", vField (field "id") ]
                            , maStroke [ white ]
                            , maSize [ vNum 600 ]
                            , maX [ vField (field "x") ]
                            , maY [ vField (field "y") ]
                            ]
                        ]
                    ]
                << mark text
                    [ mFrom [ srData (str "tree") ]
                    , mEncode
                        [ enEnter
                            [ maText [ vField (field "id") ]
                            , maStroke [ white ]
                            , maFill [ white ]
                            , maAlign [ hCenter ]
                            , maBaseline [ vMiddle ]
                            , maFontWeight [ vStr "normal" ]
                            , maFontSize [ vNum 16 ]
                            ]
                        , enUpdate
                            [ maX [ vField (field "x") ]
                            , maY [ vField (field "y") ]
                            ]
                        ]
                    ]
    in
    toVega
        [ width 300, height 100, padding 5, ds, si [], sc [], mk [] ]


treeTest1 : Spec
treeTest1 =
    let
        table =
            dataFromColumns "tree" []
                << dataColumn "id" (vStrs [ "A", "B", "C", "D", "E" ])
                << dataColumn "parent" (vStrs [ "", "A", "A", "C", "C" ])

        ds =
            dataSource
                [ table []
                    |> transform
                        [ trStratify (field "id") (field "parent")
                        , trTree
                            [ teMethod (meSignal "method")
                            , teSeparation (booSignal "separation")
                            , teSize (numSignals [ "width", "height" ])
                            ]
                        ]
                , data "links" [ daSource "tree" ]
                    |> transform [ trTreeLinks, trLinkPath [] ]
                ]

        si =
            signals
                << signal "method"
                    [ siValue (vStr "tidy")
                    , siBind (iSelect [ inOptions (vStrs [ "tidy", "cluster" ]) ])
                    ]
                << signal "separation" [ siValue vTrue, siBind (iCheckbox []) ]

        sc =
            scales
                << scale "cScale"
                    [ scType scOrdinal
                    , scRange (raScheme (str "category20") [])
                    ]

        mk =
            marks
                << mark path
                    [ mFrom [ srData (str "links") ]
                    , mEncode
                        [ enEnter [ maStroke [ vStr "#ccc" ] ]
                        , enUpdate [ maPath [ vField (field "path") ] ]
                        ]
                    ]
                << mark symbol
                    [ mFrom [ srData (str "tree") ]
                    , mEncode
                        [ enEnter
                            [ maFill [ vScale "cScale", vField (field "id") ]
                            , maStroke [ white ]
                            , maSize [ vNum 400 ]
                            ]
                        , enUpdate
                            [ maX [ vField (field "x") ]
                            , maY [ vField (field "y") ]
                            ]
                        ]
                    ]
    in
    toVega
        [ width 200, height 100, padding 5, ds, si [], sc [], mk [] ]


pr : List Spec -> ( VProperty, Spec )
pr =
    projections
        << projection "projection"
            [ prType transverseMercator
            , prScale (num 3700)
            , prTranslate (nums [ 320, 3855 ])
            ]


voronoiTest1 : Spec
voronoiTest1 =
    let
        ds =
            dataSource
                [ data "hull"
                    [ daUrl (str "https://gicentre.github.io/data/uk/ukConvexHull.json")
                    , daFormat [ topojsonFeature (str "convexHull") ]
                    ]
                    |> transform [ trGeoPath "projection" [] ]
                , data "centroids"
                    [ daUrl (str "https://gicentre.github.io/data/uk/constituencyCentroids.csv")
                    , daFormat [ csv, parseAuto ]
                    ]
                    |> transform
                        [ trGeoPoint "projection" (field "longitude") (field "latitude")
                        , trVoronoi
                            (field "x")
                            (field "y")
                            [ voSize (numSignals [ "width", "height" ])
                            , voAs "voronoi"
                            ]
                        ]
                ]

        mk =
            marks
                << mark path
                    [ mFrom [ srData (str "centroids") ]
                    , mClip (clPath (strSignal "data('hull')[0]['path']"))
                    , mEncode
                        [ enEnter
                            [ maFill [ transparent ]
                            , maStroke [ black ]
                            , maStrokeWidth [ vNum 0.2 ]
                            , maPath [ vField (field "voronoi") ]
                            ]
                        ]
                    ]
                << mark path
                    [ mFrom [ srData (str "hull") ]
                    , mEncode
                        [ enEnter
                            [ maFill [ transparent ]
                            , maStroke [ black ]
                            , maStrokeWidth [ vNum 0.2 ]
                            , maPath [ vField (field "path") ]
                            ]
                        ]
                    ]
                << mark symbol
                    [ mFrom [ srData (str "centroids") ]
                    , mEncode
                        [ enEnter
                            [ maSize [ vNum 2 ]
                            , maX [ vField (field "x") ]
                            , maY [ vField (field "y") ]
                            ]
                        ]
                    ]
    in
    toVega
        [ width 420, height 670, padding 5, ds, pr [], mk [] ]


voronoiTest2 : Spec
voronoiTest2 =
    let
        ds =
            dataSource
                [ data "regions"
                    [ daUrl (str "https://gicentre.github.io/data/uk/ukConstituencies.json")
                    , daFormat [ topojsonFeature (str "constituencies") ]
                    ]
                    |> transform [ trGeoPath "projection" [] ]
                , data "hull"
                    [ daUrl (str "https://gicentre.github.io/data/uk/ukConvexHull.json")
                    , daFormat [ topojsonFeature (str "convexHull") ]
                    ]
                    |> transform [ trGeoPath "projection" [] ]
                , data "centroids"
                    [ daUrl (strSignal "centroidFile")
                    , daFormat [ csv, parseAuto ]
                    ]
                    |> transform
                        [ trGeoPoint "projection" (field "longitude") (field "latitude")
                        , trVoronoi
                            (field "x")
                            (field "y")
                            [ voSize (numSignals [ "width", "height" ])
                            , voAs "voronoi"
                            ]
                        ]
                ]

        si =
            signals
                << signal "centroidFile"
                    [ siValue (vStr "https://gicentre.github.io/data/uk/constituencyCentroidsWithSpacers.csv")
                    , siBind
                        (iSelect
                            [ inOptions
                                (vStrs
                                    [ "https://gicentre.github.io/data/uk/constituencyCentroidsWithSpacers.csv"
                                    , "https://gicentre.github.io/data/uk/constituencySpacedCentroidsWithSpacers.csv"
                                    ]
                                )
                            ]
                        )
                    ]
                << signal "showRegions" [ siValue vTrue, siBind (iCheckbox []) ]
                << signal "showVoronoi" [ siBind (iCheckbox []) ]
                << signal "colors"
                    [ siValue
                        (vStrs
                            [ "white"
                            , "rgb(225,174,218)" -- EMids
                            , "rgb(136,136,136)" -- London
                            , "rgb(161,200,136)" -- NW
                            , "rgb(181,156,149)" -- WMids
                            , "rgb(240,180,122)" -- YorkAndHumber
                            , "rgb(185,165,215)" -- SE
                            , "rgb(195,149,148)" -- NE
                            , "rgb(215,131,130)" -- Wales
                            , "rgb(167,216,227)" -- East
                            , "rgb(215,217,135)" -- SW
                            , "rgb(146,173,210)" -- Scotland
                            , "rgb(180,160,120)" -- NI
                            ]
                        )
                    ]

        sc =
            scales
                << scale "cScale"
                    [ scType scOrdinal
                    , scDomain (doNums (nums [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 ]))
                    , scRange (raSignal "colors")
                    ]

        mk =
            marks
                << mark path
                    [ mFrom [ srData (str "regions") ]
                    , mEncode
                        [ enEnter
                            [ maStroke [ vStr "#eee" ]
                            , maStrokeWidth [ vNum 0.2 ]
                            ]
                        , enUpdate
                            [ maPath [ vField (field "path") ]
                            , maFill
                                [ ifElse "!showRegions"
                                    [ vStr "#eee" ]
                                    [ ifElse "datum.region == 0" [ transparent ] [ vScale "cScale", vField (field "id") ] ]
                                ]
                            ]
                        ]
                    ]
                << mark path
                    [ mFrom [ srData (str "centroids") ]
                    , mClip (clPath (strSignal "data('hull')[0]['path']"))
                    , mEncode
                        [ enEnter
                            [ maStrokeWidth [ vNum 0.2 ]
                            , maPath [ vField (field "voronoi") ]
                            ]
                        , enUpdate
                            [ maFill
                                [ ifElse "!showVoronoi || datum.region == 0"
                                    [ transparent ]
                                    [ vScale "cScale", vField (field "region") ]
                                ]
                            , maStroke
                                [ ifElse "!showVoronoi || datum.region == 0"
                                    [ transparent ]
                                    [ vStr "white" ]
                                ]
                            ]
                        ]
                    ]
    in
    toVega
        [ width 420, height 670, padding 5, ds, si [], pr [], sc [], mk [] ]


contourTest1 : Spec
contourTest1 =
    let
        cf =
            config [ cfScaleRange raHeatmap (raScheme (str "greenblue") []) ]

        ds =
            dataSource
                [ data "source" [ daUrl (str "https://vega.github.io/vega/data/cars.json") ]
                    |> transform [ trFilter (expr "datum['Horsepower'] != null && datum['Miles_per_Gallon'] != null") ]
                , data "contours" [ daSource "source" ]
                    |> transform
                        [ trContour (numSignal "width")
                            (numSignal "height")
                            [ cnX (fExpr "scale('xScale', datum.Horsepower)")
                            , cnY (fExpr "scale('yScale', datum.Miles_per_Gallon)")
                            , cnWeight (fExpr "scale('xScale', datum.Horsepower)")
                            , cnCount (numSignal "count")
                            ]
                        ]
                ]

        si =
            signals
                << signal "count" [ siValue (vNum 10), siBind (iSelect [ inOptions (vNums [ 1, 5, 10, 20 ]) ]) ]
                << signal "points" [ siValue vTrue, siBind (iCheckbox []) ]

        sc =
            scales
                << scale "xScale"
                    [ scType scLinear
                    , scRange raWidth
                    , scDomain (doData [ daDataset "source", daField (field "Horsepower") ])
                    , scRound true
                    , scNice niTrue
                    , scZero false
                    ]
                << scale "yScale"
                    [ scType scLinear
                    , scRange raHeight
                    , scDomain (doData [ daDataset "source", daField (field "Miles_per_Gallon") ])
                    , scRound true
                    , scNice niTrue
                    , scZero false
                    ]
                << scale "cScale"
                    [ scType scSequential
                    , scDomain (doData [ daDataset "contours", daField (field "value") ])
                    , scRange raHeatmap
                    , scZero true
                    ]

        ax =
            axes
                << axis "xScale"
                    siBottom
                    [ axGrid true
                    , axDomain false
                    , axTitle (str "Horsepower")
                    ]
                << axis "yScale"
                    siLeft
                    [ axGrid true
                    , axDomain false
                    , axTitle (str "Miles per gallon")
                    ]

        le =
            legends << legend [ leFill "cScale", leType ltGradient ]

        mk =
            marks
                << mark path
                    [ mFrom [ srData (str "contours") ]
                    , mEncode
                        [ enEnter
                            [ maStroke [ vStr "#888" ]
                            , maStrokeWidth [ vNum 1 ]
                            , maFill [ vScale "cScale", vField (field "value") ]
                            , maFillOpacity [ vNum 0.35 ]
                            ]
                        ]
                    , mTransform [ trGeoPath "" [ gpField (field "datum") ] ]
                    ]
                << mark symbol
                    [ mName "marks"
                    , mFrom [ srData (str "source") ]
                    , mEncode
                        [ enUpdate
                            [ maX [ vScale "xScale", vField (field "Horsepower") ]
                            , maY [ vScale "yScale", vField (field "Miles_per_Gallon") ]
                            , maSize [ vNum 4 ]
                            , maFill [ ifElse "points" [ black ] [ transparent ] ]
                            ]
                        ]
                    ]
    in
    toVega
        [ cf, width 500, height 400, padding 5, autosize [ asPad ], ds, si [], sc [], ax [], le [], mk [] ]


sourceExample : Spec
sourceExample =
    contourTest1



{- This list comprises the specifications to be provided to the Vega runtime. -}


mySpecs : Spec
mySpecs =
    combineSpecs
        [ ( "packTest1", packTest1 )
        , ( "stackTest1", stackTest1 )
        , ( "forceTest1", forceTest1 )
        , ( "nestTest1", nestTest1 )
        , ( "treeTest1", treeTest1 )
        , ( "voronoiTest1", voronoiTest1 )
        , ( "voronoiTest2", voronoiTest2 )
        , ( "contourTest1", contourTest1 )
        ]



{- ---------------------------------------------------------------------------
   The code below creates an Elm module that opens an outgoing port to Javascript
   and sends both the specs and DOM node to it.
   This is used to display the generated Vega specs for testing purposes.
-}


main : Program () Spec msg
main =
    Browser.element
        { init = always ( mySpecs, elmToJS mySpecs )
        , view = view
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = always Sub.none
        }



-- View


view : Spec -> Html msg
view spec =
    div []
        [ div [ id "specSource" ] []
        , pre []
            [ Html.text (Json.Encode.encode 2 sourceExample) ]
        ]


port elmToJS : Spec -> Cmd msg
