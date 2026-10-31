package com.example.junit4;

import org.junit.AfterClass;
import org.junit.BeforeClass;
import org.junit.Test;

public class BeforeClassFailsScenario {

    @BeforeClass
    public static void beforeClass() {
        System.out.println("[EVENT] beforeClass");
        throw new IllegalStateException("Expected failure from @BeforeClass");
    }

    @Test
    public void test() {
        System.out.println("[EVENT] test");
    }

    @AfterClass
    public static void afterClass() {
        System.out.println("[EVENT] afterClass");
    }
}
