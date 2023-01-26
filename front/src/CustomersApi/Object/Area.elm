-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module CustomersApi.Object.Area exposing (..)

import CustomersApi.InputObject
import CustomersApi.Interface
import CustomersApi.Object
import CustomersApi.Scalar
import CustomersApi.ScalarCodecs
import CustomersApi.Union
import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Json.Decode as Decode


bottomCorner :
    SelectionSet decodesTo CustomersApi.Object.Position
    -> SelectionSet decodesTo CustomersApi.Object.Area
bottomCorner object____ =
    Object.selectionForCompositeField "bottomCorner" [] object____ Basics.identity


topCorner :
    SelectionSet decodesTo CustomersApi.Object.Position
    -> SelectionSet decodesTo CustomersApi.Object.Area
topCorner object____ =
    Object.selectionForCompositeField "topCorner" [] object____ Basics.identity