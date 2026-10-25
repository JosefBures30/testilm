package com.otilm.core.api;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.actuate.info.Info;
import org.springframework.boot.actuate.info.InfoContributor;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/**
 * Class that contributes the deployer name to the Spring Boot Actuator info endpoint.
 *
 * Data for deployer is obtained from:
 * - the environment variable DEPLOYER_NAME.
 * - if the variable is not set, a default value of "default" is used.
 * Created as part of the test.
 * DeployerInfoContributor
 */
@Component
@Profile("!test")
public class DeployerInfoContributor implements InfoContributor {

    private final String deployerName;

    public DeployerInfoContributor(@Value("${DEPLOYER_NAME:default}") String deployerName) {
        this.deployerName = deployerName;
    }

    @Override
    public void contribute(Info.Builder builder) {
        builder.withDetail("builder", deployerName);
    }
}
