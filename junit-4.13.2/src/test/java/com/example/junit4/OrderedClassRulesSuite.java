package com.example.junit4;

import org.junit.ClassRule;
import org.junit.Test;
import org.junit.rules.ExternalResource;
import org.junit.runner.RunWith;
import org.junit.runners.Suite;

import java.util.ArrayList;
import java.util.List;

@RunWith(Suite.class)
@Suite.SuiteClasses(OrderedClassRulesSuite.ExampleCase.class)
public class OrderedClassRulesSuite {

    static final List<String> EVENTS = new ArrayList<String>();

    @ClassRule(order = 0)
    public static final ExternalResource OUTER = new LoggingRule("outer");

    @ClassRule(order = 1)
    public static final ExternalResource INNER = new LoggingRule("inner");

    public static class ExampleCase {

        @Test
        public void test() {
            EVENTS.add("test");
        }
    }

    private static final class LoggingRule extends ExternalResource {

        private final String name;

        private LoggingRule(String name) {
            this.name = name;
        }

        @Override
        protected void before() {
            EVENTS.add(name + ".before");
        }

        @Override
        protected void after() {
            EVENTS.add(name + ".after");
        }
    }
}
