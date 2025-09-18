/*
 * Copyright (c) 2025
 * Regis Rousseau
 * Univ Lyon, INSA Lyon, Inria, CITI, EA3720
 * SPDX-License-Identifier: Apache-2.0
 */

//  ========== includes ====================================================================
#include "app_lora.h"

//  ========== globals =====================================================================
// define GPIO configurations for the LED
static const struct gpio_dt_spec led_tx = GPIO_DT_SPEC_GET(LED_TX, gpios);

//  ========== main ========================================================================
int8_t main(void)
{
	// print initial message indicating the program and board name
	printk("LoRa Transmitter Example\nBoard: %s\n", CONFIG_BOARD);
	
	// initialize the LoRa radio device
	const struct device *lora_dev = DEVICE_DT_GET(DT_ALIAS(lora0));
	if (!device_is_ready(lora_dev)) {
		printk("%s: device not ready\n", lora_dev->name);
		return;
	}

	// configure the transmission LED pin as an output
	gpio_pin_configure_dt(&led_tx, GPIO_OUTPUT_ACTIVE);
	gpio_pin_set_dt(&led_tx, 0);

	// configuration of LoRa parameters for transmission 
	if (app_lora_config(lora_dev, TRANSMIT)) {
		printk("LoRa device configured\n");
	} else {
			return 0;
	}

	// main loop for transmitting packets over LoRa
	while (1) {
		// generate a random 32-bit payload (simulating ADC value)
		int32_t payload = sys_rand32_get();

		// transmit the payload using LoRa
		int8_t ret = lora_send(lora_dev, &payload, sizeof(payload));
		if (ret == 0) {
			printk("LoRa send failed. error %d\n", ret);
			return 0;
		} else {
			// toggle the transmission LED to indicate successful transmission
			ret = gpio_pin_toggle_dt(&led_tx);	 
			if (ret < 0) {
				return 0;
			}
			
			// print details about the transmitted data
			printk("transmitted value: %d\n", payload);
		}
		// wait for a specified interval before transmitting the next packet
		k_msleep(SLEEP_TIME_MS);;	
	}
	return 0;
}