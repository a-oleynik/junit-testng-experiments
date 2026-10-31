package com.example.junit4;

import org.junit.Test;
import org.junit.runner.JUnitCore;
import org.junit.runner.Result;

import java.util.Arrays;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

public class ClassRuleOrderTest {

    @Test
    public void ordersSeparateClassRulesUsingAnnotationAttribute() {
        OrderedClassRulesSuite.EVENTS.clear();

        Result result = JUnitCore.runClasses(OrderedClassRulesSuite.class);

        assertTrue(result.getFailures().toString(), result.wasSuccessful());
        assertEquals(
                Arrays.asList(
                        "outer.before",
                        "inner.before",
                        "test",
                        "inner.after",
                        "outer.after"
                ),
                OrderedClassRulesSuite.EVENTS
        );
        System.out.println("[EVENTS] " + OrderedClassRulesSuite.EVENTS);
    }
}
