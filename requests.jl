
function getAccessUsingCode(clientId::Int64, clientSecret::String, code::String)
    q = Dict(:client_id => clientId,
             :client_secret => clientSecret,
             :grant_type => "authorization_code",
             :code => code)
    getAccess(clientId, clientSecret, q)
end

function getAccessUsingToken(clientId::Int64, clientSecret::String, refreshToken::String)
    q = Dict(:client_id => clientId,
             :client_secret => clientSecret,
             :grant_type => "refresh_token",
             :refresh_token => refreshToken)
    getAccess(clientId, clientSecret, q)
end

function getAccess(clientId::Int64, clientSecret::String, query::Dict)
    r = HTTP.request("POST", "https://www.strava.com/api/v3/oauth/token"; query = query)
    JSON.parse(String(r.body))
end

function getAthleteInfo(accessToken::String)
    r = HTTP.request("GET", "https://www.strava.com/api/v3/athlete"; query = Dict(:access_token => accessToken))
    JSON.parse(String(r.body))
end

function getAllStarredSegments(accessToken::String)
    r = HTTP.request("GET", "https://www.strava.com/api/v3/segments/starred"; query = Dict(:access_token => accessToken))
    JSON.parse(String(r.body))
end

function getSegmentEfforts(segments::Vector{Any}, accessToken::String)
    efforts = []
    for segment in segments
        append!(efforts, getSegmentEfforts(accessToken, segment["id"]))
    end
    efforts
end

function getSegmentEfforts(segmentId::Int64, accessToken::String)
    r = HTTP.request("GET", "https://www.strava.com/api/v3/segments/$segmentId/all_efforts/"; query = Dict(:access_token => accessToken, :per_page => 120))
    JSON.parse(String(r.body))
end

function getAllActivities(accessToken::String)
    activities = []
    page = 1
    while true
        a = getActivities(page, accessToken)
        isempty(a) && break

        append!(activities, a)

        page += 1
    end
    activities
end

function getActivities(page::Int64, accessToken::String)
    r = HTTP.request("GET", "https://www.strava.com/api/v3/athlete/activities"; query = Dict(:access_token => accessToken, :page => page))
    JSON.parse(String(r.body))
end

function getCoordinates(address::String)
    r = HTTP.request("GET", "https://geocode.xyz/$(address)?json=1")
    rbody = JSON.parse(String(r.body))

    (rbody["latt"] == "0.00000" && rbody["longt"] == "0.00000") && throw("can't find coordinates for $(address)")

    parse.(Float64, (rbody["latt"], rbody["longt"]))
end

function getSunriseSunset(lat::Float64, lon::Float64, date::Date, timeZone::String)
    if (lat > 90 || lat < -90)
        lat = 48.16369
        @warn("Latitude out of limits. Setting to $lat.")
    end
    if (lon > 180 || lon < -180)
        lon = 17.11894
        @warn("Longitude out of limits. Setting to $lon.")
    end

    r = HTTP.request("GET", "https://api.sunrise-sunset.org/json?lat=$lat&lng=$lon&date=$date&formatted=0")
    rbody = JSON.parse(String(r.body))["results"]

    for (key, val) in rbody
        key == "day_length" && continue
        rbody[key] = zonedDateTime2DateTime(astimezone(ZonedDateTime(val, "yyyy-mm-ddTHH:MM:SSzzzz"), TimeZone(timeZone)))
    end
    rbody
end
