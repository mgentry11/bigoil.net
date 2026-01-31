//
//  ThemeManager.swift
//  HITCoachPro
//
//  Manages color themes for the app
//

import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    // Featured themes
    case gadfly = "gadfly"
    case `default` = "default"
    case emerald = "emerald"
    case orange = "orange"
    case gold = "gold"
    case ocean = "ocean"
    case slate = "slate"
    case rose = "rose"

    // Extended themes
    case crimson = "crimson"
    case bronze = "bronze"
    case sunset = "sunset"
    case olive = "olive"
    case steel = "steel"
    case charcoal = "charcoal"
    case maroon = "maroon"
    case atom = "atom"
    case aubergine = "aubergine"
    case forest = "forest"
    case onyx = "onyx"
    case cyan = "cyan"
    case coral = "coral"
    case nord = "nord"
    case navy = "navy"
    case amber = "amber"
    case midnight = "midnight"
    case matrix = "matrix"
    case lemon = "lemon"
    case cobalt = "cobalt"
    case silver = "silver"
    case tropical = "tropical"
    case arctic = "arctic"
    case blush = "blush"
    case sunflower = "sunflower"
    case cream = "cream"
    case cloud = "cloud"
    case royal = "royal"
    case lavender = "lavender"
    case electric = "electric"
    case tangerine = "tangerine"
    case pastel = "pastel"
    case neon = "neon"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gadfly: return "Gadfly"
        case .default: return "Default"
        case .emerald: return "Emerald"
        case .orange: return "Ember"
        case .gold: return "Gold"
        case .ocean: return "Ocean"
        case .slate: return "Slate"
        case .rose: return "Rose"
        case .crimson: return "Crimson"
        case .bronze: return "Bronze"
        case .sunset: return "Sunset"
        case .olive: return "Olive"
        case .steel: return "Steel"
        case .charcoal: return "Charcoal"
        case .maroon: return "Maroon"
        case .atom: return "Atom"
        case .aubergine: return "Aubergine"
        case .forest: return "Forest"
        case .onyx: return "Onyx"
        case .cyan: return "Cyan"
        case .coral: return "Coral"
        case .nord: return "Nord"
        case .navy: return "Navy"
        case .amber: return "Amber"
        case .midnight: return "Midnight"
        case .matrix: return "Matrix"
        case .lemon: return "Lemon"
        case .cobalt: return "Cobalt"
        case .silver: return "Silver"
        case .tropical: return "Tropical"
        case .arctic: return "Arctic"
        case .blush: return "Blush"
        case .sunflower: return "Sunflower"
        case .cream: return "Cream"
        case .cloud: return "Cloud"
        case .royal: return "Royal"
        case .lavender: return "Lavender"
        case .electric: return "Electric"
        case .tangerine: return "Tangerine"
        case .pastel: return "Pastel"
        case .neon: return "Neon"
        }
    }

    // Preview colors for theme selector (4 colors for the grid preview)
    var previewColors: [Color] {
        switch self {
        case .gadfly:
            return [Color(hex: "FFBF00"), Color(hex: "CC9900"), Color(hex: "FFD54F"), Color(hex: "000000")]
        case .default:
            return [Color(hex: "0ea5e9"), Color(hex: "6d28d9"), Color(hex: "059669"), Color(hex: "a78bfa")]
        case .emerald:
            return [Color(hex: "178F65"), Color(hex: "0E674D"), Color(hex: "20A271"), Color(hex: "4aa889")]
        case .orange:
            return [Color(hex: "DC540C"), Color(hex: "AC3D00"), Color(hex: "E96825"), Color(hex: "eb9268")]
        case .gold:
            return [Color(hex: "FFD738"), Color(hex: "DEA900"), Color(hex: "FFF4B8"), Color(hex: "c9a832")]
        case .ocean:
            return [Color(hex: "0071A4"), Color(hex: "1C405F"), Color(hex: "0E9DD3"), Color(hex: "5a8bab")]
        case .slate:
            return [Color(hex: "EAEAEA"), Color(hex: "CBCCCF"), Color(hex: "EF3E75"), Color(hex: "8a8b8d")]
        case .rose:
            return [Color(hex: "FFC4D9"), Color(hex: "FF81AA"), Color(hex: "EF3E75"), Color(hex: "e897b4")]
        case .crimson:
            return [Color(hex: "323232"), Color(hex: "E60A00"), Color(hex: "505050"), Color(hex: "F5F5F5")]
        case .bronze:
            return [Color(hex: "2F2C2F"), Color(hex: "A36B31"), Color(hex: "ADBA4E"), Color(hex: "DB6668")]
        case .sunset:
            return [Color(hex: "0050A0"), Color(hex: "F08000"), Color(hex: "000020"), Color(hex: "FFFFFF")]
        case .olive:
            return [Color(hex: "534d46"), Color(hex: "7a9c0f"), Color(hex: "9cbe30"), Color(hex: "f3b670")]
        case .steel:
            return [Color(hex: "373D48"), Color(hex: "5294E2"), Color(hex: "303641"), Color(hex: "4A5664")]
        case .charcoal:
            return [Color(hex: "383838"), Color(hex: "999999"), Color(hex: "303641"), Color(hex: "5c5c5c")]
        case .maroon:
            return [Color(hex: "8C1D40"), Color(hex: "FFC627"), Color(hex: "5C6670"), Color(hex: "00A3E0")]
        case .atom:
            return [Color(hex: "121417"), Color(hex: "2F343D"), Color(hex: "98C379"), Color(hex: "ABB2BF")]
        case .aubergine:
            return [Color(hex: "3F0E40"), Color(hex: "1164A3"), Color(hex: "2BAC76"), Color(hex: "CD2553")]
        case .forest:
            return [Color(hex: "194234"), Color(hex: "E7C12e"), Color(hex: "ee6030"), Color(hex: "9C2E33")]
        case .onyx:
            return [Color(hex: "222222"), Color(hex: "444444"), Color(hex: "38978D"), Color(hex: "fc7459")]
        case .cyan:
            return [Color(hex: "1d1d1d"), Color(hex: "0ba8ca"), Color(hex: "075566"), Color(hex: "EB4D5C")]
        case .coral:
            return [Color(hex: "F2F0EC"), Color(hex: "F2777A"), Color(hex: "99CC99"), Color(hex: "66CCCC")]
        case .nord:
            return [Color(hex: "2b303b"), Color(hex: "4f5b66"), Color(hex: "a3be8c"), Color(hex: "bf616a")]
        case .navy:
            return [Color(hex: "003E6B"), Color(hex: "73AD0D"), Color(hex: "F79F66"), Color(hex: "F15340")]
        case .amber:
            return [Color(hex: "F7941E"), Color(hex: "FFB963"), Color(hex: "3D0000"), Color(hex: "507DAA")]
        case .midnight:
            return [Color(hex: "020623"), Color(hex: "00B993"), Color(hex: "52eb7b"), Color(hex: "FF2154")]
        case .matrix:
            return [Color(hex: "2C2C26"), Color(hex: "13C217"), Color(hex: "229725"), Color(hex: "439AEA")]
        case .lemon:
            return [Color(hex: "f4f5f0"), Color(hex: "efd213"), Color(hex: "59c77f"), Color(hex: "fa575d")]
        case .cobalt:
            return [Color(hex: "193549"), Color(hex: "FFC600"), Color(hex: "0085FF"), Color(hex: "2CDB00")]
        case .silver:
            return [Color(hex: "F5F5F5"), Color(hex: "3873AE"), Color(hex: "69AA4E"), Color(hex: "999999")]
        case .tropical:
            return [Color(hex: "ffffff"), Color(hex: "4EBDA6"), Color(hex: "E5613B"), Color(hex: "E2B708")]
        case .arctic:
            return [Color(hex: "F8F8FA"), Color(hex: "2D9EE0"), Color(hex: "60D156"), Color(hex: "DC5960")]
        case .blush:
            return [Color(hex: "FBFBFB"), Color(hex: "F9C6D6"), Color(hex: "8EEADB"), Color(hex: "F0A2B8")]
        case .sunflower:
            return [Color(hex: "FDE13A"), Color(hex: "000000"), Color(hex: "E72D25"), Color(hex: "FFF09E")]
        case .cream:
            return [Color(hex: "F3E3CD"), Color(hex: "F3951D"), Color(hex: "DA3D61"), Color(hex: "F26328")]
        case .cloud:
            return [Color(hex: "f4f6f9"), Color(hex: "0070d2"), Color(hex: "4bca81"), Color(hex: "c23934")]
        case .royal:
            return [Color(hex: "6044db"), Color(hex: "f0b31a"), Color(hex: "500ba3"), Color(hex: "a92ab0")]
        case .lavender:
            return [Color(hex: "F4F5F6"), Color(hex: "9B4DCA"), Color(hex: "FFFFFF"), Color(hex: "606c76")]
        case .electric:
            return [Color(hex: "00A8E1"), Color(hex: "F7A800"), Color(hex: "0D2240"), Color(hex: "FFFFFF")]
        case .tangerine:
            return [Color(hex: "F9F6F1"), Color(hex: "FF3300"), Color(hex: "B3D4FD"), Color(hex: "1E1E1E")]
        case .pastel:
            return [Color(hex: "b19cd9"), Color(hex: "FEC8D8"), Color(hex: "89cff0"), Color(hex: "8F6DB0")]
        case .neon:
            return [Color(hex: "f9fc00"), Color(hex: "ec34ff"), Color(hex: "66ed00"), Color(hex: "2b2b2b")]
        }
    }

    // Primary/accent color
    var primaryColor: Color {
        switch self {
        case .gadfly: return Color(hex: "FFBF00")
        case .default: return Color(hex: "0ea5e9")
        case .emerald: return Color(hex: "20A271")
        case .orange: return Color(hex: "E96825")
        case .gold: return Color(hex: "DEA900")
        case .ocean: return Color(hex: "0E9DD3")
        case .slate: return Color(hex: "EF3E75")
        case .rose: return Color(hex: "EF3E75")
        case .crimson: return Color(hex: "E60A00")
        case .bronze: return Color(hex: "A36B31")
        case .sunset: return Color(hex: "F08000")
        case .olive: return Color(hex: "7a9c0f")
        case .steel: return Color(hex: "5294E2")
        case .charcoal: return Color(hex: "999999")
        case .maroon: return Color(hex: "FFC627")
        case .atom: return Color(hex: "98C379")
        case .aubergine: return Color(hex: "1164A3")
        case .forest: return Color(hex: "E7C12e")
        case .onyx: return Color(hex: "38978D")
        case .cyan: return Color(hex: "0ba8ca")
        case .coral: return Color(hex: "F2777A")
        case .nord: return Color(hex: "a3be8c")
        case .navy: return Color(hex: "73AD0D")
        case .amber: return Color(hex: "F7941E")
        case .midnight: return Color(hex: "00B993")
        case .matrix: return Color(hex: "13C217")
        case .lemon: return Color(hex: "efd213")
        case .cobalt: return Color(hex: "FFC600")
        case .silver: return Color(hex: "3873AE")
        case .tropical: return Color(hex: "4EBDA6")
        case .arctic: return Color(hex: "2D9EE0")
        case .blush: return Color(hex: "F0A2B8")
        case .sunflower: return Color(hex: "E72D25")
        case .cream: return Color(hex: "F3951D")
        case .cloud: return Color(hex: "0070d2")
        case .royal: return Color(hex: "f0b31a")
        case .lavender: return Color(hex: "9B4DCA")
        case .electric: return Color(hex: "F7A800")
        case .tangerine: return Color(hex: "FF3300")
        case .pastel: return Color(hex: "b19cd9")
        case .neon: return Color(hex: "f9fc00")
        }
    }

    var accentColor: Color {
        switch self {
        case .gadfly: return Color(hex: "CC9900")
        case .default: return Color(hex: "059669")
        case .emerald: return Color(hex: "178F65")
        case .orange: return Color(hex: "DC540C")
        case .gold: return Color(hex: "FFD738")
        case .ocean: return Color(hex: "0071A4")
        case .slate: return Color(hex: "CBCCCF")
        case .rose: return Color(hex: "FF81AA")
        case .crimson: return Color(hex: "E64600")
        case .bronze: return Color(hex: "ADBA4E")
        case .sunset: return Color(hex: "0050A0")
        case .olive: return Color(hex: "9cbe30")
        case .steel: return Color(hex: "4A5664")
        case .charcoal: return Color(hex: "5c5c5c")
        case .maroon: return Color(hex: "8C1D40")
        case .atom: return Color(hex: "2F343D")
        case .aubergine: return Color(hex: "2BAC76")
        case .forest: return Color(hex: "ee6030")
        case .onyx: return Color(hex: "fc7459")
        case .cyan: return Color(hex: "EB4D5C")
        case .coral: return Color(hex: "99CC99")
        case .nord: return Color(hex: "bf616a")
        case .navy: return Color(hex: "F15340")
        case .amber: return Color(hex: "FFB963")
        case .midnight: return Color(hex: "FF2154")
        case .matrix: return Color(hex: "439AEA")
        case .lemon: return Color(hex: "59c77f")
        case .cobalt: return Color(hex: "0085FF")
        case .silver: return Color(hex: "69AA4E")
        case .tropical: return Color(hex: "E5613B")
        case .arctic: return Color(hex: "60D156")
        case .blush: return Color(hex: "8EEADB")
        case .sunflower: return Color(hex: "FDE13A")
        case .cream: return Color(hex: "DA3D61")
        case .cloud: return Color(hex: "4bca81")
        case .royal: return Color(hex: "6044db")
        case .lavender: return Color(hex: "606c76")
        case .electric: return Color(hex: "00A8E1")
        case .tangerine: return Color(hex: "B3D4FD")
        case .pastel: return Color(hex: "89cff0")
        case .neon: return Color(hex: "ec34ff")
        }
    }

    var textColor: Color {
        switch self {
        case .gadfly: return Color(hex: "000000")
        case .default: return Color(hex: "6d28d9")
        case .emerald: return Color(hex: "0E674D")
        case .orange: return Color(hex: "AC3D00")
        case .gold: return Color(hex: "8a6a00")
        case .ocean: return Color(hex: "1C405F")
        case .slate: return Color(hex: "4a4b4d")
        case .rose: return Color(hex: "b02d56")
        case .crimson: return Color(hex: "323232")
        case .bronze: return Color(hex: "252525")
        case .sunset: return Color(hex: "000020")
        case .olive: return Color(hex: "534d46")
        case .steel: return Color(hex: "303641")
        case .charcoal: return Color(hex: "303641")
        case .maroon: return Color(hex: "5C6670")
        case .atom: return Color(hex: "ABB2BF")
        case .aubergine: return Color(hex: "350d36")
        case .forest: return Color(hex: "194234")
        case .onyx: return Color(hex: "333333")
        case .cyan: return Color(hex: "000000")
        case .coral: return Color(hex: "515151")
        case .nord: return Color(hex: "c0c5ce")
        case .navy: return Color(hex: "000a52")
        case .amber: return Color(hex: "110000")
        case .midnight: return Color(hex: "020623")
        case .matrix: return Color(hex: "229725")
        case .lemon: return Color(hex: "333232")
        case .cobalt: return Color(hex: "193549")
        case .silver: return Color(hex: "000000")
        case .tropical: return Color(hex: "777777")
        case .arctic: return Color(hex: "383F45")
        case .blush: return Color(hex: "5D5759")
        case .sunflower: return Color(hex: "000000")
        case .cream: return Color(hex: "183E1C")
        case .cloud: return Color(hex: "16325c")
        case .royal: return Color(hex: "500ba3")
        case .lavender: return Color(hex: "606c76")
        case .electric: return Color(hex: "0D2240")
        case .tangerine: return Color(hex: "1E1E1E")
        case .pastel: return Color(hex: "8F6DB0")
        case .neon: return Color(hex: "ffffff")
        }
    }

    var textDimColor: Color {
        switch self {
        case .gadfly: return Color(hex: "FFD54F")
        case .default: return Color(hex: "a78bfa")
        case .emerald: return Color(hex: "4aa889")
        case .orange: return Color(hex: "eb9268")
        case .gold: return Color(hex: "c9a832")
        case .ocean: return Color(hex: "5a8bab")
        case .slate: return Color(hex: "8a8b8d")
        case .rose: return Color(hex: "e897b4")
        case .crimson: return Color(hex: "505050")
        case .bronze: return Color(hex: "5C6380")
        case .sunset: return Color(hex: "0050A0")
        case .olive: return Color(hex: "706b63")
        case .steel: return Color(hex: "4A5664")
        case .charcoal: return Color(hex: "5c5c5c")
        case .maroon: return Color(hex: "5C6670")
        case .atom: return Color(hex: "4f5b66")
        case .aubergine: return Color(hex: "CD2553")
        case .forest: return Color(hex: "9c2e33")
        case .onyx: return Color(hex: "444444")
        case .cyan: return Color(hex: "075566")
        case .coral: return Color(hex: "B8B8B8")
        case .nord: return Color(hex: "a7adba")
        case .navy: return Color(hex: "D37C71")
        case .amber: return Color(hex: "F5A849")
        case .midnight: return Color(hex: "41465c")
        case .matrix: return Color(hex: "229725")
        case .lemon: return Color(hex: "EFD213")
        case .cobalt: return Color(hex: "1D425D")
        case .silver: return Color(hex: "999999")
        case .tropical: return Color(hex: "E2B708")
        case .arctic: return Color(hex: "383F45")
        case .blush: return Color(hex: "8EEADB")
        case .sunflower: return Color(hex: "FFF09E")
        case .cream: return Color(hex: "F26328")
        case .cloud: return Color(hex: "e0e5ee")
        case .royal: return Color(hex: "997929")
        case .lavender: return Color(hex: "9B4DCA")
        case .electric: return Color(hex: "0D2240")
        case .tangerine: return Color(hex: "FF3300")
        case .pastel: return Color(hex: "FEC8D8")
        case .neon: return Color(hex: "66ed00")
        }
    }

    var downColor: Color {
        switch self {
        case .gadfly: return Color(hex: "CC9900")
        case .default: return Color(hex: "3b82f6")
        case .emerald: return Color(hex: "178F65")
        case .orange: return Color(hex: "DC540C")
        case .gold: return Color(hex: "DEA900")
        case .ocean: return Color(hex: "0071A4")
        case .slate: return Color(hex: "6b6c6e")
        case .rose: return Color(hex: "FF81AA")
        case .crimson: return Color(hex: "E60A00")
        case .bronze: return Color(hex: "A36B31")
        case .sunset: return Color(hex: "0050A0")
        case .olive: return Color(hex: "648200")
        case .steel: return Color(hex: "5294E2")
        case .charcoal: return Color(hex: "5c5c5c")
        case .maroon: return Color(hex: "8C1D40")
        case .atom: return Color(hex: "80A2BE")
        case .aubergine: return Color(hex: "1164A3")
        case .forest: return Color(hex: "9C2E33")
        case .onyx: return Color(hex: "38978D")
        case .cyan: return Color(hex: "0ba8ca")
        case .coral: return Color(hex: "66CCCC")
        case .nord: return Color(hex: "4f5b66")
        case .navy: return Color(hex: "003E6B")
        case .amber: return Color(hex: "507DAA")
        case .midnight: return Color(hex: "00B993")
        case .matrix: return Color(hex: "13C217")
        case .lemon: return Color(hex: "59c77f")
        case .cobalt: return Color(hex: "0085FF")
        case .silver: return Color(hex: "3873AE")
        case .tropical: return Color(hex: "4EBDA6")
        case .arctic: return Color(hex: "2D9EE0")
        case .blush: return Color(hex: "8EEADB")
        case .sunflower: return Color(hex: "000000")
        case .cream: return Color(hex: "F3951D")
        case .cloud: return Color(hex: "0070d2")
        case .royal: return Color(hex: "6044db")
        case .lavender: return Color(hex: "9B4DCA")
        case .electric: return Color(hex: "00A8E1")
        case .tangerine: return Color(hex: "FF3300")
        case .pastel: return Color(hex: "89cff0")
        case .neon: return Color(hex: "ec34ff")
        }
    }

    var upColor: Color {
        switch self {
        case .gadfly: return Color(hex: "FFD54F")
        case .default: return Color(hex: "22c55e")
        case .emerald: return Color(hex: "20A271")
        case .orange: return Color(hex: "E96825")
        case .gold: return Color(hex: "FFD738")
        case .ocean: return Color(hex: "0E9DD3")
        case .slate: return Color(hex: "EF3E75")
        case .rose: return Color(hex: "EF3E75")
        case .crimson: return Color(hex: "E64600")
        case .bronze: return Color(hex: "ADBA4E")
        case .sunset: return Color(hex: "F08000")
        case .olive: return Color(hex: "9cbe30")
        case .steel: return Color(hex: "5294E2")
        case .charcoal: return Color(hex: "999999")
        case .maroon: return Color(hex: "94E864")
        case .atom: return Color(hex: "98C379")
        case .aubergine: return Color(hex: "2BAC76")
        case .forest: return Color(hex: "ee6030")
        case .onyx: return Color(hex: "fc7459")
        case .cyan: return Color(hex: "EB4D5C")
        case .coral: return Color(hex: "99CC99")
        case .nord: return Color(hex: "a3be8c")
        case .navy: return Color(hex: "73AD0D")
        case .amber: return Color(hex: "FFB963")
        case .midnight: return Color(hex: "52eb7b")
        case .matrix: return Color(hex: "13C217")
        case .lemon: return Color(hex: "fa575d")
        case .cobalt: return Color(hex: "2CDB00")
        case .silver: return Color(hex: "69AA4E")
        case .tropical: return Color(hex: "E5613B")
        case .arctic: return Color(hex: "60D156")
        case .blush: return Color(hex: "F0A2B8")
        case .sunflower: return Color(hex: "E72D25")
        case .cream: return Color(hex: "DA3D61")
        case .cloud: return Color(hex: "4bca81")
        case .royal: return Color(hex: "f0b31a")
        case .lavender: return Color(hex: "9B4DCA")
        case .electric: return Color(hex: "F7A800")
        case .tangerine: return Color(hex: "FF3300")
        case .pastel: return Color(hex: "FEC8D8")
        case .neon: return Color(hex: "66ed00")
        }
    }

    var backgroundColor: Color {
        switch self {
        case .gadfly:
            return Color(hex: "fafaf9")
        case .default, .emerald, .orange, .ocean:
            return Color(hex: "fafaf9")
        case .gold:
            return Color(hex: "FFFEF8")
        case .slate:
            return Color(hex: "EAEAEA")
        case .rose:
            return Color(hex: "FFF9FB")
        case .crimson, .charcoal, .steel:
            return Color(hex: "323232")
        case .bronze, .atom, .nord:
            return Color(hex: "2F2C2F")
        case .sunset, .navy:
            return Color(hex: "000020")
        case .olive:
            return Color(hex: "fafaf9")
        case .maroon:
            return Color(hex: "fafaf9")
        case .aubergine:
            return Color(hex: "3F0E40")
        case .forest:
            return Color(hex: "194234")
        case .onyx, .cyan:
            return Color(hex: "1d1d1d")
        case .coral:
            return Color(hex: "F2F0EC")
        case .amber:
            return Color(hex: "F7941E")
        case .midnight:
            return Color(hex: "020623")
        case .matrix:
            return Color(hex: "2C2C26")
        case .lemon:
            return Color(hex: "f4f5f0")
        case .cobalt:
            return Color(hex: "193549")
        case .silver:
            return Color(hex: "F5F5F5")
        case .tropical, .arctic, .lavender:
            return Color(hex: "F8F8FA")
        case .blush:
            return Color(hex: "FBFBFB")
        case .sunflower:
            return Color(hex: "FDE13A")
        case .cream:
            return Color(hex: "F3E3CD")
        case .cloud:
            return Color(hex: "f4f6f9")
        case .royal:
            return Color(hex: "6044db")
        case .electric:
            return Color(hex: "00A8E1")
        case .tangerine:
            return Color(hex: "F9F6F1")
        case .pastel:
            return Color(hex: "b19cd9")
        case .neon:
            return Color(hex: "2b2b2b")
        }
    }

    var cardBackground: Color {
        switch self {
        // Dark themes need darker card backgrounds
        case .crimson, .charcoal, .steel, .bronze, .atom, .nord, .aubergine, .forest, .onyx, .cyan, .midnight, .matrix, .cobalt, .sunset, .navy, .neon:
            return Color(hex: "3a3a3a")
        case .royal, .electric, .pastel:
            return Color(hex: "ffffff").opacity(0.2)
        default:
            return .white
        }
    }

    // Helper to determine if theme is dark (for text color adjustments)
    var isDark: Bool {
        switch self {
        case .crimson, .charcoal, .steel, .bronze, .atom, .nord, .aubergine, .forest, .onyx, .cyan, .midnight, .matrix, .cobalt, .sunset, .navy, .royal, .electric, .pastel, .amber, .sunflower, .neon:
            return true
        default:
            return false
        }
    }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
        }
    }

    init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = AppTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .default
        }
    }

    // Convenience accessors
    var primary: Color { currentTheme.primaryColor }
    var accent: Color { currentTheme.accentColor }
    var text: Color { currentTheme.textColor }
    var textDim: Color { currentTheme.textDimColor }
    var down: Color { currentTheme.downColor }
    var up: Color { currentTheme.upColor }
    var background: Color { currentTheme.backgroundColor }
    var card: Color { currentTheme.cardBackground }
    var isDark: Bool { currentTheme.isDark }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Environment Key for Theme
private struct ThemeKey: EnvironmentKey {
    static let defaultValue: ThemeManager = ThemeManager.shared
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
