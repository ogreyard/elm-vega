port module MarkTests exposing (elmToJS)

import Html exposing (Html, div, pre)
import Html.Attributes exposing (id)
import Json.Encode
import Platform
import Vega exposing (..)


{- These tests converted from the examples under 'Marks' on the offical Vega site:
   https://vega.github.io/vega/docs/marks/
-}


{-| Convenience function for generating a list of 2-element DataValues lists used
when generating dashed line arrays.
-}
toValue : List ( Float, Float ) -> Value
toValue pairs =
    pairs |> List.map (\( a, b ) -> vNums [ a, b ]) |> vValues


arcTest : Spec
arcTest =
    let
        si =
            signals
                << signal "startAngle" [ siValue (vNum -0.73), siBind (iRange [ inMin -6.28, inMax 6.28 ]) ]
                << signal "endAngle" [ siValue (vNum 0.73), siBind (iRange [ inMin -6.28, inMax 6.28 ]) ]
                << signal "padAngle" [ siValue (vNum 0), siBind (iRange [ inMin 0, inMax 1.57 ]) ]
                << signal "innerRadius" [ siValue (vNum 0), siBind (iRange [ inMin 0, inMax 100, inStep 1 ]) ]
                << signal "outerRadius" [ siValue (vNum 50), siBind (iRange [ inMin 0, inMax 100, inStep 1 ]) ]
                << signal "cornerRadius" [ siValue (vNum 0), siBind (iRange [ inMin 0, inMax 50, inStep 1 ]) ]
                << signal "strokeWidth" [ siValue (vNum 4), siBind (iRange [ inMin 0, inMax 10, inStep 0.5 ]) ]
                << signal "color" [ siValue (vStr "both"), siBind (iRadio [ inOptions (vStrs [ "fill", "stroke", "both" ]) ]) ]
                << signal "x" [ siValue (vNum 100) ]
                << signal "y" [ siValue (vNum 100) ]

        mk =
            marks
                << mark Symbol
                    [ mInteractive (boolean False)
                    , mEncode
                        [ enEnter [ maFill [ vStr "firebrick" ], maSize [ vNum 25 ] ]
                        , enUpdate [ maX [ vSignal "x" ], maY [ vSignal "y" ] ]
                        ]
                    ]
                << mark Arc
                    [ mEncode
                        [ enEnter [ maFill [ vStr "#939597" ], maStroke [ vStr "#652c90" ] ]
                        , enUpdate
                            [ maX [ vSignal "x" ]
                            , maY [ vSignal "y" ]
                            , maStartAngle [ vSignal "startAngle" ]
                            , maEndAngle [ vSignal "endAngle" ]
                            , maInnerRadius [ vSignal "innerRadius" ]
                            , maOuterRadius [ vSignal "outerRadius" ]
                            , maCornerRadius [ vSignal "cornerRadius" ]
                            , maPadAngle [ vSignal "padAngle" ]
                            , maStrokeWidth [ vSignal "strokeWidth" ]
                            , maOpacity [ vNum 1 ]
                            , maFillOpacity [ vSignal "color === 'fill' || color === 'both' ? 1 : 0" ]
                            , maStrokeOpacity [ vSignal "color === 'stroke' || color === 'both' ? 1 : 0" ]
                            ]
                        , enHover [ maOpacity [ vNum 0.5 ] ]
                        ]
                    ]
    in
    toVega
        [ width 200, height 200, padding (PSize 5), si [], mk [] ]


areaTest : Spec
areaTest =
    let
        table =
            dataFromColumns "table" []
                << dataColumn "u" (daNums [ 1, 2, 3, 4, 5, 6 ])
                << dataColumn "v" (daNums [ 28, 55, 42, 34, 36, 48 ])

        ds =
            dataSource [ table [] ]

        sc =
            scales
                << scale "xscale"
                    [ scType ScLinear
                    , scDomain (doData [ dDataset "table", dField (str "u") ])
                    , scRange (raDefault RWidth)
                    , scZero (boolean False)
                    ]
                << scale "yscale"
                    [ scType ScLinear
                    , scDomain (doData [ dDataset "table", dField (str "v") ])
                    , scRange (raDefault RHeight)
                    , scZero (boolean True)
                    , scNice niTrue
                    ]

        si =
            signals
                << signal "defined" [ siValue (vBool True), siBind (iCheckbox []) ]
                << signal "interpolate"
                    [ siValue (vStr (markInterpolationLabel Linear))
                    , siBind (iSelect [ inOptions (vStrs [ "basis", "cardinal", "catmull-rom", "linear", "monotone", "natural", "step", "step-after", "step-before" ]) ])
                    ]
                << signal "tension" [ siValue (vNum 0), siBind (iRange [ inMin 0, inMax 1, inStep 0.05 ]) ]
                << signal "y2" [ siValue (vNum 0), siBind (iRange [ inMin 0, inMax 20, inStep 1 ]) ]
                << signal "strokeWidth" [ siValue (vNum 4), siBind (iRange [ inMin 0, inMax 10, inStep 0.5 ]) ]
                << signal "color" [ siValue (vStr "both"), siBind (iRadio [ inOptions (vStrs [ "fill", "stroke", "both" ]) ]) ]

        mk =
            marks
                << mark Area
                    [ mFrom [ srData (str "table") ]
                    , mEncode
                        [ enEnter [ maFill [ vStr "#939597" ], maStroke [ vStr "#652c90" ] ]
                        , enUpdate
                            [ maX [ vScale (fName "xscale"), vField (fName "u") ]
                            , maY [ vScale (fName "yscale"), vField (fName "v") ]
                            , maY2 [ vScale (fName "yscale"), vSignal "y2" ]
                            , maDefined [ vSignal "defined || datum.u !== 3" ]
                            , maInterpolate [ vSignal "interpolate" ]
                            , maTension [ vSignal "tension" ]
                            , maOpacity [ vNum 1 ]
                            , maFillOpacity [ vSignal "color === 'fill' || color === 'both' ? 1 : 0" ]
                            , maStrokeOpacity [ vSignal "color === 'stroke' || color === 'both' ? 1 : 0" ]
                            , maStrokeWidth [ vSignal "strokeWidth" ]
                            ]
                        , enHover [ maOpacity [ vNum 0.5 ] ]
                        ]
                    ]
    in
    toVega
        [ width 400, height 200, padding (PSize 5), ds, sc [], si [], mk [] ]


groupTest : Spec
groupTest =
    let
        table =
            dataFromColumns "table" []
                << dataColumn "x" (daNums [ 5, -5, 60 ])
                << dataColumn "y" (daNums [ 5, 70, 120 ])
                << dataColumn "w" (daNums [ 100, 40, 100 ])
                << dataColumn "h" (daNums [ 30, 40, 20 ])

        ds =
            dataSource [ table [] ]

        si =
            signals
                << signal "groupClip" [ siValue (vBool False), siBind (iCheckbox []) ]
                << signal "x" [ siValue (vNum 25), siBind (iRange [ inMin 0, inMax 200, inStep 1 ]) ]
                << signal "y" [ siValue (vNum 25), siBind (iRange [ inMin 0, inMax 200, inStep 1 ]) ]
                << signal "w" [ siValue (vNum 150), siBind (iRange [ inMin 0, inMax 200, inStep 1 ]) ]
                << signal "h" [ siValue (vNum 150), siBind (iRange [ inMin 0, inMax 200, inStep 1 ]) ]
                << signal "cornerRadius" [ siValue (vNum 0), siBind (iRange [ inMin 0, inMax 50, inStep 1 ]) ]
                << signal "strokeWidth" [ siValue (vNum 4), siBind (iRange [ inMin 0, inMax 10 ]) ]
                << signal "color" [ siValue (vStr "both"), siBind (iRadio [ inOptions (vStrs [ "fill", "stroke", "both" ]) ]) ]

        mk =
            marks
                << mark Group
                    [ mEncode
                        [ enEnter [ maFill [ vStr "#939597" ], maStroke [ vStr "#652c90" ] ]
                        , enUpdate
                            [ maX [ vSignal "x" ]
                            , maY [ vSignal "y" ]
                            , maWidth [ vSignal "w" ]
                            , maHeight [ vSignal "h" ]
                            , maGroupClip [ vSignal "groupClip" ]
                            , maOpacity [ vNum 1 ]
                            , maCornerRadius [ vSignal "cornerRadius" ]
                            , maStrokeWidth [ vSignal "strokeWidth" ]
                            , maFillOpacity [ vSignal "color === 'fill' || color === 'both' ? 1 : 0" ]
                            , maStrokeOpacity [ vSignal "color === 'stroke' || color === 'both' ? 1 : 0" ]
                            ]
                        , enHover [ maOpacity [ vNum 0.5 ] ]
                        ]
                    , mGroup [ ds, nestedMk [] ]
                    ]

        nestedMk =
            marks
                << mark Rect
                    [ mFrom [ srData (str "table") ]
                    , mInteractive (boolean False)
                    , mEncode
                        [ enEnter
                            [ maX [ vField (fName "x") ]
                            , maY [ vField (fName "y") ]
                            , maWidth [ vField (fName "w") ]
                            , maHeight [ vField (fName "h") ]
                            , maFill [ vStr "aliceblue" ]
                            , maStroke [ vStr "firebrick" ]
                            ]
                        ]
                    ]
    in
    toVega
        [ width 200, height 200, padding (PSize 5), si [], mk [] ]


imageTest : Spec
imageTest =
    let
        si =
            signals
                << signal "x" [ siValue (vNum 75), siBind (iRange [ inMin 0, inMax 100, inStep 1 ]) ]
                << signal "y" [ siValue (vNum 75), siBind (iRange [ inMin 0, inMax 100, inStep 1 ]) ]
                << signal "w" [ siValue (vNum 50), siBind (iRange [ inMin 0, inMax 200, inStep 1 ]) ]
                << signal "h" [ siValue (vNum 50), siBind (iRange [ inMin 0, inMax 200, inStep 1 ]) ]
                << signal "aspect" [ siValue (vBool True), siBind (iCheckbox []) ]
                << signal "align" [ siValue (vStr "left"), siBind (iSelect [ inOptions (vStrs [ "left", "center", "right" ]) ]) ]
                << signal "baseline" [ siValue (vStr "top"), siBind (iSelect [ inOptions (vStrs [ "top", "middle", "bottom" ]) ]) ]

        mk =
            marks
                << mark Image
                    [ mEncode
                        [ enEnter [ maUrl [ vStr "https://vega.github.io/images/idl-logo.png" ] ]
                        , enUpdate
                            [ maOpacity [ vNum 1 ]
                            , maX [ vSignal "x" ]
                            , maY [ vSignal "y" ]
                            , maWidth [ vSignal "w" ]
                            , maHeight [ vSignal "h" ]
                            , maAspect [ vSignal "aspect" ]
                            , maAlign [ vSignal "align" ]
                            , maBaseline [ vSignal "baseline" ]
                            ]
                        , enHover [ maOpacity [ vNum 0.5 ] ]
                        ]
                    ]
    in
    toVega
        [ width 200, height 200, padding (PSize 5), si [], mk [] ]


lineTest : Spec
lineTest =
    let
        table =
            dataFromColumns "table" []
                << dataColumn "u" (daNums [ 1, 2, 3, 4, 5, 6 ])
                << dataColumn "v" (daNums [ 28, 55, 42, 34, 36, 48 ])

        ds =
            dataSource [ table [] ]

        sc =
            scales
                << scale "xscale"
                    [ scType ScLinear
                    , scDomain (doData [ dDataset "table", dField (str "u") ])
                    , scRange (raDefault RWidth)
                    , scZero (boolean False)
                    ]
                << scale "yscale"
                    [ scType ScLinear
                    , scDomain (doData [ dDataset "table", dField (str "v") ])
                    , scRange (raDefault RHeight)
                    , scZero (boolean True)
                    , scNice niTrue
                    ]

        si =
            signals
                << signal "defined" [ siValue (vBool True), siBind (iCheckbox []) ]
                << signal "interpolate"
                    [ siValue (vStr (markInterpolationLabel Linear))
                    , siBind (iSelect [ inOptions (vStrs [ "basis", "cardinal", "catmull-rom", "linear", "monotone", "natural", "step", "step-after", "step-before" ]) ])
                    ]
                << signal "tension" [ siValue (vNum 0), siBind (iRange [ inMin 0, inMax 1, inStep 0.05 ]) ]
                << signal "strokeWidth" [ siValue (vNum 4), siBind (iRange [ inMin 0, inMax 10, inStep 0.5 ]) ]
                << signal "strokeCap" [ siValue (vStr (strokeCapLabel CButt)), siBind (iSelect [ inOptions (vStrs [ "butt", "round", "square" ]) ]) ]
                << signal "strokeDash" [ siValue (vNums [ 1, 0 ]), siBind (iSelect [ inOptions (toValue [ ( 1, 0 ), ( 8, 8 ), ( 8, 4 ), ( 4, 4 ), ( 4, 2 ), ( 2, 1 ), ( 1, 1 ) ]) ]) ]

        mk =
            marks
                << mark Line
                    [ mFrom [ srData (str "table") ]
                    , mEncode
                        [ enEnter [ maStroke [ vStr "#652c90" ] ]
                        , enUpdate
                            [ maX [ vScale (fName "xscale"), vField (fName "u") ]
                            , maY [ vScale (fName "yscale"), vField (fName "v") ]
                            , maDefined [ vSignal "defined || datum.u !== 3" ]
                            , maInterpolate [ vSignal "interpolate" ]
                            , maTension [ vSignal "tension" ]
                            , maStrokeWidth [ vSignal "strokeWidth" ]
                            , maStrokeDash [ vSignal "strokeDash" ]
                            , maStrokeCap [ vSignal "strokeCap" ]
                            , maOpacity [ vNum 1 ]
                            ]
                        , enHover [ maOpacity [ vNum 0.5 ] ]
                        ]
                    ]
    in
    toVega
        [ width 400, height 200, padding (PSize 5), ds, sc [], si [], mk [] ]


pathTest : Spec
pathTest =
    let
        si =
            signals
                << signal "path" [ siValue (vStr "M-50,-50 L50,50 V-50 L-50,50 Z"), siBind (iText [ inPlaceholder "SVG path string" ]) ]
                << signal "x" [ siValue (vNum 100), siBind (iRange [ inMin 10, inMax 190, inStep 1 ]) ]
                << signal "y" [ siValue (vNum 100), siBind (iRange [ inMin 10, inMax 190, inStep 1 ]) ]
                << signal "strokeWidth" [ siValue (vNum 4), siBind (iRange [ inMin 0, inMax 10, inStep 0.5 ]) ]
                << signal "color" [ siValue (vStr "both"), siBind (iRadio [ inOptions (vStrs [ "fill", "stroke", "both" ]) ]) ]

        mk =
            marks
                << mark Path
                    [ mEncode
                        [ enEnter [ maFill [ vStr "#939597" ], maStroke [ vStr "#652c90" ] ]
                        , enUpdate
                            [ maX [ vSignal "x" ]
                            , maY [ vSignal "y" ]
                            , maPath [ vSignal "path" ]
                            , maOpacity [ vNum 1 ]
                            , maStrokeWidth [ vSignal "strokeWidth" ]
                            , maFillOpacity [ vSignal "color === 'fill' || color === 'both' ? 1 : 0" ]
                            , maStrokeOpacity [ vSignal "color === 'stroke' || color === 'both' ? 1 : 0" ]
                            ]
                        , enHover [ maOpacity [ vNum 0.5 ] ]
                        ]
                    ]
    in
    toVega
        [ width 200, height 200, padding (PSize 5), si [], mk [] ]


rectTest : Spec
rectTest =
    let
        si =
            signals
                << signal "x" [ siValue (vNum 50), siBind (iRange [ inMin 1, inMax 100, inStep 1 ]) ]
                << signal "y" [ siValue (vNum 50), siBind (iRange [ inMin 1, inMax 100, inStep 1 ]) ]
                << signal "w" [ siValue (vNum 100), siBind (iRange [ inMin 1, inMax 100, inStep 1 ]) ]
                << signal "h" [ siValue (vNum 100), siBind (iRange [ inMin 1, inMax 100, inStep 1 ]) ]
                << signal "cornerRadius" [ siValue (vNum 0), siBind (iRange [ inMin 0, inMax 50, inStep 1 ]) ]
                << signal "strokeWidth" [ siValue (vNum 4), siBind (iRange [ inMin 0, inMax 10 ]) ]
                << signal "color" [ siValue (vStr "both"), siBind (iRadio [ inOptions (vStrs [ "fill", "stroke", "both" ]) ]) ]

        mk =
            marks
                << mark Rect
                    [ mEncode
                        [ enEnter [ maFill [ vStr "#939597" ], maStroke [ vStr "#652c90" ] ]
                        , enUpdate
                            [ maX [ vSignal "x" ]
                            , maY [ vSignal "y" ]
                            , maWidth [ vSignal "w" ]
                            , maHeight [ vSignal "h" ]
                            , maOpacity [ vNum 1 ]
                            , maCornerRadius [ vSignal "cornerRadius" ]
                            , maStrokeWidth [ vSignal "strokeWidth" ]
                            , maFillOpacity [ vSignal "color === 'fill' || color === 'both' ? 1 : 0" ]
                            , maStrokeOpacity [ vSignal "color === 'stroke' || color === 'both' ? 1 : 0" ]
                            ]
                        , enHover [ maOpacity [ vNum 0.5 ] ]
                        ]
                    ]
    in
    toVega
        [ width 200, height 200, padding (PSize 5), si [], mk [] ]


ruleTest : Spec
ruleTest =
    let
        si =
            signals
                << signal "x" [ siValue (vNum 50), siBind (iRange [ inMin 0, inMax 200, inStep 1 ]) ]
                << signal "y" [ siValue (vNum 50), siBind (iRange [ inMin 0, inMax 200, inStep 1 ]) ]
                << signal "x2" [ siValue (vNum 150), siBind (iRange [ inMin 0, inMax 200, inStep 1 ]) ]
                << signal "y2" [ siValue (vNum 150), siBind (iRange [ inMin 0, inMax 200, inStep 1 ]) ]
                << signal "strokeWidth" [ siValue (vNum 4), siBind (iRange [ inMin 0, inMax 10, inStep 0.5 ]) ]
                << signal "strokeCap" [ siValue (vStr (strokeCapLabel CButt)), siBind (iSelect [ inOptions (vStrs [ "butt", "round", "square" ]) ]) ]
                << signal "strokeDash" [ siValue (vNums [ 1, 0 ]), siBind (iSelect [ inOptions (toValue [ ( 1, 0 ), ( 8, 8 ), ( 8, 4 ), ( 4, 4 ), ( 4, 2 ), ( 2, 1 ), ( 1, 1 ) ]) ]) ]

        mk =
            marks
                << mark Rule
                    [ mEncode
                        [ enEnter [ maStroke [ vStr "#652c90" ] ]
                        , enUpdate
                            [ maX [ vSignal "x" ]
                            , maY [ vSignal "y" ]
                            , maX2 [ vSignal "x2" ]
                            , maY2 [ vSignal "y2" ]
                            , maStrokeWidth [ vSignal "strokeWidth" ]
                            , maStrokeDash [ vSignal "strokeDash" ]
                            , maStrokeCap [ vSignal "strokeCap" ]
                            , maOpacity [ vNum 1 ]
                            ]
                        , enHover [ maOpacity [ vNum 0.5 ] ]
                        ]
                    ]
    in
    toVega
        [ width 200, height 200, padding (PSize 5), si [], mk [] ]


symbolTest : Spec
symbolTest =
    let
        si =
            signals
                << signal "shape"
                    [ siValue (vStr "circle")
                    , siBind
                        (iSelect
                            [ inOptions
                                (vStrs
                                    [ symbolLabel SymCircle
                                    , symbolLabel SymSquare
                                    , symbolLabel SymCross
                                    , symbolLabel SymDiamond
                                    , symbolLabel SymTriangleUp
                                    , symbolLabel SymTriangleDown
                                    , symbolLabel SymTriangleRight
                                    , symbolLabel SymTriangleLeft
                                    , "M-1,-1H1V1H-1Z"
                                    , "M0,.5L.6,.8L.5,.1L1,-.3L.3,-.4L0,-1L-.3,-.4L-1,-.3L-.5,.1L-.6,.8L0,.5Z"
                                    ]
                                )
                            ]
                        )
                    ]
                << signal "size" [ siValue (vNum 2000), siBind (iRange [ inMin 0, inMax 10000, inStep 100 ]) ]
                << signal "x" [ siValue (vNum 100), siBind (iRange [ inMin 10, inMax 190, inStep 1 ]) ]
                << signal "y" [ siValue (vNum 100), siBind (iRange [ inMin 10, inMax 190, inStep 1 ]) ]
                << signal "strokeWidth" [ siValue (vNum 4), siBind (iRange [ inMin 0, inMax 10, inStep 0.5 ]) ]
                << signal "color" [ siValue (vStr "both"), siBind (iRadio [ inOptions (vStrs [ "fill", "stroke", "both" ]) ]) ]

        mk =
            marks
                << mark Symbol
                    [ mEncode
                        [ enEnter [ maFill [ vStr "#939597" ], maStroke [ vStr "#652c90" ] ]
                        , enUpdate
                            [ maX [ vSignal "x" ]
                            , maY [ vSignal "y" ]
                            , maSize [ vSignal "size" ]
                            , maShape [ vSignal "shape" ]
                            , maOpacity [ vNum 1 ]
                            , maStrokeWidth [ vSignal "strokeWidth" ]
                            , maFillOpacity [ vSignal "color === 'fill' || color === 'both' ? 1 : 0" ]
                            , maStrokeOpacity [ vSignal "color === 'stroke' || color === 'both' ? 1 : 0" ]
                            ]
                        , enHover [ maOpacity [ vNum 0.5 ] ]
                        ]
                    ]
    in
    toVega
        [ width 200, height 200, padding (PSize 5), si [], mk [] ]


textTest : Spec
textTest =
    let
        si =
            signals
                << signal "x" [ siValue (vNum 100), siBind (iRange [ inMin 0, inMax 200, inStep 1 ]) ]
                << signal "y" [ siValue (vNum 100), siBind (iRange [ inMin 0, inMax 200, inStep 1 ]) ]
                << signal "dx" [ siValue (vNum 0), siBind (iRange [ inMin -20, inMax 20, inStep 1 ]) ]
                << signal "angle" [ siValue (vNum 0), siBind (iRange [ inMin -180, inMax 180, inStep 1 ]) ]
                << signal "fontSize" [ siValue (vNum 10), siBind (iRange [ inMin 1, inMax 36, inStep 1 ]) ]
                << signal "limit" [ siValue (vNum 0), siBind (iRange [ inMin 0, inMax 150, inStep 1 ]) ]
                << signal "align" [ siValue (vStr (hAlignLabel AlignLeft)), siBind (iSelect [ inOptions (vStrs [ "left", "center", "right" ]) ]) ]
                << signal "baseline" [ siValue (vStr (vAlignLabel Alphabetic)), siBind (iSelect [ inOptions (vStrs [ "alphabetic", "top", "middle", "bottom" ]) ]) ]
                << signal "font" [ siValue (vStr "sans-serif"), siBind (iRadio [ inOptions (vStrs [ "sans-serif", "serif", "monospace" ]) ]) ]
                << signal "fontWeight" [ siValue (vStr "normal"), siBind (iRadio [ inOptions (vStrs [ "normal", "bold" ]) ]) ]
                << signal "fontStyle" [ siValue (vStr "normal"), siBind (iRadio [ inOptions (vStrs [ "normal", "italic" ]) ]) ]

        mk =
            marks
                << mark Symbol
                    [ mInteractive (boolean False)
                    , mEncode
                        [ enEnter [ maFill [ vStr "firebrick" ], maSize [ vNum 25 ] ]
                        , enUpdate [ maX [ vSignal "x" ], maY [ vSignal "y" ] ]
                        ]
                    ]
                << mark Text
                    [ mEncode
                        [ enEnter [ maFill [ vStr "#000" ], maText [ vStr "Text Label" ] ]
                        , enUpdate
                            [ maOpacity [ vNum 1 ]
                            , maX [ vSignal "x" ]
                            , maY [ vSignal "y" ]
                            , maDx [ vSignal "dx" ]
                            , maAngle [ vSignal "angle" ]
                            , maAlign [ vSignal "align" ]
                            , maBaseline [ vSignal "baseline" ]
                            , maFont [ vSignal "font" ]
                            , maFontSize [ vSignal "fontSize" ]
                            , maFontStyle [ vSignal "fontStyle" ]
                            , maFontWeight [ vSignal "fontWeight" ]
                            , maLimit [ vSignal "limit" ]
                            ]
                        , enHover [ maOpacity [ vNum 0.5 ] ]
                        ]
                    ]
    in
    toVega
        [ width 200, height 200, padding (PSize 5), si [], mk [] ]


trailTest : Spec
trailTest =
    let
        table =
            dataFromColumns "table" []
                << dataColumn "u" (daNums [ 1, 2, 3, 4, 5, 6 ])
                << dataColumn "v" (daNums [ 28, 55, 42, 34, 36, 48 ])

        ds =
            dataSource [ table [] ]

        sc =
            scales
                << scale "xscale"
                    [ scType ScLinear
                    , scDomain (doData [ dDataset "table", dField (str "u") ])
                    , scRange (raDefault RWidth)
                    , scZero (boolean False)
                    ]
                << scale "yscale"
                    [ scType ScLinear
                    , scDomain (doData [ dDataset "table", dField (str "v") ])
                    , scRange (raDefault RHeight)
                    , scZero (boolean True)
                    , scNice niTrue
                    ]
                << scale "zscale"
                    [ scType ScLinear
                    , scRange (raNums [ 5, 1 ])
                    , scDomain (doData [ dDataset "table", dField (str "v") ])
                    ]

        si =
            signals
                << signal "defined" [ siValue (vBool True), siBind (iCheckbox []) ]
                << signal "size" [ siValue (vNum 5), siBind (iRange [ inMin 1, inMax 10 ]) ]

        mk =
            marks
                << mark Trail
                    [ mFrom [ srData (str "table") ]
                    , mEncode
                        [ enEnter [ maFill [ vStr "#939597" ] ]
                        , enUpdate
                            [ maX [ vScale (fName "xscale"), vField (fName "u") ]
                            , maY [ vScale (fName "yscale"), vField (fName "v") ]
                            , maSize [ vScale (fName "zscale"), vField (fName "v"), vMultiply (vSignal "size") ]
                            , maDefined [ vSignal "defined || datum.u !== 3" ]
                            , maOpacity [ vNum 1 ]
                            ]
                        , enHover [ maOpacity [ vNum 0.5 ] ]
                        ]
                    ]
    in
    toVega
        [ width 400, height 200, padding (PSize 5), ds, sc [], si [], mk [] ]


sourceExample : Spec
sourceExample =
    groupTest



{- This list comprises the specifications to be provided to the Vega runtime. -}


mySpecs : Spec
mySpecs =
    combineSpecs
        [ ( "arcTest", arcTest )
        , ( "areaTest", areaTest )
        , ( "groupTest", groupTest )
        , ( "imageTest", imageTest )
        , ( "lineTest", lineTest )
        , ( "pathTest", pathTest )
        , ( "rectTest", rectTest )
        , ( "ruleTest", ruleTest )
        , ( "symbolTest", symbolTest )
        , ( "textTest", textTest )
        , ( "trailTest", trailTest )
        ]



{- ---------------------------------------------------------------------------
   The code below creates an Elm module that opens an outgoing port to Javascript
   and sends both the specs and DOM node to it.
   This is used to display the generated Vega specs for testing purposes.
-}


main : Program Never Spec msg
main =
    Html.program
        { init = ( mySpecs, elmToJS mySpecs )
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
