import Foundation

enum RSSClientError: Error {
    case badStatus(Int)
    case emptyFeed
}

/// Cliente RSS mínimo (RSS 2.0 / Atom básico) para la v1.
actor RSSClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchItems(from source: FeedSource, limit: Int = 10) async throws -> [RationItem] {
        let (data, response) = try await session.data(from: source.feedURL)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw RSSClientError.badStatus(http.statusCode)
        }

        let parser = RSSParser(source: source)
        let items = parser.parse(data: data)
        guard !items.isEmpty else { throw RSSClientError.emptyFeed }
        return Array(items.prefix(limit))
    }
}

final class RSSParser: NSObject, XMLParserDelegate {
    private let source: FeedSource
    private var items: [RationItem] = []

    private var insideItem = false
    private var currentElement = ""
    private var title = ""
    private var link = ""
    private var summary = ""
    private var pubDate = ""
    private var isAtom = false

    init(source: FeedSource) {
        self.source = source
    }

    func parse(data: Data) -> [RationItem] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return items
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentElement = elementName.lowercased()
        if currentElement == "entry" {
            isAtom = true
            beginItem()
        } else if currentElement == "item" {
            beginItem()
        } else if insideItem, currentElement == "link", let href = attributeDict["href"], !href.isEmpty {
            link = href
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard insideItem else { return }
        switch currentElement {
        case "title": title += string
        case "link": if !isAtom { link += string }
        case "description", "summary", "content", "content:encoded": summary += string
        case "pubdate", "published", "updated", "dc:date": pubDate += string
        default: break
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let name = elementName.lowercased()
        if name == "item" || name == "entry" {
            finishItem()
        }
        currentElement = ""
    }

    private func beginItem() {
        insideItem = true
        title = ""
        link = ""
        summary = ""
        pubDate = ""
    }

    private func finishItem() {
        defer { insideItem = false }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        let url = URL(string: link.trimmingCharacters(in: .whitespacesAndNewlines))
        let cleanSummary = summary
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        items.append(
            RationItem(
                title: trimmedTitle,
                summary: String(cleanSummary.prefix(280)),
                url: url,
                sourceName: source.name,
                kind: source.kind,
                publishedAt: Self.parseDate(pubDate)
            )
        )
    }

    private static func parseDate(_ raw: String) -> Date? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: value) { return d }
        let rfc = DateFormatter()
        rfc.locale = Locale(identifier: "en_US_POSIX")
        rfc.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return rfc.date(from: value)
    }
}
