# module StravaGuru
#     using HTTP, JSON, Plots, Dates, TimeZones
#
#     include("requests.jl")
# end


# https://yizeng.me/2017/01/11/get-a-strava-api-access-token-with-write-permission/
# r = HTTP.request("GET", "https://www.strava.com/oauth/authorize?client_id=44198&response_type=code&redirect_uri=http://localhost/exchange_token&approval_prompt=force&scope=read_all,activity:read_all")


using HTTP, JSON, Plots, Dates, TimeZones

include("config.jl")
include("definitions.jl")
include("requests.jl")
include("plotting.jl")
include("utils.jl")

code = "146e961350429cbb65d088fc1c2d3a8009c5bdf9"

access = getAccessUsingCode(cliendId, clientSecret, code)
access = getAccessUsingToken(cliendId, clientSecret, access["refresh_token"])

athlete = getAthleteInfo(access["access_token"])

starredSegments = getAllStarredSegments(access["access_token"])

efforts = getSegmentEfforts(starredSegments, access["access_token"])

activities = getAllActivities(access["access_token"])

plotly(size = (1200, 600))
p = plotEfforts(activities, "Bratislava", "Europe/Bratislava");
gui()
