module Pages.Home_ exposing (view)

import Element
import Html
import UI exposing (layout)
import View exposing (View)


help_english_text =
    [ """
    🇬🇧
    "buildings" displays the list of buildings.
    You can delete a building by clicking on the adjacent x.
    A site will be deleted when it has no more building,
    Similarly a customer when it has no more site.
     """
    , """
    
    When creating a new "building" it is possible to use an
    existing site or create one. The same goes for customers.
    """
    ]


help_french_text =
    [ """
    🇫🇷
    "buildings" affiche la liste des bâtiments.
     On peut supprimer un building en cliquant sur la croix adjacente.
     Un site sera supprimer qd il n'aura plus de bâtiment, pareillement
     un customer quand celui-ci n'aura plus de site.
     """
    , """
     Lors de la création d'un nouveau "building" il est possible
     d'utiliser un site existant ou en créer un. De même pour les clients.
    """
    ]


view : View msg
view =
    { title = "Homepage"
    , body =
        layout "Hello" <|
            Element.el [ Element.centerX ] <|
                Element.column
                    [ Element.spacing 20
                    , Element.width (Element.fill |> Element.maximum 900)
                    ]
                    [ Element.column
                        [ Element.width Element.fill
                        , Element.spacing 10
                        ]
                      <|
                        List.map (Element.paragraph [] << (\s -> [ Element.text s ])) help_english_text
                    , Element.column
                        [ Element.width Element.fill
                        , Element.spacing 10
                        ]
                      <|
                        List.map (Element.paragraph [] << (\s -> [ Element.text s ])) help_french_text
                    ]
    }
