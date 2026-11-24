package com.sixammart.runners;

import com.intuit.karate.Results;
import com.intuit.karate.Runner;
import com.sixammart.support.ApiCoverageHook;
import com.sixammart.support.ApiCoverageReport;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * Business scenarios: multi-actor flows that create their own data and clean it up (src/test/resources/scenarios).
 *
 * mvn test -Dtest=E2ERunner                                         -> all scenarios
 * mvn test -Dtest=E2ERunner -Dkarate.options="--tags @order"        -> one business area
 * mvn test -Dtest=E2ERunner -Dkarate.options="--tags @order,@negative"  (OR)   /  "--tags @order --tags @negative" (AND)
 *
 * Sequential by default (-Dthreads=1): parallel orders against the same store intermittently fail on the test server
 * with 403 "Failed to place order" (see README). Use -Dthreads=N only when you want to load the system.
 *
 * Report: target/karate-reports/e2e/karate-summary.html
 */
class E2ERunner {

    @Test
    void scenarios() {
        Results results = Runner.path("classpath:scenarios")
                .tags("~@known-issue", "~@blocked")
                .hook(new ApiCoverageHook("e2e"))
                .outputHtmlReport(true)
                .reportDir("target/karate-reports/e2e")
                .parallel(Integer.getInteger("threads", 1));
        System.out.println("Karate report: " + new java.io.File(results.getReportDir(), "karate-summary.html").getAbsolutePath());
        ApiCoverageReport.generate();
        assertEquals(0, results.getFailCount(), results.getErrorMessages());
    }
}
