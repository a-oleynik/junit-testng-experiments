package com.example.testng;

import org.testng.annotations.AfterSuite;
import org.testng.annotations.BeforeSuite;
import org.testng.annotations.Test;

import static org.testng.Assert.fail;

public class TestFailsScenario {

    @BeforeSuite
    public void beforeSuite() {
        event("beforeSuite");
    }

    @Test
    public void test() {
        event("test");
        fail("Expected test failure");
    }

    @AfterSuite
    public void afterSuite() {
        event("afterSuite");
    }

    private static void event(String name) {
        System.out.println("[EVENT] " + name);
    }
}
