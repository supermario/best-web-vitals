module Pages.AddSite exposing (Model, Msg, page)

import Api.Site
import Bridge exposing (..)
import Effect exposing (Effect)
import Element exposing (centerX, centerY, fill, height, htmlAttribute, maximum, paddingXY, spacing, width)
import Element.Input as Input
import Gen.Params.AddSite exposing (Params)
import Html.Attributes exposing (style)
import Page
import Request
import Shared
import String exposing (fromInt)
import UI.Styled as Styled
import UI.Styles as Styles
import Utils.Misc exposing (onEnter)
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared _ =
    Page.advanced
        { init = init
        , update = update
        , view = view shared
        , subscriptions = subscriptions
        }



-- INIT


type alias Model =
    { site : String
    , category : Maybe Api.Site.Category
    , frontendLang : Maybe Api.Site.FrontendLang
    }


init : ( Model, Effect Msg )
init =
    ( { site = ""
      , category = Nothing
      , frontendLang = Nothing
      }
    , Effect.batch
        [ Effect.fromCmd <| sendToBackend <| FetchCategories
        , Effect.fromCmd <| sendToBackend <| FetchFrontendLangs
        ]
    )



-- UPDATE


type Msg
    = Updated Field String
    | SubmitSite


type Field
    = Site
    | Category
    | FrontendLang


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        Updated Site site ->
            ( { model | site = site }
            , Effect.none
            )

        Updated Category category ->
            ( { model | category = Just category }
            , Effect.none
            )

        Updated FrontendLang frontendLang ->
            ( { model | frontendLang = Just frontendLang }
            , Effect.none
            )

        SubmitSite ->
            let
                validSite =
                    case model.site |> String.split "://" of
                        [ "http", _ ] ->
                            model.site

                        [ "https", _ ] ->
                            model.site

                        _ ->
                            "https://" ++ model.site
            in
            case ( model.category, model.frontendLang ) of
                ( Just category, Just frontendLang ) ->
                    ( { model | site = "" }
                    , Effect.fromCmd <| sendToBackend <| RequestSiteStats validSite category frontendLang
                    )

                _ ->
                    ( model, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = "Add Site"
    , body =
        [ Element.layout
            [ width fill
            , paddingXY 20 75
            , height fill
            , htmlAttribute <|
                style "min-height"
                    ("calc(100vh - "
                        ++ fromInt (Styles.navbarHeight + Styles.footerHeight)
                        ++ "px)"
                    )
            ]
          <|
            Element.column [ centerX, centerY, width <| maximum 500 fill ]
                [ Element.column [ spacing 20, width fill ]
                    [ Input.text
                        (Styles.inputStyle ++ [ onEnter SubmitSite ])
                        { onChange = Updated Site
                        , placeholder = Just <| Input.placeholder [] <| Element.text "Website"
                        , text = model.site
                        , label = Input.labelHidden ""
                        }
                    , Styled.dropdownWith Styles.dropdownStyle
                        { label = "Category"
                        , onChange = Updated Category
                        }
                        shared.categories
                    , Styled.dropdownWith Styles.dropdownStyle
                        { label = "Frontend Language"
                        , onChange = Updated FrontendLang
                        }
                        shared.frontendLangs
                    , Styled.submitButtonWith Styles.buttonStyle
                        { label = Element.text "Add Site"
                        , onPress = Just SubmitSite
                        , disabled = model.category == Nothing || model.frontendLang == Nothing
                        }
                    ]
                ]
        ]
    }
