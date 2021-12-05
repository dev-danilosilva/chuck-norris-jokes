module Main exposing (..)

import Browser
import Html exposing ( Html
                     , text
                     , div
                     , img
                     , a
                     , button
                     )
import Html.Attributes exposing (class
                                , src
                                , href
                                )
import Html.Events exposing (onClick)
import Http
import Json.Decode
import Array exposing (Array)

main : Program Json.Decode.Value Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

type alias Model =
    { jokeApiConfig    : ApiConfig
    , joke            : Maybe ChuckJoke
    , gifApiConfig     : ApiConfig
    , gifSet          : Array String
    , gifSetMaxLength : Int
    , imageIndex      : Int
    }

type Msg
    = FetchJoke
    | GotGifSet  (Result Http.Error (Array String))
    | GotJoke    (Result Http.Error ChuckJoke)

type alias Flags =
    { jokeApi : ApiConfig
    , gifApi  : ApiConfig
    , gifSetMaxLength : Int
    }

type alias ApiConfig =
    { baseUrl : String
    , apiKey : String
    }

type alias ChuckJoke =
    { text : String
    , url : String
    }

subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none

init : Json.Decode.Value -> (Model, Cmd Msg)
init flags =
    case Json.Decode.decodeValue flagsDecoder flags of
        Ok decodedFlags ->
            ( { jokeApiConfig    = decodedFlags.jokeApi
                , joke            = Nothing
                , gifApiConfig     = decodedFlags.gifApi
                , gifSet          = Array.empty
                , gifSetMaxLength = decodedFlags.gifSetMaxLength
                , imageIndex      = 0
                }
            , Cmd.batch
                [ fetchRandomJoke decodedFlags.jokeApi
                , fetchGifSet decodedFlags.gifSetMaxLength decodedFlags.gifApi
                ]
            )
        Err _ ->
            ({ jokeApiConfig   = ApiConfig "" ""
            , joke            = Nothing
            , gifApiConfig     = ApiConfig "" ""
            , gifSet          = Array.empty
            , gifSetMaxLength = 10
            , imageIndex      = 0
            }
            ,Cmd.none
            )

update : Msg -> Model ->  ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchJoke ->
            ( model
            , fetchRandomJoke model.jokeApiConfig
            )
        GotJoke result ->
            case result of
                Ok joke ->
                    ({model | joke = Just joke, imageIndex = modBy model.gifSetMaxLength (model.imageIndex + 1)}
                    , Cmd.none)
                Err _ ->
                    ({ model | joke = Nothing}
                     , Cmd.none
                    )
        GotGifSet result ->
            case result of
                Ok gifSet ->
                    ({model | gifSet = gifSet}, Cmd.none)
                Err _ ->
                    (model, Cmd.none)

view : Model -> Html Msg
view model =
    div [class "container"]
        [ img [class "joke_img"
              , src <| Maybe.withDefault "" <| Array.get model.imageIndex model.gifSet
              ]
              []
        , div [class "chuck_joke"]
              [ a [href "https://api.chucknorris.io/jokes/uojt-t8as5ws5h1q-sjslw"]
                  [text <| case model.joke of
                            Just joke ->
                                joke.text
                            Nothing ->
                                "No joke to show"]
              ]
        , button [ class "random_joke_button"
                 , onClick FetchJoke]
                 [text "Random Joke"]
        ]

-- Http

randomJokeEndpoint : ApiConfig -> String
randomJokeEndpoint apiConfig = apiConfig.baseUrl ++ "/jokes/random"

gifSetEndpoint : Int -> ApiConfig -> String
gifSetEndpoint limit apiConfig = apiConfig.baseUrl ++ "/search?q=chuck%20norris&key=" ++ apiConfig.apiKey  ++ "&limit=" ++ String.fromInt limit

fetchRandomJoke : ApiConfig -> Cmd Msg
fetchRandomJoke apiConfig =
    Http.get
        { url = randomJokeEndpoint apiConfig
        , expect = Http.expectJson GotJoke chuckJokeDecoder
        }

fetchGifSet : Int -> ApiConfig -> Cmd Msg
fetchGifSet limit apiConfig =
    Http.get
        { url = gifSetEndpoint limit apiConfig
        , expect = Http.expectJson GotGifSet gifSetDecoder
        }

-- Decoders

flagsDecoder : Json.Decode.Decoder Flags
flagsDecoder =
    Json.Decode.map3
        Flags
        (Json.Decode.field "joke_api" apiConfigDecoder)
        (Json.Decode.field "gif_api" apiConfigDecoder)
        (Json.Decode.field "gif_set_max_length" Json.Decode.int)

apiConfigDecoder : Json.Decode.Decoder ApiConfig
apiConfigDecoder =
    Json.Decode.map2
        ApiConfig
        (Json.Decode.field "base_url" Json.Decode.string)
        (Json.Decode.field "api_key"  Json.Decode.string)

gifSetDecoder : Json.Decode.Decoder (Array String)
gifSetDecoder =
    Json.Decode.field "results"
                     (Json.Decode.array
                       <| Json.Decode.field "media"
                       <| Json.Decode.index 0
                       <| Json.Decode.at ["tinygif", "url"]
                       <| Json.Decode.string)

chuckJokeDecoder : Json.Decode.Decoder ChuckJoke
chuckJokeDecoder =
    Json.Decode.map2
        ChuckJoke
        (Json.Decode.field "value"    Json.Decode.string)
        (Json.Decode.field "url"      Json.Decode.string)