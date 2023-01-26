module UI exposing (cross, deepBlue, grey, h1, layout)

import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Gen.Route as Route exposing (Route)
import Html exposing (Html)
import Html.Attributes as Attr exposing (style)
import Svg
import Svg.Attributes as SvgAttr


deepBlue =
    Element.rgb255 33 33 55


grey =
    Element.rgb255 183 177 181


cross : Int -> String -> Html msg
cross size color =
    Svg.svg
        [ SvgAttr.width <| String.fromInt size
        , SvgAttr.height <| String.fromInt size
        , SvgAttr.viewBox "0 0 120 120"
        ]
        [ Svg.line
            [ SvgAttr.x1 "10"
            , SvgAttr.y1 "10"
            , SvgAttr.x2 "100"
            , SvgAttr.y2 "100"
            , SvgAttr.stroke color
            , SvgAttr.strokeWidth "15"
            ]
            []
        , Svg.line
            [ SvgAttr.x1 "10"
            , SvgAttr.y1 "100"
            , SvgAttr.x2 "100"
            , SvgAttr.y2 "10"
            , SvgAttr.stroke color
            , SvgAttr.strokeWidth "15"
            ]
            []
        ]


menuItem title page =
    let
        viewLink : String -> Route -> Element msg
        viewLink label route =
            Element.link
                [ Element.htmlAttribute <| style "text-decoration" "none"
                , Element.width Element.fill
                , Border.shadow
                    { offset = ( 1, 1 )
                    , size = 1.0
                    , blur = 2.5
                    , color = Element.rgb255 94 103 111
                    }
                , Element.padding 10
                , Background.color grey
                , Font.color deepBlue
                , Font.size 15
                ]
                { label = Element.text label
                , url = Route.toHref route
                }
    in
    viewLink title page


layout : String -> Element msg -> List (Html msg)
layout title content =
    [ Element.layout
        [ Element.width Element.fill
        , Element.height Element.fill
        , Font.color deepBlue
        ]
      <|
        Element.column
            [ Element.width Element.fill
            , Element.height Element.fill
            ]
            [ header title
            , Element.row
                [ Element.width Element.fill
                , Element.height Element.fill
                , Element.centerX
                ]
                [ Element.el
                    [ Element.width (Element.px 200)
                    , Element.spacing 5
                    , Background.color <| Element.rgb255 215 219 225
                    , Element.height Element.fill
                    , Border.shadow
                        { offset = ( 1, 0 )
                        , size = 1.0
                        , blur = 2.0
                        , color = Element.rgba255 88 92 96 0.38
                        }
                    ]
                  <|
                    Element.column
                        [ Element.paddingXY 10 80
                        , Element.height Element.fill
                        , Element.width (Element.px 200)
                        , Element.spacing 5
                        ]
                        [ menuItem "Home" Route.Home_
                        , menuItem "Buildings" Route.Buildings
                        , menuItem "New Building For Site" Route.NewBuilding
                        ]
                , Element.el
                    [ Element.paddingEach
                        { top = 75
                        , right = 5
                        , bottom = 25
                        , left = 5
                        }
                    , Element.width Element.fill
                    , Element.height Element.fill
                    , Element.centerX
                    , Element.alignTop
                    ]
                    content
                ]
            ]
    ]


h1 : String -> Html msg
h1 label =
    Html.h1 [] [ Html.text label ]


header : String -> Element msg
header title =
    Element.el
        [ Background.color (Element.rgb255 216 212 227)
        , Element.width Element.fill
        , Element.htmlAttribute (style "position" "fixed")
        , Element.htmlAttribute (style "z-index" "2")
        , Element.height (Element.px 50)
        , Font.color (Element.rgb255 83 69 53)
        , Font.size 32
        , Font.family
            [ Font.external
                { url = "https://fonts.googleapis.com/css?family=Ruda"
                , name = "Ruda"
                }
            , Font.sansSerif
            ]
        , Border.shadow
            { offset = ( 0.5, 0.5 )
            , size = 1.0
            , blur = 3.0
            , color = Element.rgba 0 0 0 0.6
            }
        ]
    <|
        Element.el
            [ Element.centerX
            , Element.centerY
            ]
            (Element.text title)
