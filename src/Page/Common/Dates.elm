module Page.Common.Dates exposing (formatStringDate, formatStringDatetime, posixToDate)

import Time


formatStringDate : String -> String
formatStringDate date =
    -- Very naive way to display only the date of the day given a date in the format "2019-04-05T12:56:54.424Z"
    String.left 10 date


formatStringDatetime : String -> String
formatStringDatetime date =
    -- Very naive way to display the date and time of the day given a date in the format "2019-04-05T12:56:54.424Z"
    String.left 19 date
        |> String.replace "T" " "


posixToDate : Time.Zone -> Time.Posix -> String
posixToDate timezone posix =
    let
        year =
            String.fromInt <| Time.toYear timezone posix

        month =
            case Time.toMonth timezone posix of
                Time.Jan ->
                    "01"

                Time.Feb ->
                    "02"

                Time.Mar ->
                    "03"

                Time.Apr ->
                    "04"

                Time.May ->
                    "05"

                Time.Jun ->
                    "06"

                Time.Jul ->
                    "07"

                Time.Aug ->
                    "08"

                Time.Sep ->
                    "09"

                Time.Oct ->
                    "10"

                Time.Nov ->
                    "11"

                Time.Dec ->
                    "12"

        day =
            Time.toDay timezone posix
                |> String.fromInt
                |> (\str ->
                        if String.length str < 2 then
                            "0" ++ str

                        else
                            str
                   )
    in
    year ++ "-" ++ month ++ "-" ++ day
