package com.example.testng;

import org.testng.annotations.AfterSuite;
import org.testng.annotations.BeforeSuite;
import org.testng.annotations.Test;

public class AfterFailsScenario {

    @BeforeSuite
    public void beforeSuite() {
        event("beforeSuite");
    }

    @Test
    public void test() {
        event("test");
    }

    @AfterSuite
    public void afterSuite() {
        event("afterSuite");
        throw new IllegalStateException("Expected failure from @AfterSuite");
    }

    private static void event(String name) {
        System.out.println("[EVENT] " + name);
    }
}
