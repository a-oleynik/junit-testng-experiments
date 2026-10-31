package com.example.testng;

import org.testng.annotations.AfterSuite;
import org.testng.annotations.BeforeSuite;
import org.testng.annotations.Test;

public class BeforeFailsWithAlwaysRunScenario {

    @BeforeSuite
    public void beforeSuite() {
        event("beforeSuite");
        throw new IllegalStateException("Expected failure from @BeforeSuite");
    }

    @Test
    public void test() {
        event("test");
    }

    @AfterSuite(alwaysRun = true)
    public void afterSuite() {
        event("afterSuite");
    }

    private static void event(String name) {
        System.out.println("[EVENT] " + name);
    }
}
