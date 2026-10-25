package com.otilm.core.api;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;
import org.springframework.boot.actuate.info.Info;

class DeployerInfoContributorTest {

    @Test
    void contributesConfiguredBuilderName() {
        Info.Builder info = new Info.Builder();

        new DeployerInfoContributor("JOSEF BURES, josef.bures@gmail.com").contribute(info);

        assertEquals("JOSEF BURES, josef.bures@gmail.com", info.build().getDetails().get("builder"));
    }

    @Test
    void contributesDefaultBuilderName() {
        Info.Builder info = new Info.Builder();

        new DeployerInfoContributor("default").contribute(info);

        assertEquals("default", info.build().getDetails().get("builder"));
    }
}
