
function plotEfforts(efforts::Vector{Any}, address::String, timeZone::String)
    D = Dict{String, Dict}()

    for eff in efforts
        startDateTime = DateTime(eff["start_date_local"][1:end-1])
        elapsedSeconds = eff["elapsed_time"]

        if !haskey(D, eff["name"])
            D[eff["name"]] = Dict()
            D[eff["name"]]["x"] = Array{Date, 2}(undef, 2, 0)
            D[eff["name"]]["y"] = Array{Float64, 2}(undef, 2, 0)
        end

        D[eff["name"]]["x"] = hcat(D[eff["name"]]["x"], [Date(startDateTime), Date(startDateTime)])
        D[eff["name"]]["y"] = hcat(D[eff["name"]]["y"], Dates.value.([Time(startDateTime), Time(startDateTime) + Dates.Second(elapsedSeconds)]) / (1000 ^ 3 * 60 * 60))
    end

    coordinates = getCoordinates(address)

    plotEfforts(D, coordinates[1], coordinates[2], timeZone);
end

function plotEfforts(D::Dict{String, Dict}, lat::Float64, lon::Float64, timeZone::String)
    p = plot([], ticks = :native, xgrid = false, label = "", ylim = [0, 24], yticks = 0:1:24)
    for (i, (key, val)) in enumerate(D)
        col = RGB(0.8 * rand() + 0.2, 0.8 * rand() + 0.2, 0.8 * rand() + 0.2)
        plot!(p, val["x"][:, 1], val["y"][:, 1], c = col, label = key, hover = false, linewidth = 2)
        plot!(p, val["x"][:, 2:end], val["y"][:, 2:end], c = col, label = "", hover = false, linewidth = 2)
    end

    dateMin = mapreduce(x -> minimum(x[2]["x"]), min, D)
    dateMax = mapreduce(x -> maximum(x[2]["x"]), max, D)

    for dt in dateMin - Dates.Day(14):Dates.Day(1):dateMax + Dates.Day(14)
        if Dates.issaturday(dt)
            srss = getSunriseSunset(lat, lon, dt, timeZone)

            # plot sunrise / sunset
            plotRectangle!(p, Dates.value(dt - Dates.Day(3)), Dates.value(dt + Dates.Day(4)),
                time2Hours(Time("00:00:00")), time2Hours(Time(srss["nautical_twilight_begin"])); opacity = .5)
            plotRectangle!(p, Dates.value(dt - Dates.Day(3)), Dates.value(dt + Dates.Day(4)),
                time2Hours(Time(srss["nautical_twilight_begin"])), time2Hours(Time(srss["civil_twilight_begin"])); opacity = .3)
            plotRectangle!(p, Dates.value(dt - Dates.Day(3)), Dates.value(dt + Dates.Day(4)),
                time2Hours(Time(srss["civil_twilight_begin"])), time2Hours(Time(srss["sunrise"])); opacity = .15)
            plotRectangle!(p, Dates.value(dt - Dates.Day(3)), Dates.value(dt + Dates.Day(4)),
                time2Hours(Time(srss["sunset"])), time2Hours(Time(srss["civil_twilight_end"])); opacity = .15)
            plotRectangle!(p, Dates.value(dt - Dates.Day(3)), Dates.value(dt + Dates.Day(4)),
                time2Hours(Time(srss["civil_twilight_end"])), time2Hours(Time(srss["nautical_twilight_end"])); opacity = .3)
            plotRectangle!(p, Dates.value(dt - Dates.Day(3)), Dates.value(dt + Dates.Day(4)),
                time2Hours(Time(srss["nautical_twilight_end"])), time2Hours(Time("23:59:59")); opacity = .5)

            # plot weekends
            plotRectangle!(p, Dates.value(dt), Dates.value(dt + Dates.Day(2)),
                time2Hours(Time("00:00:00")), time2Hours(Time("23:59:59")); opacity = .1, color = "brown")
        end
    end

    p
end

function plotRectangle!(p::Plots.Plot, x1::Real, x2::Real, y1::Real, y2::Real; opacity::Float64 = 1.0, color::String = "grey")
    plot!(p, Shape([x1, x2, x2, x1], [y1, y1, y2, y2]), c = color, label = "", opacity = opacity, lineopacity = .0)
end
