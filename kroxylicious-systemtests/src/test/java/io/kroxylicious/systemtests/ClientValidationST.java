/*
 * Copyright Kroxylicious Authors.
 *
 * Licensed under the Apache Software License version 2.0, available at http://www.apache.org/licenses/LICENSE-2.0
 */

package io.kroxylicious.systemtests;

import org.junit.jupiter.api.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import io.kroxylicious.systemtests.enums.KafkaClientType;

import static org.junit.jupiter.api.Assertions.assertNotEquals;

/**
 * Test suite that validates Kafka client type.
 * This test fails if run with strimzi_test_client, otherwise passes with hello message.
 */
class ClientValidationST extends AbstractSystemTests {
    private static final Logger LOGGER = LoggerFactory.getLogger(ClientValidationST.class);

    @Test
    void testClientType(String namespace) {
        String currentClient = Environment.KAFKA_CLIENT.toUpperCase();
        LOGGER.info("Current Kafka client: {}", currentClient);

        if (currentClient.equals(KafkaClientType.STRIMZI_TEST_CLIENT.name())) {
            LOGGER.error("Test is running with STRIMZI_TEST_CLIENT - this should not happen!");
            assertNotEquals(KafkaClientType.STRIMZI_TEST_CLIENT.name(), currentClient,
                    "Test must not run with strimzi_test_client");
        }
        else {
            LOGGER.info("Hello! Running with client: {}", currentClient);
        }
    }
}
