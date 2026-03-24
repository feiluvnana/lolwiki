# 🕸️ flncrawly Features Plan

This document outlines a detailed roadmap and plan for expanding the `flncrawly` framework based on its current architecture. The goal is to evolve the library into a comprehensive, production-ready web crawling solution for Dart, comparable to industry standards like Scrapy or Colly.

## 🚀 Priority 1: Advanced Downloader Middlewares

Currently, `flncrawly` supports `Delay`, `Retry`, and `UserAgent` rotation. To handle more complex scraping scenarios, the following middleware should be added:

1. **`RobotsTxtMiddleware`**
   - Automatically fetch and parse a site's `robots.txt`.
   - Before scheduling a request, check if the crawler's User-Agent is permitted to access the URL.
   - Configurable to forcefully ignore `robots.txt` if needed.
2. **`HttpProxyMiddleware`**
   - Support for routing requests through proxies to avoid IP bans.
   - Ability to pass a rotating list of proxies so that each request or batch of requests uses a new IP.
3. **`HttpCacheMiddleware`**
   - Cache responses (e.g., to disk/file system or memory) based on URL/Request hashes.
   - Extremely useful during development and debugging so that processors can be tested without hitting the live server repeatedly.
4. **`CookieMiddleware`**
   - Maintain sessions and cookies across requests automatically.
   - Useful for scraping sites that require a logged-in state or track users via session IDs.

## ⚙️ Priority 2: Data Export Pipelines

The current pipeline layer efficiently exports items using `JsonFilePipeline` and logs using `LogPipeline`. We should introduce more built-in sinks:

1. **`CsvFilePipeline`**
   - Export structured data directly to CSV format mapping item keys to columns.
2. **`DatabasePipeline` (SQL/NoSQL Sinks)**
   - Pre-built pipelines for common databases (e.g., SQLite, PostgreSQL, MongoDB).
   - Insert items directly into a table or collection as they stream in.
3. **`BatchPipeline`**
   - A generic pipeline that groups items into batches (e.g., 100 items at a time) before calling an insertion function, reducing database overhead.

## 🏗️ Priority 3: Core Engine & Dispatcher Enhancements

To increase crawler intelligence and scale:

1. **`AutoThrottleMiddleware`**
   - Dynamically adjust the request delay based on the target server's response time and load.
   - If the server slows down, the crawler increases its delay to avoid overwhelming the server or getting banned.
2. **Distributed Crawling (`RedisDispatcher`)**
   - Allow multiple crawler instances to share a single request queue using Redis.
   - Enables horizontal scaling of the crawling process across multiple machines or Dart isolates.
3. **Advanced Engine Statistics (`Stats` Collector)**
   - Track detailed metrics: bytes downloaded, success/error rates, redirects, parsing speed, and active domains.
   - Export stats periodically to a dashboard or log file.

## 🌐 Priority 4: Dynamic Content and Headless Browsing

1. **`HeadlessDownloader` Middleware/Integration**
   - Modern web heavily relies on JavaScript (SPAs).
   - Integrate with tools like `puppeteer-dart` to execute JS and return the fully rendered HTML DOM back to the `Processor`.

## 🛠️ Priority 5: Developer Tools

1. **CLI Tool (`flncrawly shell`)**
   - Introduce an interactive REPL command-line interface.
   - Developers can download a page, test XPath or CSS selectors on the fly without writing a full `Processor`.
2. **Boilerplate Generator**
   - A command (e.g., `dart run flncrawly:create project_name`) that scaffolds a new crawler directory with best-practice structures (main script, processors, models, pipelines).

## Summary Table

| Component | Feature | Complexity | Impact |
| --- | --- | --- | --- |
| Middleware | `RobotsTxtMiddleware` | Low | High |
| Middleware | `HttpProxyMiddleware` | Medium | High |
| Middleware | `HttpCacheMiddleware`| Medium | High |
| Middleware | `CookieMiddleware` | Low | Medium |
| Pipeline | `CsvFilePipeline` | Low | Medium |
| Pipeline | `DatabasePipelines` | Medium | Medium |
| Dispatcher | `RedisDispatcher` | High | High (Scale) |
| Downloader | `HeadlessDownloader` | High | High (JS) |
| Tooling | Interactive CLI | Medium | High (DX) |

---
*This plan can be iteratively implemented, starting with the highest-impact middlewares and pipelines to support more robust daily usage.*
