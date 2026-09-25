.pragma library

// Grid conversions for the Fly view "Point 1 / TGT" panel.
//  - Everest grid: Indian Grid zones (LCC 1SP) on Kalianpur 1975 datum
//  - Custom grid:  LCC 2SP on WGS84, user supplied parameters
// Math and constants match the LOCATORS GRID CONVERTER tool.

var WGS84 = { a: 6378137.0, invf: 298.257223563 }

var KALIANPUR_1975 = {
    label:      "Kalianpur 1975",
    ellipsoid:  { a: 6377299.151, invf: 300.8017255 },
    towgs84:    { dx: 295, dy: 736, dz: 257 }
}

var INDIA_ZONE_KEYS = [ "0", "I", "IIa", "IIb", "IIIa", "IVa" ]
var INDIA_ZONES = {
    "0":    { label: "Zone 0",    lat0: 39.5, lon0: 68, k0: 0.99846154, FE: 2153746.0, FN: 2368271.6 },
    "I":    { label: "Zone I",    lat0: 32.5, lon0: 68, k0: 0.99878641, FE: 2743195.5, FN: 914398.5 },
    "IIa":  { label: "Zone IIa",  lat0: 26,   lon0: 74, k0: 0.99878641, FE: 2743195.6, FN: 914398.5 },
    "IIb":  { label: "Zone IIb",  lat0: 26,   lon0: 90, k0: 0.99878641, FE: 2743195.6, FN: 914398.5 },
    "IIIa": { label: "Zone IIIa", lat0: 19,   lon0: 80, k0: 0.99878641, FE: 2743195.6, FN: 914398.5 },
    "IVa":  { label: "Zone IVa",  lat0: 12,   lon0: 80, k0: 0.99878641, FE: 2743195.6, FN: 914398.5 }
}

function toRad(d) { return d * Math.PI / 180 }
function toDeg(r) { return r * 180 / Math.PI }

function _ell(e) {
    var f = 1 / e.invf
    var e2 = f * (2 - f)
    return { a: e.a, f: f, e2: e2, e: Math.sqrt(e2) }
}

function _tFunc(p, e) {
    return Math.tan(Math.PI / 4 - p / 2) / Math.pow((1 - e * Math.sin(p)) / (1 + e * Math.sin(p)), e / 2)
}

function _phiFromT(t, e) {
    var phi = Math.PI / 2 - 2 * Math.atan(t)
    for (var i = 0; i < 15; i++) {
        phi = Math.PI / 2 - 2 * Math.atan(t * Math.pow((1 - e * Math.sin(phi)) / (1 + e * Math.sin(phi)), e / 2))
    }
    return phi
}

// ---- LCC 1 standard parallel (Indian Grid zones) ----
function lcc1spForward(lat, lon, z, ellipsoid) {
    var el = _ell(ellipsoid)
    var phi = toRad(lat), lam = toRad(lon)
    var phi0 = toRad(z.lat0), lam0 = toRad(z.lon0)
    var m0 = Math.cos(phi0) / Math.sqrt(1 - el.e2 * Math.pow(Math.sin(phi0), 2))
    var t0 = _tFunc(phi0, el.e)
    var n = Math.sin(phi0)
    var F = m0 / (n * Math.pow(t0, n))
    var rho = el.a * F * z.k0 * Math.pow(_tFunc(phi, el.e), n)
    var rho0 = el.a * F * z.k0 * Math.pow(t0, n)
    var theta = n * (lam - lam0)
    return { E: z.FE + rho * Math.sin(theta), N: z.FN + rho0 - rho * Math.cos(theta) }
}

function lcc1spInverse(E, N, z, ellipsoid) {
    var el = _ell(ellipsoid)
    var phi0 = toRad(z.lat0), lam0 = toRad(z.lon0)
    var m0 = Math.cos(phi0) / Math.sqrt(1 - el.e2 * Math.pow(Math.sin(phi0), 2))
    var t0 = _tFunc(phi0, el.e)
    var n = Math.sin(phi0)
    var F = m0 / (n * Math.pow(t0, n))
    var rho0 = el.a * F * z.k0 * Math.pow(t0, n)
    var dx = E - z.FE, dy = rho0 - (N - z.FN)
    var rho = Math.sqrt(dx * dx + dy * dy)
    var theta = Math.atan2(dx, dy)
    var t = Math.pow(rho / (el.a * F * z.k0), 1 / n)
    return { lat: toDeg(_phiFromT(t, el.e)), lon: toDeg(theta / n + lam0) }
}

// ---- LCC 2 standard parallels on WGS84 (Custom grid) ----
// p = { lat0, lon0, sp1, sp2, FE, FN }
function _lcc2Consts(p) {
    var el = _ell(WGS84)
    var phi0 = toRad(p.lat0), phi1 = toRad(p.sp1), phi2 = toRad(p.sp2)
    var m1 = Math.cos(phi1) / Math.sqrt(1 - el.e2 * Math.pow(Math.sin(phi1), 2))
    var m2 = Math.cos(phi2) / Math.sqrt(1 - el.e2 * Math.pow(Math.sin(phi2), 2))
    var t0 = _tFunc(phi0, el.e), t1 = _tFunc(phi1, el.e), t2 = _tFunc(phi2, el.e)
    var n = (Math.abs(p.sp1 - p.sp2) < 1e-10)
            ? Math.sin(phi1)
            : (Math.log(m1) - Math.log(m2)) / (Math.log(t1) - Math.log(t2))
    var F = m1 / (n * Math.pow(t1, n))
    return { el: el, n: n, F: F, rho0: el.a * F * Math.pow(t0, n), lam0: toRad(p.lon0) }
}

function lcc2spForward(lat, lon, p) {
    var c = _lcc2Consts(p)
    var rho = c.el.a * c.F * Math.pow(_tFunc(toRad(lat), c.el.e), c.n)
    var theta = c.n * (toRad(lon) - c.lam0)
    return { E: p.FE + rho * Math.sin(theta), N: p.FN + c.rho0 - rho * Math.cos(theta) }
}

function lcc2spInverse(E, N, p) {
    var c = _lcc2Consts(p)
    var dx = E - p.FE, dy = c.rho0 - (N - p.FN)
    var rho = Math.sqrt(dx * dx + dy * dy)
    if (c.n < 0) rho = -rho
    var theta = Math.atan2(c.n < 0 ? -dx : dx, c.n < 0 ? -dy : dy)
    var t = Math.pow(rho / (c.el.a * c.F), 1 / c.n)
    return { lat: toDeg(_phiFromT(t, c.el.e)), lon: toDeg(theta / c.n + c.lam0) }
}

// ---- Datum shift (3 parameter geocentric translation) ----
function _toGeocentric(lat, lon, h, ellipsoid) {
    var el = _ell(ellipsoid)
    var phi = toRad(lat), lam = toRad(lon)
    var Nr = el.a / Math.sqrt(1 - el.e2 * Math.pow(Math.sin(phi), 2))
    return { X: (Nr + h) * Math.cos(phi) * Math.cos(lam),
             Y: (Nr + h) * Math.cos(phi) * Math.sin(lam),
             Z: (Nr * (1 - el.e2) + h) * Math.sin(phi) }
}

function _fromGeocentric(X, Y, Z, ellipsoid) {
    var el = _ell(ellipsoid)
    var lam = Math.atan2(Y, X)
    var p = Math.sqrt(X * X + Y * Y)
    var phi = Math.atan2(Z, p * (1 - el.e2))
    var h = 0
    for (var i = 0; i < 12; i++) {
        var Nr = el.a / Math.sqrt(1 - el.e2 * Math.pow(Math.sin(phi), 2))
        h = p / Math.cos(phi) - Nr
        phi = Math.atan2(Z, p * (1 - el.e2 * (Nr / (Nr + h))))
    }
    return { lat: toDeg(phi), lon: toDeg(lam) }
}

function kalianpurToWgs84(lat, lon) {
    var d = KALIANPUR_1975
    var g = _toGeocentric(lat, lon, 0, d.ellipsoid)
    return _fromGeocentric(g.X + d.towgs84.dx, g.Y + d.towgs84.dy, g.Z + d.towgs84.dz, WGS84)
}

function wgs84ToKalianpur(lat, lon) {
    var d = KALIANPUR_1975
    var g = _toGeocentric(lat, lon, 0, WGS84)
    return _fromGeocentric(g.X - d.towgs84.dx, g.Y - d.towgs84.dy, g.Z - d.towgs84.dz, d.ellipsoid)
}

// ---- Public helpers used by the QML panel ----

/// Everest grid (zone key, E, N) -> WGS84 {lat, lon}
function everestToWgs84(zoneKey, E, N) {
    var z = INDIA_ZONES[zoneKey]
    var local = lcc1spInverse(E, N, z, KALIANPUR_1975.ellipsoid)
    return kalianpurToWgs84(local.lat, local.lon)
}

/// WGS84 -> Everest grid {E, N}
function wgs84ToEverest(zoneKey, lat, lon) {
    var local = wgs84ToKalianpur(lat, lon)
    return lcc1spForward(local.lat, local.lon, INDIA_ZONES[zoneKey], KALIANPUR_1975.ellipsoid)
}

/// Custom grid (E, N) -> WGS84 {lat, lon}
function customToWgs84(p, E, N) {
    return lcc2spInverse(E, N, p)
}

/// WGS84 -> Custom grid {E, N}
function wgs84ToCustom(p, lat, lon) {
    return lcc2spForward(lat, lon, p)
}

/// Checks custom grid parameters. Returns "" if ok, otherwise an error text.
function checkCustomParams(p) {
    var names = [ "lat0", "lon0", "sp1", "sp2", "FE", "FN" ]
    for (var i = 0; i < names.length; i++) {
        if (typeof p[names[i]] !== "number" || isNaN(p[names[i]])) {
            return "Fill all Custom Grid settings"
        }
    }
    if (Math.abs(p.lat0) >= 90 || Math.abs(p.sp1) >= 90 || Math.abs(p.sp2) >= 90) {
        return "Latitudes must be between -90 and 90"
    }
    if (Math.abs(p.lon0) > 180) {
        return "Origin longitude must be between -180 and 180"
    }
    if (Math.abs(p.sp1 + p.sp2) < 1e-10) {
        return "Standard parallels must not be opposite (e.g. 10 and -10)"
    }
    return ""
}

/// Parses a number, returns NaN if the text is not a plain number
function parseNum(text) {
    var s = String(text).trim()
    if (s === "" || !/^[-+]?\d*\.?\d+(e[-+]?\d+)?$/i.test(s)) {
        return NaN
    }
    return Number(s)
}
