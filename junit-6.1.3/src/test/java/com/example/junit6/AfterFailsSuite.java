package com.example.junit6;

import org.junit.jupiter.api.Test;
import org.junit.platform.suite.api.AfterSuite;
import org.junit.platform.suite.api.BeforeSuite;
import org.junit.platform.suite.api.SelectClasses;
import org.junit.platform.suite.api.Suite;

@Suite
@SelectClasses(AfterFailsSuite.SelectedCase.class)
public class AfterFailsSuite {

    @BeforeSuite
    static void beforeSuite() {
        event("beforeSuite");
    }

    @AfterSuite
    static void afterSuite() {
        event("afterSuite");
        throw new IllegalStateException("Expected failure from @AfterSuite");
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
