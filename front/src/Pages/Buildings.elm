module Pages.Buildings exposing (Model, Msg, page)

import CustomersApi.InputObject
    exposing
        ( AreaInput
        , buildAreaInput
        , buildPositionInput
        )
import CustomersApi.Mutation as Mutation
import CustomersApi.Object
import CustomersApi.Object.Building as Building
import CustomersApi.Object.Customer as Customer
import CustomersApi.Object.Position as Position
import CustomersApi.Object.Site as Site
import CustomersApi.Query as Query
import CustomersApi.Scalar exposing (Decimal(..))
import CustomersApi.ScalarCodecs exposing (Void)
import Debug
import Dialog exposing (Config, view)
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Gen.Params.Example exposing (Params)
import Graphql.Http
import Graphql.Operation exposing (RootMutation, RootQuery)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Html.Attributes as Attr exposing (style)
import Page
import RemoteData exposing (RemoteData)
import Request exposing (Request)
import Shared
import UI exposing (cross, deepBlue, grey, layout)
import View exposing (View)



-- INIT


type alias Model =
    { status : RData
    , deleteStatus : RDeleteData
    , buildings : List Building
    , searching : Search
    , toDelete : Maybe Int
    }


type alias RData =
    RemoteData (Graphql.Http.Error Response) Response


type alias RDeleteData =
    RemoteData (Graphql.Http.Error DeleteResponse) DeleteResponse


type alias Search =
    { customerName : Maybe String
    , area : Maybe AreaInput
    }


type alias Response =
    List Building


type alias DeleteResponse =
    Maybe Void


type alias Position =
    { longitude : String
    , latitude : String
    }


type alias Building =
    { id : Int
    , label : String
    , position : Maybe Position
    , site : Site
    }


type alias Site =
    { label : String
    , owner : Customer
    }


type alias Customer =
    { name : String }


page : Shared.Model -> Request -> Page.With Model Msg
page shared req =
    Page.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


init : ( Model, Cmd Msg )
init =
    let
        model =
            { status = RemoteData.NotAsked
            , deleteStatus = RemoteData.NotAsked
            , buildings = []
            , searching =
                { customerName = Nothing
                , area = Nothing
                }
            , toDelete = Nothing
            }
    in
    ( model
    , makeRequest model.searching
    )



-- API


makeRequest : Search -> Cmd Msg
makeRequest { customerName, area } =
    let
        options =
            case ( customerName, area ) of
                ( Nothing, Nothing ) ->
                    identity

                ( Nothing, Just zone ) ->
                    \optionals -> { optionals | area = Present zone }

                ( Just name, Nothing ) ->
                    \optionals ->
                        { optionals | customerName = Present ("%" ++ name ++ "%") }

                ( Just name, Just zone ) ->
                    \optionals ->
                        { optionals
                            | customerName = Present ("%" ++ name ++ "%")
                            , area = Present zone
                        }
    in
    query options
        |> Graphql.Http.queryRequest "http://localhost:8000"
        |> Graphql.Http.send (RemoteData.fromResult >> GotResponse)


makeDeleteRequest : Int -> Cmd Msg
makeDeleteRequest id =
    sendDeleteBuildingMutation id
        |> Graphql.Http.mutationRequest "http://localhost:8000"
        |> Graphql.Http.send (RemoteData.fromResult >> GotDeleteResponse)


sendDeleteBuildingMutation : Int -> SelectionSet DeleteResponse RootMutation
sendDeleteBuildingMutation id =
    Mutation.deleteBuilding
        { id = id }


query :
    (Query.BuildingsOptionalArguments -> Query.BuildingsOptionalArguments)
    -> SelectionSet Response RootQuery
query args =
    Query.buildings args buildingInfoSelection


buildingInfoSelection : SelectionSet Building CustomersApi.Object.Building
buildingInfoSelection =
    SelectionSet.succeed Building
        |> SelectionSet.with Building.id
        |> SelectionSet.with Building.label
        |> SelectionSet.with
            (SelectionSet.succeed Position
                |> SelectionSet.with (SelectionSet.map parseDecimal Position.long)
                |> SelectionSet.with (SelectionSet.map parseDecimal Position.lat)
                |> Building.position
            )
        |> SelectionSet.with
            (SelectionSet.succeed Site
                |> SelectionSet.with Site.label
                |> SelectionSet.with
                    (SelectionSet.succeed Customer
                        |> SelectionSet.with Customer.name
                        |> Site.owner
                    )
                |> Building.site
            )



-- UPDATE


type Corner
    = Bottom
    | Top


type Axe
    = X
    | Y


type Msg
    = GotResponse RData
    | SearchCustomer String
    | AreaChange Corner Axe Float
    | SearchAreaChecked Bool
    | ResetClicked
    | LaunchClicked
    | Delete Int
    | CancelDeletion
    | CommitDeletion
    | GotDeleteResponse RDeleteData


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotResponse rdata ->
            case rdata of
                RemoteData.Success buildings ->
                    ( { model | status = rdata, buildings = buildings }, Cmd.none )

                _ ->
                    ( { model | status = rdata }, Cmd.none )

        SearchCustomer term ->
            let
                old =
                    model.searching

                new =
                    if term == "" then
                        { old | customerName = Nothing }

                    else
                        { old | customerName = Just term }
            in
            ( { model | searching = new }, makeRequest new )

        AreaChange corner axe value ->
            changeArea model corner axe value

        SearchAreaChecked True ->
            let
                old =
                    model.searching

                newTop =
                    buildPositionInput
                        { long = Decimal "165.0"
                        , lat = Decimal "67.0"
                        }

                newBottom =
                    buildPositionInput
                        { long = Decimal "-165.0"
                        , lat = Decimal "-67.0"
                        }

                new =
                    { old
                        | area =
                            Just <|
                                buildAreaInput
                                    { bottomCorner = newBottom
                                    , topCorner = newTop
                                    }
                    }
            in
            ( { model | searching = new }, Cmd.none )

        SearchAreaChecked False ->
            let
                old =
                    model.searching

                new =
                    { old
                        | area = Nothing
                    }
            in
            ( { model | searching = new }, makeRequest new )

        LaunchClicked ->
            ( model, makeRequest model.searching )

        ResetClicked ->
            let
                new =
                    { customerName = Nothing, area = Nothing }
            in
            ( { model | searching = new }, makeRequest new )

        Delete id ->
            ( { model | toDelete = Just id }, Cmd.none )

        CancelDeletion ->
            ( { model | toDelete = Nothing }, Cmd.none )

        CommitDeletion ->
            let
                new_model =
                    { model | toDelete = Nothing }
            in
            case model.toDelete of
                Just id ->
                    ( new_model, makeDeleteRequest id )

                Nothing ->
                    ( new_model, Cmd.none )

        GotDeleteResponse rdata ->
            case rdata of
                RemoteData.Success _ ->
                    ( { model | toDelete = Nothing }, makeRequest model.searching )

                _ ->
                    ( { model | toDelete = Nothing }, Cmd.none )


changeArea : Model -> Corner -> Axe -> Float -> ( Model, Cmd Msg )
changeArea model corner axe value =
    let
        old =
            model.searching

        oldArea =
            old.area
    in
    case corner of
        Bottom ->
            case axe of
                X ->
                    case oldArea of
                        Just area ->
                            let
                                oldBottom =
                                    area.bottomCorner

                                newBottom =
                                    { oldBottom | long = Decimal <| String.fromFloat value }

                                newArea =
                                    { area | bottomCorner = newBottom }

                                new =
                                    { old | area = Just newArea }
                            in
                            ( { model | searching = new }, Cmd.none )

                        Nothing ->
                            let
                                newBottom =
                                    buildPositionInput
                                        { lat = Decimal "-67.0"
                                        , long = Decimal <| String.fromFloat value
                                        }

                                newTop =
                                    buildPositionInput
                                        { lat = Decimal "67.0"
                                        , long = Decimal "165.0"
                                        }

                                new =
                                    { old
                                        | area =
                                            Just <|
                                                buildAreaInput
                                                    { bottomCorner = newBottom
                                                    , topCorner = newTop
                                                    }
                                    }
                            in
                            ( { model | searching = new }, Cmd.none )

                Y ->
                    case oldArea of
                        Just area ->
                            let
                                oldBottom =
                                    area.bottomCorner

                                newBottom =
                                    { oldBottom | lat = Decimal <| String.fromFloat value }

                                newArea =
                                    { area | bottomCorner = newBottom }

                                new =
                                    { old | area = Just newArea }
                            in
                            ( { model | searching = new }, Cmd.none )

                        Nothing ->
                            let
                                newBottom =
                                    buildPositionInput
                                        { long = Decimal "-165.0"
                                        , lat = Decimal <| String.fromFloat value
                                        }

                                newTop =
                                    buildPositionInput
                                        { long = Decimal "165.0"
                                        , lat = Decimal "67.0"
                                        }

                                new =
                                    { old
                                        | area =
                                            Just <|
                                                buildAreaInput
                                                    { bottomCorner = newBottom
                                                    , topCorner = newTop
                                                    }
                                    }
                            in
                            ( { model | searching = new }, Cmd.none )

        Top ->
            case axe of
                X ->
                    case oldArea of
                        Just area ->
                            let
                                oldTop =
                                    area.topCorner

                                newTop =
                                    { oldTop | long = Decimal <| String.fromFloat value }

                                newArea =
                                    { area | topCorner = newTop }

                                new =
                                    { old | area = Just newArea }
                            in
                            ( { model | searching = new }, Cmd.none )

                        Nothing ->
                            let
                                newTop =
                                    buildPositionInput
                                        { lat = Decimal "67.0"
                                        , long = Decimal <| String.fromFloat value
                                        }

                                newBottom =
                                    buildPositionInput
                                        { lat = Decimal "-67.0"
                                        , long = Decimal "-165.0"
                                        }

                                new =
                                    { old
                                        | area =
                                            Just <|
                                                buildAreaInput
                                                    { bottomCorner = newBottom
                                                    , topCorner = newTop
                                                    }
                                    }
                            in
                            ( { model | searching = new }, Cmd.none )

                Y ->
                    case oldArea of
                        Just area ->
                            let
                                oldTop =
                                    area.topCorner

                                newTop =
                                    { oldTop | lat = Decimal <| String.fromFloat value }

                                newArea =
                                    { area | topCorner = newTop }

                                new =
                                    { old | area = Just newArea }
                            in
                            ( { model | searching = new }, Cmd.none )

                        Nothing ->
                            let
                                newTop =
                                    buildPositionInput
                                        { long = Decimal "165.0"
                                        , lat = Decimal <| String.fromFloat value
                                        }

                                newBottom =
                                    buildPositionInput
                                        { long = Decimal "-165.0"
                                        , lat = Decimal "-67.0"
                                        }

                                new =
                                    { old
                                        | area =
                                            Just <|
                                                buildAreaInput
                                                    { bottomCorner = newBottom
                                                    , topCorner = newTop
                                                    }
                                    }
                            in
                            ( { model | searching = new }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Beebryte - buildings"
    , body = layout "Buildings" <| mainElem model
    }


mainElem : Model -> Element Msg
mainElem model =
    let
        attributes =
            case model.toDelete of
                Just id ->
                    [ Element.inFront <|
                        Dialog.view <|
                            Just confirmDeleteDialog
                    ]

                Nothing ->
                    []
    in
    Element.row
        ([ Element.width Element.fill
         , Element.height Element.fill
         , Element.spacing 5
         , Element.paddingXY 15 0
         ]
            ++ attributes
        )
        [ searchForm model
        , buildingList model.buildings
        ]


confirmDeleteDialog =
    { closeMessage = Nothing
    , maskAttributes = []
    , headerAttributes = []
    , bodyAttributes = []
    , footerAttributes = []
    , containerAttributes =
        [ Background.color (Element.rgb 1 1 1)
        , Element.centerX
        , Element.centerY
        , Element.height (Element.px 200)
        , Element.width (Element.px 400)
        , Element.spacing 10
        , Border.solid
        , Border.width 1
        ]
    , header =
        Just <|
            Element.el
                [ Element.width Element.fill
                , Background.color (Element.rgb 1 0.7 0.7)
                , Element.padding 5
                ]
                (Element.text "Please confirm deletion")
    , body =
        Just <|
            Element.column
                [ Element.spacing 10
                , Element.padding 5
                ]
                [ Element.paragraph []
                    [ Element.text "You are about to delete a building."
                    , Element.text "This deletion will cannot be undone."
                    ]
                , Element.paragraph []
                    [ Element.text "Please confirm by clicking on 'Commit'." ]
                , Element.row
                    [ Element.alignRight
                    , Element.spacing 8
                    , Element.padding 10                   ]
                    [ Input.button
                        [ Background.color (Element.rgb 0.8 0.8 1.0)
                        , Element.width (Element.px 100)
                        , Element.height (Element.px 30)
                        , Border.shadow
                            { offset = ( 1, 1 )
                            , size = 1.0
                            , blur = 2.5
                            , color = Element.rgb255 94 103 111
                            }
                        ]
                        { label =
                            Element.el [ Element.centerX ] <|
                                Element.text "Cancel"
                        , onPress = Just <| CancelDeletion
                        }
                    , Input.button
                        [ Background.color (Element.rgb 1.0 0.9 0.9)
                        , Element.width (Element.px 100)
                        , Element.height (Element.px 30)
                        , Border.shadow
                            { offset = ( 1, 1 )
                            , size = 1.0
                            , blur = 2.5
                            , color = Element.rgb255 94 103 111
                            }
                        ]
                        { label =
                            Element.el [ Element.centerX ] <|
                                Element.text "Commit"
                        , onPress = Just <| CommitDeletion
                        }
                    ]
                ]
    , footer = Nothing
    }


searchForm : Model -> Element Msg
searchForm model =
    Element.column
        [ Element.width (Element.px 300)
        , Element.alignTop
        , Element.paddingXY 0 50
        , Element.spacing 30
        ]
        [ searchCustomerForm model
        , searchAreaForm model
        , Input.button
            [ Background.color grey
            , Element.width Element.fill
            , Element.padding 5
            , Element.centerX
            , Border.shadow
                { offset = ( 1, 1 )
                , size = 1.0
                , blur = 2.5
                , color = Element.rgb255 94 103 111
                }
            , Font.color deepBlue
            ]
            { onPress = Just ResetClicked
            , label = Element.el [ Element.centerX ] <| Element.text "reset"
            }
        ]


searchCustomerForm : Model -> Element Msg
searchCustomerForm model =
    Input.text
        [ Element.width (Element.px 300)
        , Element.alignTop
        , Element.padding 5
        ]
        { onChange = SearchCustomer
        , text =
            case model.searching.customerName of
                Just name ->
                    name

                _ ->
                    ""
        , placeholder =
            Just <|
                Input.placeholder [] <|
                    Element.text "customer name"
        , label = Input.labelAbove [] <| Element.text "Customer"
        }


searchAreaForm : Model -> Element Msg
searchAreaForm model =
    Element.column
        [ Element.spacing 5
        , Border.width 1
        , Border.solid
        , Element.padding 5
        , case model.searching.area of
            Just _ ->
                Background.color (Element.rgba 1.0 1.0 1 1)

            _ ->
                Background.color (Element.rgba 0.9 0.9 0.9 0.7)
        ]
        [ Input.checkbox []
            { onChange = SearchAreaChecked
            , icon = Input.defaultCheckbox
            , checked =
                case model.searching.area of
                    Just _ ->
                        True

                    _ ->
                        False
            , label =
                Input.labelRight []
                    (Element.text "Area search")
            }
        , Element.column
            [ Border.solid
            , Border.width 1
            , Element.padding 10
            ]
          <|
            areaSliders model
        , Input.button
            [ Background.color grey
            , Element.width Element.fill
            , Element.padding 5
            , Element.centerX
            , Border.shadow
                { offset = ( 1, 1 )
                , size = 1.0
                , blur = 2.5
                , color = Element.rgb255 94 103 111
                }
            , Font.color deepBlue
            ]
            { onPress = Just LaunchClicked
            , label = Element.el [ Element.centerX ] <| Element.text "search"
            }
        , let
            area =
                model.searching.area
          in
          case area of
            Just area_ ->
                Element.column
                    [ Font.size 15
                    , Element.paddingXY 5 30
                    ]
                    [ Element.el [] <|
                        Element.text
                            (parseDecimal area_.bottomCorner.long
                                ++ ", "
                                ++ parseDecimal area_.bottomCorner.lat
                            )
                    , Element.el [] <|
                        Element.text
                            (parseDecimal area_.topCorner.long
                                ++ ", "
                                ++ parseDecimal area_.topCorner.lat
                            )
                    ]

            Nothing ->
                Element.el [ Element.height (Element.px 90) ] Element.none
        ]


areaSliders : Model -> List (Element Msg)
areaSliders model =
    [ Input.slider
        [ Element.width (Element.px 270)
        , Element.alignTop
        , Element.padding 5
        , Element.behindContent
            (Element.el
                [ Element.width Element.fill
                , Element.height (Element.px 2)
                , Element.centerY
                , Background.color (Element.rgba255 82 70 83 0.45)
                , Border.rounded 2
                ]
                Element.none
            )
        ]
        { onChange = AreaChange Bottom X
        , value =
            case model.searching.area of
                Just value ->
                    case String.toFloat <| parseDecimal value.bottomCorner.long of
                        Just v ->
                            v

                        _ ->
                            -165.0

                _ ->
                    -165.0
        , label = Input.labelAbove [] <| Element.text "X-bottom"
        , min = -165.0
        , max = 165.0
        , step = Just 0.0001
        , thumb = Input.defaultThumb
        }
    , Input.slider
        [ Element.width (Element.px 270)
        , Element.alignTop
        , Element.padding 5
        , Element.behindContent
            (Element.el
                [ Element.width Element.fill
                , Element.height (Element.px 2)
                , Element.centerY
                , Background.color (Element.rgba255 82 70 83 0.45)
                , Border.rounded 2
                ]
                Element.none
            )
        ]
        { onChange = AreaChange Bottom Y
        , value =
            case model.searching.area of
                Just value ->
                    case String.toFloat <| parseDecimal value.bottomCorner.lat of
                        Just v ->
                            v

                        _ ->
                            -67.0

                _ ->
                    -67.0
        , label = Input.labelAbove [] <| Element.text "Y-bottom"
        , min = -67.0
        , max = 67.0
        , step = Just 0.0001
        , thumb = Input.defaultThumb
        }
    , Input.slider
        [ Element.width (Element.px 270)
        , Element.alignTop
        , Element.padding 5
        , Element.behindContent
            (Element.el
                [ Element.width Element.fill
                , Element.height (Element.px 2)
                , Element.centerY
                , Background.color (Element.rgba255 82 70 83 0.45)
                , Border.rounded 2
                ]
                Element.none
            )
        ]
        { onChange = AreaChange Top X
        , value =
            case model.searching.area of
                Just value ->
                    case String.toFloat <| parseDecimal value.topCorner.long of
                        Just v ->
                            v

                        _ ->
                            165.0

                _ ->
                    165.0
        , label = Input.labelAbove [] <| Element.text "X-top"
        , min = -165.0
        , max = 165.0
        , step = Just 0.0001
        , thumb = Input.defaultThumb
        }
    , Input.slider
        [ Element.width (Element.px 270)
        , Element.alignTop
        , Element.padding 5
        , Element.behindContent
            (Element.el
                [ Element.width Element.fill
                , Element.height (Element.px 2)
                , Element.centerY
                , Background.color (Element.rgba255 82 70 83 0.45)
                , Border.rounded 2
                ]
                Element.none
            )
        ]
        { onChange = AreaChange Top Y
        , value =
            case model.searching.area of
                Just value ->
                    case String.toFloat <| parseDecimal value.topCorner.lat of
                        Just v ->
                            v

                        _ ->
                            67.0

                _ ->
                    67.0
        , label = Input.labelAbove [] <| Element.text "Y-top"
        , min = -67.0
        , max = 67
        , step = Just 0.0001
        , thumb = Input.defaultThumb
        }
    ]


buildingList : List Building -> Element Msg
buildingList buildings =
    Element.column
        [ Font.size 15
        , Element.centerX
        , Element.spacing 1
        , Border.solid
        , Border.width 1
        , Element.height Element.fill
        ]
    <|
        [ buildingsHeader
        , Element.column
            [ Element.scrollbarY
            , Element.height Element.fill
            , Element.padding 5
            , Border.innerShadow
                { offset = ( 1, 1 )
                , size = 0.0
                , blur = 4.0
                , color = Element.rgba 0 0 0 0.6
                }
            ]
          <|
            List.map buildingRow buildings
        ]


buildingRow : Building -> Element Msg
buildingRow building =
    Element.row
        [ Element.spacing 45
        ]
        [ Element.el [ Element.width (Element.px 100) ] <|
            Element.text building.site.owner.name
        , Element.el [ Element.width (Element.px 200) ] <|
            Element.text building.site.label
        , Element.el [ Element.width (Element.px 250) ] <|
            Element.text building.label
        , Element.el [ Element.width (Element.px 300) ] <|
            Element.text <|
                formatPos building.position
        , Input.button
            [ Element.width (Element.px 20)
            , Element.padding 4
            , Element.centerX
            , Element.centerY
            ]
            { onPress = Just <| Delete building.id
            , label = Element.html <| cross 11 "rgb(0, 10, 40)"
            }
        ]


buildingsHeader : Element msg
buildingsHeader =
    Element.row
        [ Element.spacing 45
        , Background.color (Element.rgb 0.9 0.9 0.9)
        , Font.size 20
        , Element.paddingXY 2 5
        , Element.width Element.fill
        , Border.shadow
            { offset = ( 0.0, 2 )
            , size = 0.0
            , blur = 2.0
            , color = Element.rgba 0 0 0 0.6
            }
        ]
        [ Element.el [ Element.width (Element.px 100) ] <| Element.text "customer"
        , Element.el [ Element.width (Element.px 200) ] <| Element.text "site"
        , Element.el [ Element.width (Element.px 250) ] <| Element.text "building"
        , Element.el [ Element.width (Element.px 300) ] <| Element.text "position"
        , Element.el [ Element.width (Element.px 20) ] Element.none
        ]


formatPos : Maybe Position -> String
formatPos position =
    case position of
        Just coord ->
            let
                long =
                    coord.longitude

                lat =
                    coord.latitude
            in
            "(" ++ long ++ ", " ++ lat ++ ")"

        _ ->
            ""


parseDecimal : Decimal -> String
parseDecimal (Decimal string) =
    string
