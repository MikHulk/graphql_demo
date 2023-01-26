module Pages.NewBuilding exposing (Model, Msg, page)

import CustomersApi.InputObject
    exposing
        ( PositionInput
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
import Graphql.Http.GraphqlError exposing (PossiblyParsedData(..))
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
    , searching : Search
    , label : Maybe String
    , siteSelection : Maybe (List SiteId)
    , siteId : Maybe SiteId
    , positionX : Maybe String
    , positionY : Maybe String
    }


type alias RData =
    RemoteData (Graphql.Http.Error Response) Response


type alias Search =
    { customerName : Maybe String
    }


type alias Response =
    Building


type alias SiteResponse =
    List SiteId


type alias SiteRData =
    RemoteData (Graphql.Http.Error SiteResponse) SiteResponse


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


type alias SiteId =
    { label : String
    , id : Int
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
            , searching =
                { customerName = Nothing
                }
            , label = Nothing
            , siteId = Nothing
            , siteSelection = Nothing
            , positionX = Nothing
            , positionY = Nothing
            }
    in
    ( model, Cmd.none )



-- API


makeRequest : Maybe PositionInput -> String -> Int -> Cmd Msg
makeRequest possiblyPos label siteId =
    sendNewBuildingMutation possiblyPos label siteId
        |> Graphql.Http.mutationRequest "http://localhost:8000"
        |> Graphql.Http.send (RemoteData.fromResult >> GotResponse)


siteQuery :
    (Query.SitesOptionalArguments -> Query.SitesOptionalArguments)
    -> SelectionSet SiteResponse RootQuery
siteQuery args =
    Query.sites args siteInfoSelection


makeSiteRequest : String -> Cmd Msg
makeSiteRequest customerName =
    siteQuery
        (\optionals ->
            { optionals
                | customerName = Present ("%" ++ customerName ++ "%")
            }
        )
        |> Graphql.Http.queryRequest "http://localhost:8000"
        |> Graphql.Http.send (RemoteData.fromResult >> GotSiteResponse)


sendNewBuildingMutation : Maybe PositionInput -> String -> Int -> SelectionSet Building RootMutation
sendNewBuildingMutation possiblyPos label siteId =
    case possiblyPos of
        Nothing ->
            Mutation.addNewBuildingForSite
                identity
                { siteId = siteId
                , label = label
                }
                buildingInfoSelection

        Just pos ->
            Mutation.addNewBuildingForSite
                (\optionals -> { optionals | position = Present pos })
                { siteId = siteId
                , label = label
                }
                buildingInfoSelection


siteInfoSelection : SelectionSet SiteId CustomersApi.Object.Site
siteInfoSelection =
    SelectionSet.succeed SiteId
        |> SelectionSet.with Site.label
        |> SelectionSet.with Site.id


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


type Msg
    = GotResponse RData
    | AcquitError
    | SearchSite String
    | GotSiteResponse SiteRData
    | SiteSelected SiteId
    | LabelChanged String
    | PositionChanged Axe String
    | SendCreation
    | Reinit


type Axe
    = X
    | Y


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotResponse rdata ->
            case rdata of
                RemoteData.Success building ->
                    ( { model | status = rdata }, Cmd.none )

                _ ->
                    ( { model | status = rdata }, Cmd.none )

        SearchSite term ->
            let
                old =
                    model.searching

                new =
                    if term == "" then
                        { old | customerName = Nothing }

                    else
                        { old | customerName = Just term }
            in
            ( { model | searching = new }, makeSiteRequest term )

        GotSiteResponse rdata ->
            case rdata of
                RemoteData.Success sites ->
                    ( { model | siteSelection = Just <| sites }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        SiteSelected siteId ->
            ( { model | siteId = Just siteId }, Cmd.none )

        LabelChanged value ->
            if value == "" then
                ( { model | label = Nothing }, Cmd.none )

            else
                ( { model | label = Just value }, Cmd.none )

        PositionChanged axe s ->
            case axe of
                X ->
                    ( { model | positionX = Just s }, Cmd.none )

                Y ->
                    ( { model | positionY = Just s }, Cmd.none )

        SendCreation ->
            case ( model.siteId, model.label ) of
                ( Just site, Just label ) ->
                    case ( model.positionX, model.positionY ) of
                        ( Just x, Just y ) ->
                            ( { model | status = RemoteData.Loading }
                            , makeRequest
                                (Just <|
                                    buildPositionInput { long = Decimal x, lat = Decimal y }
                                )
                                label
                                site.id
                            )

                        _ ->
                            ( model, makeRequest Nothing label site.id )

                _ ->
                    ( model, Cmd.none )

        AcquitError ->
            ( { model | status = RemoteData.NotAsked }, Cmd.none )

        Reinit ->
            init



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "New building"
    , body = layout "New Building" <| mainElem model
    }


errorDialog messages =
    { closeMessage = Nothing
    , maskAttributes = []
    , headerAttributes = []
    , bodyAttributes = []
    , footerAttributes = []
    , containerAttributes =
        [ Background.color (Element.rgb 1 1 1)
        , Element.centerX
        , Element.centerY
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
                (Element.text "Error")
    , body =
        Just <|
            Element.column
                [ Element.spacing 15
                , Element.padding 8
                , Element.width Element.fill
                ]
            <|
                List.map (Element.el [] << Element.text) messages
                    ++ [ Input.button
                            [ Background.color (Element.rgb 1.0 0.9 0.9)
                            , Element.alignRight
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
                                    Element.text "Close"
                            , onPress = Just <| AcquitError
                            }
                       ]
    , footer = Nothing
    }


mainElem : Model -> Element Msg
mainElem model =
    let
        messages =
            case model.status of
                RemoteData.Failure error ->
                    case error of
                        Graphql.Http.GraphqlError _ parsedError ->
                            let
                                errorMessages =
                                    List.map .message parsedError
                            in
                            Dialog.view <| Just <| errorDialog errorMessages

                        _ ->
                            Element.none

                _ ->
                    Element.none
    in
    Element.el
        [ Element.width Element.fill
        , Element.height Element.fill
        , Element.inFront messages
        , Element.centerX
        ]
    <|
        case model.status of
            RemoteData.Success building ->
                displayBuilding building

            _ ->
                case model.siteId of
                    Nothing ->
                        siteSearchView model

                    Just id ->
                        buildingCreationView id model


displayBuilding : Building -> Element Msg
displayBuilding building =
    Element.column
        [ Element.centerX
        , Element.spacing 10
        ]
        [ Element.el [] <|
            Element.text
              ("new huilding created with id: "
                   ++ String.fromInt building.id)
        , Element.el [] <| Element.text building.label
        , Element.el [] <|
            Element.text <|
                "in site: "
                     ++ building.site.label
        , Element.el [] <|
            Element.text <|
                "for customer: "
                ++ building.site.owner.name
        , Input.button
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
                    Element.text "Ok"
            , onPress = Just <| Reinit
            }
        ]


buildingCreationView : SiteId -> Model -> Element Msg
buildingCreationView site model =
    Element.column
        [ Element.spacing 7
        , Element.centerX
        ]
    <|
        [ Element.row
            [ Element.spacing 7
            ]
            [ Element.text "Site selected:"
            , Element.text <| String.fromInt site.id
            , Element.text site.label
            ]
        , Input.text
            [ Element.width (Element.px 300)
            , Element.alignTop
            , Element.alignRight
            , Element.padding 5
            , Element.spacing 30
            ]
            { onChange = LabelChanged
            , text =
                case model.label of
                    Nothing ->
                        ""

                    Just value ->
                        value
            , placeholder = Nothing
            , label =
                Input.labelLeft
                    [ Element.width (Element.px 100)
                    ]
                <|
                    Element.text "Site label"
            }
        , Input.text
            [ Element.width (Element.px 300)
            , Element.alignTop
            , Element.alignRight
            , Element.padding 5
            , Element.spacing 30
            ]
            { onChange = PositionChanged X
            , text =
                case model.positionX of
                    Nothing ->
                        ""

                    Just value ->
                        value
            , placeholder = Nothing
            , label =
                Input.labelLeft
                    [ Element.width (Element.px 100)
                    ]
                <|
                    Element.text "Site long."
            }
        , Input.text
            [ Element.width (Element.px 300)
            , Element.alignTop
            , Element.alignRight
            , Element.padding 5
            , Element.spacing 30
            ]
            { onChange = PositionChanged Y
            , text =
                case model.positionY of
                    Nothing ->
                        ""

                    Just value ->
                        value
            , placeholder = Nothing
            , label =
                Input.labelLeft
                    [ Element.width (Element.px 100)
                    ]
                <|
                    Element.text "Site lat."
            }
        , Input.button
            [ Background.color (Element.rgb 0.8 0.8 1.0)
            , Element.width (Element.px 100)
            , Element.height (Element.px 30)
            , Element.alignRight
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
            , onPress = Just <| SendCreation
            }
        ]


siteSearchView : Model -> Element Msg
siteSearchView model =
    Element.el
        [ Element.centerX
        ]
    <|
        Input.text
            [ Element.width (Element.px 300)
            , Element.alignTop
            , Element.padding 5
            , Element.spacing 30
            , Element.below <|
                case model.siteSelection of
                    Just selection ->
                        Element.el
                            [ Element.paddingXY 0 7 ]
                        <|
                            siteSelectionView selection

                    Nothing ->
                        Element.none
            ]
            { onChange = SearchSite
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
            , label = Input.labelLeft [] <| Element.text "Customer"
            }


siteRow : SiteId -> Element Msg
siteRow site =
    Input.button
        []
        { label =
            Element.row
                []
                [ Element.text <| String.fromInt site.id
                , Element.text site.label
                ]
        , onPress = Just <| SiteSelected site
        }


siteSelectionView : List SiteId -> Element Msg
siteSelectionView =
    Element.column
        [ Border.solid
        , Border.width 1
        , Element.width (Element.px 300)
        , Element.padding 5
        , Element.spacing 5
        ]
        << List.map siteRow


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
