module DataTransfer exposing (elmFileDecoder, toFileType)

import File exposing (File)
import Json.Decode as Json exposing (Decoder)


type FileType
    = Image File
    | FarmUrl File
    | DocumentUrl File
    | File File


toFileType : File -> FileType
toFileType file =
    case String.split "/" (File.mime file) of
        ["image", _] ->
            Image file
        ["application", "farm-url"] ->
            FarmUrl file
        ["application", "hypermerge-url"] ->
            DocumentUrl file
        _ ->
            File file
        


elmFileDecoder : Decoder (List File)
elmFileDecoder =
    Json.field "elmFiles" (Json.list File.decoder)