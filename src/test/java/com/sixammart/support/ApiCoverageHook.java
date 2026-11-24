package com.sixammart.support;

import com.intuit.karate.RuntimeHook;
import com.intuit.karate.Suite;
import com.intuit.karate.core.ScenarioRuntime;
import com.intuit.karate.http.HttpRequest;
import com.intuit.karate.http.Response;

import java.io.IOException;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Queue;
import java.util.concurrent.ConcurrentLinkedQueue;

/**
 * Records every HTTP call made by a suite (method, path relative to /api/v1, status) into
 * target/api-calls/&lt;suite&gt;.csv so {@link ApiCoverageReport} can compare it with the Postman collection.
 */
public class ApiCoverageHook implements RuntimeHook {

    private final String suite;
    private final Queue<String> calls = new ConcurrentLinkedQueue<>();

    public ApiCoverageHook(String suite) {
        this.suite = suite;
    }

    @Override
    public void afterHttpCall(HttpRequest request, Response response, ScenarioRuntime sr) {
        try {
            String path = URI.create(request.getUrl()).getPath();
            int idx = path.indexOf("/api/v1/");
            if (idx < 0) {
                return;
            }
            String relative = path.substring(idx + "/api/v1/".length());
            calls.add(request.getMethod().toUpperCase() + "," + relative + "," + response.getStatus());
        } catch (Exception ignored) {
            // never let bookkeeping break a test
        }
    }

    @Override
    public void afterSuite(Suite suiteRun) {
        try {
            Path dir = Paths.get("target", "api-calls");
            Files.createDirectories(dir);
            Files.write(dir.resolve(suite + ".csv"), calls, StandardCharsets.UTF_8);
        } catch (IOException e) {
            System.err.println("could not write api call log: " + e.getMessage());
        }
    }
}
