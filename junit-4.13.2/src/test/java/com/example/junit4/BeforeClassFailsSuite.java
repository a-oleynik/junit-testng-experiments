package com.example.junit4;

import org.junit.AfterClass;
import org.junit.BeforeClass;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Suite;

@RunWith(Suite.class)
@Suite.SuiteClasses(BeforeClassFailsSuite.SelectedCase.class)
public class BeforeClassFailsSuite {

    @BeforeClass
    public static void beforeClass() {
        System.out.println("[EVENT] suite.beforeClass");
        throw new IllegalStateException("Expected failure from suite @BeforeClass");
    }

    @AfterClass
    public static void afterClass() {
        System.out.println("[EVENT] suite.afterClass");
    }

    public static class SelectedCase {

        @BeforeClass
        public static void beforeClass() {
            System.out.println("[EVENT] selected.beforeClass");
        }

        @Test
        public void test() {
            System.out.println("[EVENT] test");
        }

        @AfterClass
        public static void afterClass() {
            System.out.println("[EVENT] selected.afterClass");
        }
    }
}
