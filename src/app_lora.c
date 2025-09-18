/*
 * Copyright (c) 2025
 * Regis Rousseau
 * Univ Lyon, INSA Lyon, Inria, CITI, EA3720
 * SPDX-License-Identifier: Apache-2.0
 */

//  ========== includes ====================================================================
#include "app_lora.h"

//  ========== app_lora_config =============================================================
int8_t app_lora_config(const struct device *dev, bool TxRx)
{
	int8_t ret;
	struct lora_modem_config config;

	// configure lora phy layer parameters
	config.frequency = 868100000;
	config.bandwidth = BW_125_KHZ;
	config.datarate = SF_9;
	config.preamble_len = 8;
	config.coding_rate = CR_4_5;
	config.tx_power = 17;
	config.iq_inverted = false;
	config.public_network = false;
	config.tx = TxRx;

	// apply the configuration to the LoRa device
	ret = lora_config(dev, &config);
	if (ret < 0) {
		printk("lora device configuration failed. error: %d\n", ret);
		return 0;
	}
	return 1;
}
