package com.example.junit6;

import org.junit.jupiter.api.Test;
import org.junit.platform.suite.api.AfterSuite;
import org.junit.platform.suite.api.BeforeSuite;
import org.junit.platform.suite.api.SelectClasses;
import org.junit.platform.suite.api.Suite;

import static org.junit.jupiter.api.Assertions.fail;

@Suite
@SelectClasses(TestFailsSuite.SelectedCase.class)
public class TestFailsSuite {

    @BeforeSuite
    static void beforeSuite() {
        event("beforeSuite");
    }

    @AfterSuite
    static void afterSuite() {
        event("afterSuite");
    }

    static class SelectedCase {

        @Test
        void test() {
            event("test");
            fail("Expected test failure");
        }
    }

    private static void event(String name) {
        System.out.println("[EVENT] " + name);
    }
}
