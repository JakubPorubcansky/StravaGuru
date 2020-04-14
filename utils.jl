
zonedDateTime2DateTime(zdt::ZonedDateTime) = DateTime(string(zdt)[1:end-6])

time2Hours(t::Time) = Dates.value(t) / (1000 ^ 3 * 60 * 60)
