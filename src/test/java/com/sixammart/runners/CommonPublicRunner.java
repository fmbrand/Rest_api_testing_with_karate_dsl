package com.sixammart.runners;

import com.intuit.karate.Results;
import com.intuit.karate.Runner;
import com.sixammart.support.ApiCoverageHook;
import com.sixammart.support.ApiCoverageReport;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * Postman folder "Common (public)" - stateless endpoint checks, run in parallel.
 *
 * mvn test -Dtest=CommonPublicRunner
 * mvn test -Dtest=CommonPublicRunner -Dkarate.options="--tags @smoke"
 *
 * Report: target/karate-reports/common-public/karate-summary.html
 */
class CommonPublicRunner {

    @Test
    void commonPublic() {
        Results results = Runner.path("classpath:common/public")
                .tags("~@known-issue")
                .hook(new ApiCoverageHook("common-public"))
                .outputHtmlReport(true)
                .reportDir("target/karate-reports/common-public")
                .parallel(Integer.getInteger("threads", 5));
        System.out.println("Karate report: " + new java.io.File(results.getReportDir(), "karate-summary.html").getAbsolutePath());
        ApiCoverageReport.generate();
        assertEquals(0, results.getFailCount(), results.getErrorMessages());
    }
}
