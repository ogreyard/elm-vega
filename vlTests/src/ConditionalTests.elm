port module ConditionalTests exposing (elmToJS)

import Html exposing (Html, div, pre)
import Html.Attributes exposing (id)
import Json.Encode
import Platform
import VegaLite exposing (..)


markCondition1 : Spec
markCondition1 =
    let
        data =
            dataFromUrl "data/movies.json" []

        config =
            configure
                << configuration (RemoveInvalid False)

        enc =
            encoding
                << position X [ pName "IMDB_Rating", pMType Quantitative ]
                << position Y [ pName "Rotten_Tomatoes_Rating", pMType Quantitative ]
                << color
                    [ mDataCondition
                        (Or (Expr "datum.IMDB_Rating === null")
                            (Expr "datum.Rotten_Tomatoes_Rating === null")
                        )
                        [ mString "#ddd" ]
                        [ mString "#0099ee" ]
                    ]
    in
    toVegaLite [ config [], data, point [], enc [] ]


selectionCondition1 : Spec
selectionCondition1 =
    let
        data =
            dataFromUrl "data/cars.json" []

        sel =
            selection
                << select "alex"
                    Interval
                    [ On "[mousedown[!event.shiftKey], mouseup] > mousemove"
                    , Translate "[mousedown[!event.shiftKey], mouseup] > mousemove"
                    ]
                << select "morgan"
                    Interval
                    [ On "[mousedown[event.shiftKey], mouseup] > mousemove"
                    , Translate "[mousedown[event.shiftKey], mouseup] > mousemove"
                    , SelectionMark [ SMFill "#fdbb84", SMFillOpacity 0.5, SMStroke "#e34a33" ]
                    ]

        enc =
            encoding
                << position Y [ pName "Origin", pMType Ordinal ]
                << position X [ pName "Cylinders", pMType Ordinal ]
                << color [ mAggregate Count, mName "*", mMType Quantitative ]
    in
    toVegaLite
        [ data, sel [], rect [ MCursor CGrab ], enc [] ]


selectionCondition2 : Spec
selectionCondition2 =
    let
        data =
            dataFromUrl "data/cars.json" []

        sel =
            selection
                << select "alex"
                    Interval
                    [ On "[mousedown[!event.shiftKey], mouseup] > mousemove"
                    , Translate "[mousedown[!event.shiftKey], mouseup] > mousemove"
                    ]
                << select "morgan"
                    Interval
                    [ On "[mousedown[event.shiftKey], mouseup] > mousemove"
                    , Translate "[mousedown[event.shiftKey], mouseup] > mousemove"
                    , SelectionMark [ SMFill "#fdbb84", SMFillOpacity 0.5, SMStroke "#e34a33" ]
                    ]

        enc =
            encoding
                << position Y [ pName "Origin", pMType Ordinal ]
                << position X [ pName "Cylinders", pMType Ordinal ]
                << color
                    [ mSelectionCondition (And (selectionName "alex") (selectionName "morgan"))
                        [ mAggregate Count, mName "*", mMType Quantitative ]
                        [ mString "gray" ]
                    ]
    in
    toVegaLite
        [ data, sel [], rect [ MCursor CGrab ], enc [] ]


selectionCondition3 : Spec
selectionCondition3 =
    let
        data =
            dataFromUrl "data/cars.json" []

        trans =
            transform
                << filter (FCompose (And (Expr "datum.Weight_in_lbs > 3000") (Selection "brush")))

        sel =
            selection
                << select "brush" Interval []

        enc1 =
            encoding
                << position X [ pName "Horsepower", pMType Quantitative ]
                << position Y [ pName "Miles_per_Gallon", pMType Quantitative ]

        spec1 =
            asSpec [ sel [], point [], enc1 [] ]

        enc2 =
            encoding
                << position X [ pName "Acceleration", pMType Quantitative, pScale [ SDomain (DNumbers [ 0, 25 ]) ] ]
                << position Y [ pName "Displacement", pMType Quantitative, pScale [ SDomain (DNumbers [ 0, 500 ]) ] ]

        spec2 =
            asSpec [ trans [], point [], enc2 [] ]
    in
    toVegaLite
        [ data, vConcat [ spec1, spec2 ] ]



{- This list comprises the specifications to be provided to the Vega-Lite runtime. -}


mySpecs : Spec
mySpecs =
    combineSpecs
        [ ( "markCondition1", markCondition1 )
        , ( "selectionCondition1", selectionCondition1 )
        , ( "selectionCondition2", selectionCondition2 )
        , ( "selectionCondition3", selectionCondition3 )
        ]


sourceExample : Spec
sourceExample =
    selectionCondition3



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
