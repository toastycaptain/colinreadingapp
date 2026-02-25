import Foundation

enum CookieInstaller {
    static func install(_ cookies: [PlaybackCookieDTO]) {
        for cookie in cookies {
            guard let expiresDate = ISO8601DateFormatter().date(from: cookie.expires) else {
                continue
            }

            var properties: [HTTPCookiePropertyKey: Any] = [
                .name: cookie.name,
                .value: cookie.value,
                .domain: cookie.domain,
                .path: cookie.path,
                .expires: expiresDate,
                .secure: cookie.secure ?? true,
            ]

            if cookie.httpOnly == true {
                properties[.init("HttpOnly")] = true
            }

            if let httpCookie = HTTPCookie(properties: properties) {
                HTTPCookieStorage.shared.setCookie(httpCookie)
            }
        }
    }
}
