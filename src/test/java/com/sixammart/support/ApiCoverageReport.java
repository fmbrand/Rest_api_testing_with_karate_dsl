package com.sixammart.support;

import com.intuit.karate.Json;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;
import java.util.stream.Stream;

/**
 * Compares the endpoints in the Postman collection (postman/*.json) with the calls recorded by
 * {@link ApiCoverageHook} (target/api-calls/*.csv) and writes target/api-coverage/api-coverage.{md,html}.
 * An endpoint counts as covered when at least one call hit it; the report also splits calls into
 * positive (2xx) and negative (4xx) so thin spots are visible.
 */
public class ApiCoverageReport {

    static class Endpoint {
        String folder, name, method, path;
        List<Pattern> segments = new ArrayList<>();
        List<Boolean> wild = new ArrayList<>();
        int wildcards;
        int calls, positive, negative;
    }

    public static void generate() {
        try {
            Path postmanDir = Paths.get("postman");
            if (!Files.isDirectory(postmanDir)) {
                System.out.println("API coverage: no postman/ folder - drop the Postman collection JSON there to get the report.");
                return;
            }
            List<Path> collections;
            try (Stream<Path> s = Files.list(postmanDir)) {
                collections = s.filter(p -> p.toString().endsWith(".json")).toList();
            }
            if (collections.isEmpty()) {
                System.out.println("API coverage: postman/ is empty - add the collection JSON to enable the report.");
                return;
            }
            List<Endpoint> endpoints = new ArrayList<>();
            for (Path p : collections) {
                Map<String, Object> root = Json.of(Files.readString(p, StandardCharsets.UTF_8)).asMap();
                walk((List<Map<String, Object>>) root.get("item"), "", endpoints);
            }
            applyCalls(endpoints);
            write(endpoints);
        } catch (Exception e) {
            System.err.println("API coverage report failed: " + e);
        }
    }

    @SuppressWarnings("unchecked")
    private static void walk(List<Map<String, Object>> items, String folder, List<Endpoint> out) {
        if (items == null) return;
        for (Map<String, Object> item : items) {
            if (item.containsKey("item")) {
                String sub = folder.isEmpty() ? (String) item.get("name") : folder + " / " + item.get("name");
                walk((List<Map<String, Object>>) item.get("item"), sub, out);
            } else if (item.containsKey("request")) {
                Map<String, Object> req = (Map<String, Object>) item.get("request");
                Map<String, Object> url = (Map<String, Object>) req.get("url");
                List<String> path = new ArrayList<>((List<String>) url.get("path"));
                if (path.size() >= 2 && path.get(0).equals("api") && path.get(1).equals("v1")) {
                    path = path.subList(2, path.size());
                }
                Endpoint e = new Endpoint();
                e.folder = folder;
                e.name = (String) item.get("name");
                e.method = ((String) req.get("method")).toUpperCase();
                e.path = String.join("/", path);
                for (String seg : path) {
                    boolean w = seg.contains("{");
                    e.wild.add(w);
                    if (w) e.wildcards++;
                    e.segments.add(Pattern.compile(segmentRegex(seg)));
                }
                out.add(e);
            }
        }
    }

    /** "list-{status}" -> list-[^/]+ ; "{{id}}" -> [^/]+ ; plain text is matched literally. */
    private static String segmentRegex(String seg) {
        StringBuilder rx = new StringBuilder();
        java.util.regex.Matcher m = Pattern.compile("\\{+[^}]*\\}+").matcher(seg);
        int last = 0;
        while (m.find()) {
            if (m.start() > last) rx.append(Pattern.quote(seg.substring(last, m.start())));
            rx.append("[^/]+");
            last = m.end();
        }
        if (last < seg.length()) rx.append(Pattern.quote(seg.substring(last)));
        return rx.toString();
    }

    private static void applyCalls(List<Endpoint> endpoints) throws IOException {
        Path dir = Paths.get("target", "api-calls");
        if (!Files.isDirectory(dir)) return;
        List<Path> files;
        try (Stream<Path> s = Files.list(dir)) {
            files = s.filter(p -> p.toString().endsWith(".csv")).toList();
        }
        for (Path f : files) {
            for (String line : Files.readAllLines(f, StandardCharsets.UTF_8)) {
                String[] parts = line.split(",");
                if (parts.length < 3) continue;
                String method = parts[0];
                String[] segs = parts[1].split("\\?")[0].split("/");
                int status = Integer.parseInt(parts[2].trim());
                Endpoint best = null;
                for (Endpoint e : endpoints) {
                    if (!e.method.equals(method) || e.segments.size() != segs.length) continue;
                    boolean ok = true;
                    for (int i = 0; i < segs.length && ok; i++) {
                        ok = e.segments.get(i).matcher(segs[i]).matches();
                    }
                    if (ok && (best == null || e.wildcards < best.wildcards)) best = e;
                }
                if (best == null) continue;
                best.calls++;
                if (status >= 200 && status < 300) best.positive++;
                else if (status >= 400 && status < 500) best.negative++;
            }
        }
    }

    private static void write(List<Endpoint> endpoints) throws IOException {
        Map<String, List<Endpoint>> byTop = new LinkedHashMap<>();
        for (Endpoint e : endpoints) {
            String top = e.folder.contains(" / ") ? e.folder.substring(0, e.folder.indexOf(" / ")) : e.folder;
            byTop.computeIfAbsent(top, k -> new ArrayList<>()).add(e);
        }
        long total = endpoints.size();
        long covered = endpoints.stream().filter(e -> e.calls > 0).count();
        long both = endpoints.stream().filter(e -> e.positive > 0 && e.negative > 0).count();

        StringBuilder md = new StringBuilder();
        md.append("# API coverage\n\n");
        md.append(String.format("**%d / %d endpoints called (%.1f%%)** - %d have both a positive (2xx) and a negative (4xx) call.\n\n",
                covered, total, total == 0 ? 0 : covered * 100.0 / total, both));
        md.append("| Postman folder | Endpoints | Covered | % | Positive+Negative |\n|---|---:|---:|---:|---:|\n");
        for (Map.Entry<String, List<Endpoint>> en : byTop.entrySet()) {
            long c = en.getValue().stream().filter(e -> e.calls > 0).count();
            long b = en.getValue().stream().filter(e -> e.positive > 0 && e.negative > 0).count();
            md.append(String.format("| %s | %d | %d | %.0f%% | %d |\n", en.getKey(), en.getValue().size(), c,
                    c * 100.0 / en.getValue().size(), b));
        }
        md.append("\n## Not covered yet\n\n");
        for (Map.Entry<String, List<Endpoint>> en : byTop.entrySet()) {
            List<Endpoint> missing = en.getValue().stream().filter(e -> e.calls == 0).toList();
            if (missing.isEmpty()) continue;
            md.append("### ").append(en.getKey()).append(" (").append(missing.size()).append(")\n");
            for (Endpoint e : missing) md.append("- `").append(e.method).append(" /").append(e.path).append("` - ").append(e.folder).append("\n");
            md.append("\n");
        }

        StringBuilder html = new StringBuilder("<!doctype html><meta charset=utf-8><title>API coverage</title><style>"
                + "body{font:14px system-ui;margin:24px;max-width:1100px}table{border-collapse:collapse;width:100%}"
                + "td,th{border:1px solid #ddd;padding:5px 8px;text-align:left}th{background:#f4f4f4}"
                + ".ok{background:#e6f4ea}.part{background:#fff4e0}.no{background:#fde8e8}code{font-size:12px}</style>");
        html.append(String.format("<h1>API coverage</h1><p><b>%d / %d</b> endpoints called (%.1f%%); %d with both positive and negative calls.</p>",
                covered, total, total == 0 ? 0 : covered * 100.0 / total, both));
        for (Map.Entry<String, List<Endpoint>> en : byTop.entrySet()) {
            html.append("<h2>").append(en.getKey()).append("</h2><table><tr><th>Endpoint</th><th>Folder</th><th>Calls</th><th>2xx</th><th>4xx</th></tr>");
            for (Endpoint e : en.getValue()) {
                String cls = e.calls == 0 ? "no" : (e.positive > 0 && e.negative > 0 ? "ok" : "part");
                html.append(String.format("<tr class=%s><td><code>%s /%s</code></td><td>%s</td><td>%d</td><td>%d</td><td>%d</td></tr>",
                        cls, e.method, e.path, e.folder, e.calls, e.positive, e.negative));
            }
            html.append("</table>");
        }

        Path out = Paths.get("target", "api-coverage");
        Files.createDirectories(out);
        Files.writeString(out.resolve("api-coverage.md"), md.toString(), StandardCharsets.UTF_8);
        Files.writeString(out.resolve("api-coverage.html"), html.toString(), StandardCharsets.UTF_8);
        System.out.println(String.format("API coverage: %d/%d endpoints (%.1f%%) -> %s", covered, total,
                total == 0 ? 0 : covered * 100.0 / total, out.resolve("api-coverage.html").toAbsolutePath()));
    }
}
