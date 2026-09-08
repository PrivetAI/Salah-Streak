import Foundation

// The place list. There is no location permission anywhere in this app and CoreLocation
// is not linked: the user names their city and nothing about the device is read.
//
// Each entry carries an IANA time-zone identifier rather than a fixed UTC offset, so the
// arithmetic is done in the city's own zone and a daylight-saving change is handled by
// the system's tz database rather than by a hard-coded number.

struct SLCity: Identifiable, Equatable {
    let id: Int
    let name: String
    let country: String
    let region: SLRegion
    let latitude: Double
    let longitude: Double
    let timeZoneID: String

    var place: SLPlace {
        SLPlace(latitude: latitude, longitude: longitude, timeZoneID: timeZoneID)
    }

    var displayName: String { "\(name), \(country)" }

    var coordinateLine: String {
        let ns = latitude >= 0 ? "N" : "S"
        let ew = longitude >= 0 ? "E" : "W"
        return String(format: "%.2f\u{00B0} %@  ·  %.2f\u{00B0} %@", abs(latitude), ns, abs(longitude), ew)
    }

    /// Lower-cased haystack for the search field, built once per city at first use.
    var searchKey: String { "\(name) \(country) \(region.title)".lowercased() }
}

enum SLRegion: Int, CaseIterable, Identifiable {
    case arabia = 0
    case levant = 1
    case anatoliaIranCaucasus = 2
    case northAfrica = 3
    case westAfrica = 4
    case eastSouthAfrica = 5
    case southAsia = 6
    case southeastAsia = 7
    case centralEastAsia = 8
    case westernEurope = 9
    case northEastEurope = 10
    case northAmerica = 11
    case latinAmerica = 12
    case oceania = 13

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .arabia: return "Arabian Peninsula and the Gulf"
        case .levant: return "Levant and Iraq"
        case .anatoliaIranCaucasus: return "Turkey, Iran and the Caucasus"
        case .northAfrica: return "North Africa"
        case .westAfrica: return "West and Central Africa"
        case .eastSouthAfrica: return "East and Southern Africa"
        case .southAsia: return "South Asia"
        case .southeastAsia: return "Southeast Asia"
        case .centralEastAsia: return "Central and East Asia"
        case .westernEurope: return "Western Europe"
        case .northEastEurope: return "Northern and Eastern Europe"
        case .northAmerica: return "North America"
        case .latinAmerica: return "Latin America"
        case .oceania: return "Oceania"
        }
    }
}

enum SLCityTable {

    /// Makkah is the fallback for a first launch and for any stored index that no longer
    /// resolves, so no screen is ever blank and no time is ever computed for nowhere.
    static var fallback: SLCity { all[0] }

    static func city(id: Int) -> SLCity {
        guard id >= 0, id < all.count else { return fallback }
        return all[id]
    }

    static var count: Int { all.count }

    static func grouped() -> [(region: SLRegion, cities: [SLCity])] {
        SLRegion.allCases.compactMap { region in
            let cities = all.filter { $0.region == region }.sorted { $0.name < $1.name }
            return cities.isEmpty ? nil : (region: region, cities: cities)
        }
    }

    static func search(_ query: String) -> [SLCity] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return [] }
        return all
            .filter { $0.searchKey.contains(needle) }
            .sorted { lhs, rhs in
                let l = lhs.name.lowercased().hasPrefix(needle)
                let r = rhs.name.lowercased().hasPrefix(needle)
                if l != r { return l }
                return lhs.name < rhs.name
            }
    }

    static let all: [SLCity] = {
        var index = 0
        func c(_ name: String, _ country: String, _ region: SLRegion,
               _ lat: Double, _ lon: Double, _ zone: String) -> SLCity {
            defer { index += 1 }
            return SLCity(id: index, name: name, country: country, region: region,
                          latitude: lat, longitude: lon, timeZoneID: zone)
        }

        return [
            // Arabian Peninsula and the Gulf
            c("Makkah", "Saudi Arabia", .arabia, 21.4225, 39.8262, "Asia/Riyadh"),
            c("Madinah", "Saudi Arabia", .arabia, 24.4686, 39.6142, "Asia/Riyadh"),
            c("Riyadh", "Saudi Arabia", .arabia, 24.7136, 46.6753, "Asia/Riyadh"),
            c("Jeddah", "Saudi Arabia", .arabia, 21.4858, 39.1925, "Asia/Riyadh"),
            c("Dammam", "Saudi Arabia", .arabia, 26.4207, 50.0888, "Asia/Riyadh"),
            c("Taif", "Saudi Arabia", .arabia, 21.2703, 40.4158, "Asia/Riyadh"),
            c("Abha", "Saudi Arabia", .arabia, 18.2465, 42.5117, "Asia/Riyadh"),
            c("Tabuk", "Saudi Arabia", .arabia, 28.3835, 36.5662, "Asia/Riyadh"),
            c("Buraydah", "Saudi Arabia", .arabia, 26.3260, 43.9750, "Asia/Riyadh"),
            c("Dubai", "United Arab Emirates", .arabia, 25.2048, 55.2708, "Asia/Dubai"),
            c("Abu Dhabi", "United Arab Emirates", .arabia, 24.4539, 54.3773, "Asia/Dubai"),
            c("Sharjah", "United Arab Emirates", .arabia, 25.3463, 55.4209, "Asia/Dubai"),
            c("Al Ain", "United Arab Emirates", .arabia, 24.1302, 55.8023, "Asia/Dubai"),
            c("Doha", "Qatar", .arabia, 25.2854, 51.5310, "Asia/Qatar"),
            c("Kuwait City", "Kuwait", .arabia, 29.3759, 47.9774, "Asia/Kuwait"),
            c("Manama", "Bahrain", .arabia, 26.2285, 50.5860, "Asia/Bahrain"),
            c("Muscat", "Oman", .arabia, 23.5880, 58.3829, "Asia/Muscat"),
            c("Salalah", "Oman", .arabia, 17.0151, 54.0924, "Asia/Muscat"),
            c("Sanaa", "Yemen", .arabia, 15.3694, 44.1910, "Asia/Aden"),
            c("Aden", "Yemen", .arabia, 12.7855, 45.0187, "Asia/Aden"),

            // Levant and Iraq
            c("Jerusalem", "Palestine", .levant, 31.7683, 35.2137, "Asia/Jerusalem"),
            c("Gaza", "Palestine", .levant, 31.5017, 34.4668, "Asia/Hebron"),
            c("Hebron", "Palestine", .levant, 31.5326, 35.0998, "Asia/Hebron"),
            c("Amman", "Jordan", .levant, 31.9454, 35.9284, "Asia/Amman"),
            c("Irbid", "Jordan", .levant, 32.5556, 35.8500, "Asia/Amman"),
            c("Beirut", "Lebanon", .levant, 33.8938, 35.5018, "Asia/Beirut"),
            c("Tripoli", "Lebanon", .levant, 34.4367, 35.8497, "Asia/Beirut"),
            c("Damascus", "Syria", .levant, 33.5138, 36.2765, "Asia/Damascus"),
            c("Aleppo", "Syria", .levant, 36.2021, 37.1343, "Asia/Damascus"),
            c("Homs", "Syria", .levant, 34.7324, 36.7137, "Asia/Damascus"),
            c("Baghdad", "Iraq", .levant, 33.3152, 44.3661, "Asia/Baghdad"),
            c("Basra", "Iraq", .levant, 30.5085, 47.7804, "Asia/Baghdad"),
            c("Mosul", "Iraq", .levant, 36.3350, 43.1189, "Asia/Baghdad"),
            c("Erbil", "Iraq", .levant, 36.1901, 44.0091, "Asia/Baghdad"),
            c("Najaf", "Iraq", .levant, 32.0000, 44.3350, "Asia/Baghdad"),

            // Turkey, Iran and the Caucasus
            c("Istanbul", "Turkey", .anatoliaIranCaucasus, 41.0082, 28.9784, "Europe/Istanbul"),
            c("Ankara", "Turkey", .anatoliaIranCaucasus, 39.9334, 32.8597, "Europe/Istanbul"),
            c("Izmir", "Turkey", .anatoliaIranCaucasus, 38.4237, 27.1428, "Europe/Istanbul"),
            c("Bursa", "Turkey", .anatoliaIranCaucasus, 40.1826, 29.0665, "Europe/Istanbul"),
            c("Konya", "Turkey", .anatoliaIranCaucasus, 37.8746, 32.4932, "Europe/Istanbul"),
            c("Gaziantep", "Turkey", .anatoliaIranCaucasus, 37.0662, 37.3833, "Europe/Istanbul"),
            c("Tehran", "Iran", .anatoliaIranCaucasus, 35.6892, 51.3890, "Asia/Tehran"),
            c("Mashhad", "Iran", .anatoliaIranCaucasus, 36.2605, 59.6168, "Asia/Tehran"),
            c("Isfahan", "Iran", .anatoliaIranCaucasus, 32.6539, 51.6660, "Asia/Tehran"),
            c("Tabriz", "Iran", .anatoliaIranCaucasus, 38.0800, 46.2919, "Asia/Tehran"),
            c("Shiraz", "Iran", .anatoliaIranCaucasus, 29.5918, 52.5837, "Asia/Tehran"),
            c("Baku", "Azerbaijan", .anatoliaIranCaucasus, 40.4093, 49.8671, "Asia/Baku"),
            c("Tbilisi", "Georgia", .anatoliaIranCaucasus, 41.7151, 44.8271, "Asia/Tbilisi"),
            c("Yerevan", "Armenia", .anatoliaIranCaucasus, 40.1792, 44.4991, "Asia/Yerevan"),

            // North Africa
            c("Cairo", "Egypt", .northAfrica, 30.0444, 31.2357, "Africa/Cairo"),
            c("Alexandria", "Egypt", .northAfrica, 31.2001, 29.9187, "Africa/Cairo"),
            c("Giza", "Egypt", .northAfrica, 30.0131, 31.2089, "Africa/Cairo"),
            c("Luxor", "Egypt", .northAfrica, 25.6872, 32.6396, "Africa/Cairo"),
            c("Aswan", "Egypt", .northAfrica, 24.0889, 32.8998, "Africa/Cairo"),
            c("Khartoum", "Sudan", .northAfrica, 15.5007, 32.5599, "Africa/Khartoum"),
            c("Port Sudan", "Sudan", .northAfrica, 19.6158, 37.2164, "Africa/Khartoum"),
            c("Tripoli", "Libya", .northAfrica, 32.8872, 13.1913, "Africa/Tripoli"),
            c("Benghazi", "Libya", .northAfrica, 32.1167, 20.0667, "Africa/Tripoli"),
            c("Tunis", "Tunisia", .northAfrica, 36.8065, 10.1815, "Africa/Tunis"),
            c("Sfax", "Tunisia", .northAfrica, 34.7406, 10.7603, "Africa/Tunis"),
            c("Algiers", "Algeria", .northAfrica, 36.7538, 3.0588, "Africa/Algiers"),
            c("Oran", "Algeria", .northAfrica, 35.6976, -0.6337, "Africa/Algiers"),
            c("Constantine", "Algeria", .northAfrica, 36.3650, 6.6147, "Africa/Algiers"),
            c("Casablanca", "Morocco", .northAfrica, 33.5731, -7.5898, "Africa/Casablanca"),
            c("Rabat", "Morocco", .northAfrica, 34.0209, -6.8416, "Africa/Casablanca"),
            c("Marrakesh", "Morocco", .northAfrica, 31.6295, -7.9811, "Africa/Casablanca"),
            c("Fez", "Morocco", .northAfrica, 34.0181, -5.0078, "Africa/Casablanca"),
            c("Tangier", "Morocco", .northAfrica, 35.7595, -5.8340, "Africa/Casablanca"),
            c("Nouakchott", "Mauritania", .northAfrica, 18.0735, -15.9582, "Africa/Nouakchott"),

            // West and Central Africa
            c("Lagos", "Nigeria", .westAfrica, 6.5244, 3.3792, "Africa/Lagos"),
            c("Kano", "Nigeria", .westAfrica, 12.0022, 8.5920, "Africa/Lagos"),
            c("Abuja", "Nigeria", .westAfrica, 9.0765, 7.3986, "Africa/Lagos"),
            c("Ibadan", "Nigeria", .westAfrica, 7.3775, 3.9470, "Africa/Lagos"),
            c("Accra", "Ghana", .westAfrica, 5.6037, -0.1870, "Africa/Accra"),
            c("Dakar", "Senegal", .westAfrica, 14.7167, -17.4677, "Africa/Dakar"),
            c("Touba", "Senegal", .westAfrica, 14.8500, -15.8833, "Africa/Dakar"),
            c("Bamako", "Mali", .westAfrica, 12.6392, -8.0029, "Africa/Bamako"),
            c("Ouagadougou", "Burkina Faso", .westAfrica, 12.3714, -1.5197, "Africa/Ouagadougou"),
            c("Niamey", "Niger", .westAfrica, 13.5116, 2.1254, "Africa/Niamey"),
            c("Conakry", "Guinea", .westAfrica, 9.6412, -13.5784, "Africa/Conakry"),
            c("Abidjan", "Cote d'Ivoire", .westAfrica, 5.3600, -4.0083, "Africa/Abidjan"),
            c("Freetown", "Sierra Leone", .westAfrica, 8.4657, -13.2317, "Africa/Freetown"),
            c("Banjul", "Gambia", .westAfrica, 13.4549, -16.5790, "Africa/Banjul"),
            c("N'Djamena", "Chad", .westAfrica, 12.1348, 15.0557, "Africa/Ndjamena"),
            c("Douala", "Cameroon", .westAfrica, 4.0511, 9.7679, "Africa/Douala"),

            // East and Southern Africa
            c("Nairobi", "Kenya", .eastSouthAfrica, -1.2864, 36.8172, "Africa/Nairobi"),
            c("Mombasa", "Kenya", .eastSouthAfrica, -4.0435, 39.6682, "Africa/Nairobi"),
            c("Addis Ababa", "Ethiopia", .eastSouthAfrica, 9.0300, 38.7400, "Africa/Addis_Ababa"),
            c("Dire Dawa", "Ethiopia", .eastSouthAfrica, 9.5931, 41.8661, "Africa/Addis_Ababa"),
            c("Mogadishu", "Somalia", .eastSouthAfrica, 2.0469, 45.3182, "Africa/Mogadishu"),
            c("Hargeisa", "Somalia", .eastSouthAfrica, 9.5600, 44.0650, "Africa/Mogadishu"),
            c("Djibouti", "Djibouti", .eastSouthAfrica, 11.5721, 43.1456, "Africa/Djibouti"),
            c("Dar es Salaam", "Tanzania", .eastSouthAfrica, -6.7924, 39.2083, "Africa/Dar_es_Salaam"),
            c("Zanzibar City", "Tanzania", .eastSouthAfrica, -6.1659, 39.2026, "Africa/Dar_es_Salaam"),
            c("Kampala", "Uganda", .eastSouthAfrica, 0.3476, 32.5825, "Africa/Kampala"),
            c("Johannesburg", "South Africa", .eastSouthAfrica, -26.2041, 28.0473, "Africa/Johannesburg"),
            c("Cape Town", "South Africa", .eastSouthAfrica, -33.9249, 18.4241, "Africa/Johannesburg"),
            c("Durban", "South Africa", .eastSouthAfrica, -29.8587, 31.0218, "Africa/Johannesburg"),
            c("Antananarivo", "Madagascar", .eastSouthAfrica, -18.8792, 47.5079, "Indian/Antananarivo"),

            // South Asia
            c("Karachi", "Pakistan", .southAsia, 24.8607, 67.0011, "Asia/Karachi"),
            c("Lahore", "Pakistan", .southAsia, 31.5204, 74.3587, "Asia/Karachi"),
            c("Islamabad", "Pakistan", .southAsia, 33.6844, 73.0479, "Asia/Karachi"),
            c("Faisalabad", "Pakistan", .southAsia, 31.4180, 73.0790, "Asia/Karachi"),
            c("Peshawar", "Pakistan", .southAsia, 34.0151, 71.5249, "Asia/Karachi"),
            c("Quetta", "Pakistan", .southAsia, 30.1798, 66.9750, "Asia/Karachi"),
            c("Multan", "Pakistan", .southAsia, 30.1575, 71.5249, "Asia/Karachi"),
            c("Delhi", "India", .southAsia, 28.6139, 77.2090, "Asia/Kolkata"),
            c("Mumbai", "India", .southAsia, 19.0760, 72.8777, "Asia/Kolkata"),
            c("Hyderabad", "India", .southAsia, 17.3850, 78.4867, "Asia/Kolkata"),
            c("Kolkata", "India", .southAsia, 22.5726, 88.3639, "Asia/Kolkata"),
            c("Chennai", "India", .southAsia, 13.0827, 80.2707, "Asia/Kolkata"),
            c("Bengaluru", "India", .southAsia, 12.9716, 77.5946, "Asia/Kolkata"),
            c("Lucknow", "India", .southAsia, 26.8467, 80.9462, "Asia/Kolkata"),
            c("Ahmedabad", "India", .southAsia, 23.0225, 72.5714, "Asia/Kolkata"),
            c("Srinagar", "India", .southAsia, 34.0837, 74.7973, "Asia/Kolkata"),
            c("Dhaka", "Bangladesh", .southAsia, 23.8103, 90.4125, "Asia/Dhaka"),
            c("Chattogram", "Bangladesh", .southAsia, 22.3569, 91.7832, "Asia/Dhaka"),
            c("Sylhet", "Bangladesh", .southAsia, 24.8949, 91.8687, "Asia/Dhaka"),
            c("Khulna", "Bangladesh", .southAsia, 22.8456, 89.5403, "Asia/Dhaka"),
            c("Colombo", "Sri Lanka", .southAsia, 6.9271, 79.8612, "Asia/Colombo"),
            c("Male", "Maldives", .southAsia, 4.1755, 73.5093, "Indian/Maldives"),
            c("Kabul", "Afghanistan", .southAsia, 34.5553, 69.2075, "Asia/Kabul"),
            c("Herat", "Afghanistan", .southAsia, 34.3529, 62.2040, "Asia/Kabul"),
            c("Kathmandu", "Nepal", .southAsia, 27.7172, 85.3240, "Asia/Kathmandu"),

            // Southeast Asia
            c("Jakarta", "Indonesia", .southeastAsia, -6.2088, 106.8456, "Asia/Jakarta"),
            c("Surabaya", "Indonesia", .southeastAsia, -7.2575, 112.7521, "Asia/Jakarta"),
            c("Bandung", "Indonesia", .southeastAsia, -6.9175, 107.6191, "Asia/Jakarta"),
            c("Medan", "Indonesia", .southeastAsia, 3.5952, 98.6722, "Asia/Jakarta"),
            c("Semarang", "Indonesia", .southeastAsia, -6.9932, 110.4203, "Asia/Jakarta"),
            c("Makassar", "Indonesia", .southeastAsia, -5.1477, 119.4327, "Asia/Makassar"),
            c("Banda Aceh", "Indonesia", .southeastAsia, 5.5483, 95.3238, "Asia/Jakarta"),
            c("Kuala Lumpur", "Malaysia", .southeastAsia, 3.1390, 101.6869, "Asia/Kuala_Lumpur"),
            c("Johor Bahru", "Malaysia", .southeastAsia, 1.4927, 103.7414, "Asia/Kuala_Lumpur"),
            c("George Town", "Malaysia", .southeastAsia, 5.4141, 100.3288, "Asia/Kuala_Lumpur"),
            c("Kota Bharu", "Malaysia", .southeastAsia, 6.1248, 102.2381, "Asia/Kuala_Lumpur"),
            c("Kuching", "Malaysia", .southeastAsia, 1.5533, 110.3592, "Asia/Kuching"),
            c("Singapore", "Singapore", .southeastAsia, 1.3521, 103.8198, "Asia/Singapore"),
            c("Bandar Seri Begawan", "Brunei", .southeastAsia, 4.9031, 114.9398, "Asia/Brunei"),
            c("Manila", "Philippines", .southeastAsia, 14.5995, 120.9842, "Asia/Manila"),
            c("Davao City", "Philippines", .southeastAsia, 7.1907, 125.4553, "Asia/Manila"),
            c("Bangkok", "Thailand", .southeastAsia, 13.7563, 100.5018, "Asia/Bangkok"),
            c("Hat Yai", "Thailand", .southeastAsia, 7.0086, 100.4747, "Asia/Bangkok"),
            c("Ho Chi Minh City", "Vietnam", .southeastAsia, 10.8231, 106.6297, "Asia/Ho_Chi_Minh"),
            c("Phnom Penh", "Cambodia", .southeastAsia, 11.5564, 104.9282, "Asia/Phnom_Penh"),
            c("Yangon", "Myanmar", .southeastAsia, 16.8409, 96.1735, "Asia/Yangon"),

            // Central and East Asia
            c("Tashkent", "Uzbekistan", .centralEastAsia, 41.2995, 69.2401, "Asia/Tashkent"),
            c("Samarkand", "Uzbekistan", .centralEastAsia, 39.6270, 66.9750, "Asia/Samarkand"),
            c("Bukhara", "Uzbekistan", .centralEastAsia, 39.7747, 64.4286, "Asia/Samarkand"),
            c("Almaty", "Kazakhstan", .centralEastAsia, 43.2220, 76.8512, "Asia/Almaty"),
            c("Astana", "Kazakhstan", .centralEastAsia, 51.1694, 71.4491, "Asia/Almaty"),
            c("Bishkek", "Kyrgyzstan", .centralEastAsia, 42.8746, 74.5698, "Asia/Bishkek"),
            c("Dushanbe", "Tajikistan", .centralEastAsia, 38.5598, 68.7870, "Asia/Dushanbe"),
            c("Ashgabat", "Turkmenistan", .centralEastAsia, 37.9601, 58.3261, "Asia/Ashgabat"),
            c("Urumqi", "China", .centralEastAsia, 43.8256, 87.6168, "Asia/Shanghai"),
            c("Kashgar", "China", .centralEastAsia, 39.4704, 75.9898, "Asia/Shanghai"),
            c("Beijing", "China", .centralEastAsia, 39.9042, 116.4074, "Asia/Shanghai"),
            c("Hong Kong", "China", .centralEastAsia, 22.3193, 114.1694, "Asia/Hong_Kong"),
            c("Tokyo", "Japan", .centralEastAsia, 35.6762, 139.6503, "Asia/Tokyo"),
            c("Seoul", "South Korea", .centralEastAsia, 37.5665, 126.9780, "Asia/Seoul"),
            c("Ulaanbaatar", "Mongolia", .centralEastAsia, 47.8864, 106.9057, "Asia/Ulaanbaatar"),

            // Western Europe
            c("London", "United Kingdom", .westernEurope, 51.5074, -0.1278, "Europe/London"),
            c("Birmingham", "United Kingdom", .westernEurope, 52.4862, -1.8904, "Europe/London"),
            c("Manchester", "United Kingdom", .westernEurope, 53.4808, -2.2426, "Europe/London"),
            c("Leeds", "United Kingdom", .westernEurope, 53.8008, -1.5491, "Europe/London"),
            c("Bradford", "United Kingdom", .westernEurope, 53.7960, -1.7594, "Europe/London"),
            c("Glasgow", "United Kingdom", .westernEurope, 55.8642, -4.2518, "Europe/London"),
            c("Dublin", "Ireland", .westernEurope, 53.3498, -6.2603, "Europe/Dublin"),
            c("Paris", "France", .westernEurope, 48.8566, 2.3522, "Europe/Paris"),
            c("Marseille", "France", .westernEurope, 43.2965, 5.3698, "Europe/Paris"),
            c("Lyon", "France", .westernEurope, 45.7640, 4.8357, "Europe/Paris"),
            c("Toulouse", "France", .westernEurope, 43.6047, 1.4442, "Europe/Paris"),
            c("Brussels", "Belgium", .westernEurope, 50.8503, 4.3517, "Europe/Brussels"),
            c("Antwerp", "Belgium", .westernEurope, 51.2194, 4.4025, "Europe/Brussels"),
            c("Amsterdam", "Netherlands", .westernEurope, 52.3676, 4.9041, "Europe/Amsterdam"),
            c("Rotterdam", "Netherlands", .westernEurope, 51.9244, 4.4777, "Europe/Amsterdam"),
            c("The Hague", "Netherlands", .westernEurope, 52.0705, 4.3007, "Europe/Amsterdam"),
            c("Berlin", "Germany", .westernEurope, 52.5200, 13.4050, "Europe/Berlin"),
            c("Hamburg", "Germany", .westernEurope, 53.5511, 9.9937, "Europe/Berlin"),
            c("Munich", "Germany", .westernEurope, 48.1351, 11.5820, "Europe/Berlin"),
            c("Cologne", "Germany", .westernEurope, 50.9375, 6.9603, "Europe/Berlin"),
            c("Frankfurt", "Germany", .westernEurope, 50.1109, 8.6821, "Europe/Berlin"),
            c("Stuttgart", "Germany", .westernEurope, 48.7758, 9.1829, "Europe/Berlin"),
            c("Vienna", "Austria", .westernEurope, 48.2082, 16.3738, "Europe/Vienna"),
            c("Zurich", "Switzerland", .westernEurope, 47.3769, 8.5417, "Europe/Zurich"),
            c("Geneva", "Switzerland", .westernEurope, 46.2044, 6.1432, "Europe/Zurich"),
            c("Madrid", "Spain", .westernEurope, 40.4168, -3.7038, "Europe/Madrid"),
            c("Barcelona", "Spain", .westernEurope, 41.3874, 2.1686, "Europe/Madrid"),
            c("Granada", "Spain", .westernEurope, 37.1773, -3.5986, "Europe/Madrid"),
            c("Lisbon", "Portugal", .westernEurope, 38.7223, -9.1393, "Europe/Lisbon"),
            c("Rome", "Italy", .westernEurope, 41.9028, 12.4964, "Europe/Rome"),
            c("Milan", "Italy", .westernEurope, 45.4642, 9.1900, "Europe/Rome"),
            c("Naples", "Italy", .westernEurope, 40.8518, 14.2681, "Europe/Rome"),

            // Northern and Eastern Europe
            c("Stockholm", "Sweden", .northEastEurope, 59.3293, 18.0686, "Europe/Stockholm"),
            c("Gothenburg", "Sweden", .northEastEurope, 57.7089, 11.9746, "Europe/Stockholm"),
            c("Malmo", "Sweden", .northEastEurope, 55.6050, 13.0038, "Europe/Stockholm"),
            c("Oslo", "Norway", .northEastEurope, 59.9139, 10.7522, "Europe/Oslo"),
            c("Tromso", "Norway", .northEastEurope, 69.6492, 18.9553, "Europe/Oslo"),
            c("Copenhagen", "Denmark", .northEastEurope, 55.6761, 12.5683, "Europe/Copenhagen"),
            c("Helsinki", "Finland", .northEastEurope, 60.1699, 24.9384, "Europe/Helsinki"),
            c("Reykjavik", "Iceland", .northEastEurope, 64.1466, -21.9426, "Atlantic/Reykjavik"),
            c("Moscow", "Russia", .northEastEurope, 55.7558, 37.6173, "Europe/Moscow"),
            c("Saint Petersburg", "Russia", .northEastEurope, 59.9311, 30.3609, "Europe/Moscow"),
            c("Kazan", "Russia", .northEastEurope, 55.7963, 49.1088, "Europe/Moscow"),
            c("Makhachkala", "Russia", .northEastEurope, 42.9849, 47.5047, "Europe/Moscow"),
            c("Ufa", "Russia", .northEastEurope, 54.7388, 55.9721, "Asia/Yekaterinburg"),
            c("Kyiv", "Ukraine", .northEastEurope, 50.4501, 30.5234, "Europe/Kiev"),
            c("Warsaw", "Poland", .northEastEurope, 52.2297, 21.0122, "Europe/Warsaw"),
            c("Prague", "Czechia", .northEastEurope, 50.0755, 14.4378, "Europe/Prague"),
            c("Budapest", "Hungary", .northEastEurope, 47.4979, 19.0402, "Europe/Budapest"),
            c("Bucharest", "Romania", .northEastEurope, 44.4268, 26.1025, "Europe/Bucharest"),
            c("Sofia", "Bulgaria", .northEastEurope, 42.6977, 23.3219, "Europe/Sofia"),
            c("Sarajevo", "Bosnia and Herzegovina", .northEastEurope, 43.8563, 18.4131, "Europe/Sarajevo"),
            c("Pristina", "Kosovo", .northEastEurope, 42.6629, 21.1655, "Europe/Belgrade"),
            c("Skopje", "North Macedonia", .northEastEurope, 41.9981, 21.4254, "Europe/Skopje"),
            c("Tirana", "Albania", .northEastEurope, 41.3275, 19.8187, "Europe/Tirane"),
            c("Athens", "Greece", .northEastEurope, 37.9838, 23.7275, "Europe/Athens"),

            // North America
            c("New York", "United States", .northAmerica, 40.7128, -74.0060, "America/New_York"),
            c("Newark", "United States", .northAmerica, 40.7357, -74.1724, "America/New_York"),
            c("Philadelphia", "United States", .northAmerica, 39.9526, -75.1652, "America/New_York"),
            c("Washington", "United States", .northAmerica, 38.9072, -77.0369, "America/New_York"),
            c("Boston", "United States", .northAmerica, 42.3601, -71.0589, "America/New_York"),
            c("Atlanta", "United States", .northAmerica, 33.7490, -84.3880, "America/New_York"),
            c("Miami", "United States", .northAmerica, 25.7617, -80.1918, "America/New_York"),
            c("Detroit", "United States", .northAmerica, 42.3314, -83.0458, "America/Detroit"),
            c("Dearborn", "United States", .northAmerica, 42.3223, -83.1763, "America/Detroit"),
            c("Chicago", "United States", .northAmerica, 41.8781, -87.6298, "America/Chicago"),
            c("Houston", "United States", .northAmerica, 29.7604, -95.3698, "America/Chicago"),
            c("Dallas", "United States", .northAmerica, 32.7767, -96.7970, "America/Chicago"),
            c("Minneapolis", "United States", .northAmerica, 44.9778, -93.2650, "America/Chicago"),
            c("Denver", "United States", .northAmerica, 39.7392, -104.9903, "America/Denver"),
            c("Phoenix", "United States", .northAmerica, 33.4484, -112.0740, "America/Phoenix"),
            c("Los Angeles", "United States", .northAmerica, 34.0522, -118.2437, "America/Los_Angeles"),
            c("San Diego", "United States", .northAmerica, 32.7157, -117.1611, "America/Los_Angeles"),
            c("San Francisco", "United States", .northAmerica, 37.7749, -122.4194, "America/Los_Angeles"),
            c("Seattle", "United States", .northAmerica, 47.6062, -122.3321, "America/Los_Angeles"),
            c("Toronto", "Canada", .northAmerica, 43.6532, -79.3832, "America/Toronto"),
            c("Ottawa", "Canada", .northAmerica, 45.4215, -75.6972, "America/Toronto"),
            c("Montreal", "Canada", .northAmerica, 45.5017, -73.5673, "America/Toronto"),
            c("Calgary", "Canada", .northAmerica, 51.0447, -114.0719, "America/Edmonton"),
            c("Edmonton", "Canada", .northAmerica, 53.5461, -113.4938, "America/Edmonton"),
            c("Vancouver", "Canada", .northAmerica, 49.2827, -123.1207, "America/Vancouver"),
            c("Mexico City", "Mexico", .northAmerica, 19.4326, -99.1332, "America/Mexico_City"),

            // Latin America
            c("Bogota", "Colombia", .latinAmerica, 4.7110, -74.0721, "America/Bogota"),
            c("Lima", "Peru", .latinAmerica, -12.0464, -77.0428, "America/Lima"),
            c("Santiago", "Chile", .latinAmerica, -33.4489, -70.6693, "America/Santiago"),
            c("Buenos Aires", "Argentina", .latinAmerica, -34.6037, -58.3816, "America/Argentina/Buenos_Aires"),
            c("Sao Paulo", "Brazil", .latinAmerica, -23.5505, -46.6333, "America/Sao_Paulo"),
            c("Rio de Janeiro", "Brazil", .latinAmerica, -22.9068, -43.1729, "America/Sao_Paulo"),
            c("Paramaribo", "Suriname", .latinAmerica, 5.8520, -55.2038, "America/Paramaribo"),
            c("Georgetown", "Guyana", .latinAmerica, 6.8013, -58.1551, "America/Guyana"),
            c("Port of Spain", "Trinidad and Tobago", .latinAmerica, 10.6596, -61.5089, "America/Port_of_Spain"),

            // Oceania
            c("Sydney", "Australia", .oceania, -33.8688, 151.2093, "Australia/Sydney"),
            c("Melbourne", "Australia", .oceania, -37.8136, 144.9631, "Australia/Melbourne"),
            c("Brisbane", "Australia", .oceania, -27.4698, 153.0251, "Australia/Brisbane"),
            c("Perth", "Australia", .oceania, -31.9505, 115.8605, "Australia/Perth"),
            c("Adelaide", "Australia", .oceania, -34.9285, 138.6007, "Australia/Adelaide"),
            c("Auckland", "New Zealand", .oceania, -36.8485, 174.7633, "Pacific/Auckland"),
            c("Suva", "Fiji", .oceania, -18.1248, 178.4501, "Pacific/Fiji")
        ]
    }()
}
