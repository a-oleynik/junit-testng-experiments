package com.example.junit5;

import org.junit.jupiter.api.Test;
import org.junit.platform.suite.api.AfterSuite;
import org.junit.platform.suite.api.BeforeSuite;
import org.junit.platform.suite.api.SelectClasses;
import org.junit.platform.suite.api.Suite;

@Suite
@SelectClasses(BeforeFailsSuite.SelectedCase.class)
public class BeforeFailsSuite {

    @BeforeSuite
    static void beforeSuite() {
        event("beforeSuite");
        throw new IllegalStateException("Expected failure from @BeforeSuite");
    }

    @AfterSuite
    static void afterSuite() {
        event("afterSuite");
    }

    static class SelectedCase {

        @Test
        void test() {
            event("test");
        }
    }

    private static void event(String name) {
        System.out.println("[EVENT] " + name);
    }
}
