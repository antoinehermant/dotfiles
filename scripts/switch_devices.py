#!/home/anthe/software/miniconda3/envs/home_automation/bin/python

import asyncio
import pandas as pd
import argparse
import os
from tapo import ApiClient

async def control_device(device_name):
    user = pd.read_csv('~/.tapo.profile', index_col=0, header=None)
    tapo_username = user.loc['TAPO_USERNAME'].item() # os.getenv("TAPO_USERNAME")
    tapo_password = user.loc["TAPO_PASSWORD"].item() # os.getenv("TAPO_PASSWORD")
    ip_address = user.loc["TAPO_STRIPE_IP"].item() # os.getenv("TAPO_STRIPE_IP")

    client = ApiClient(tapo_username, tapo_password)
    power_strip = await client.p300(ip_address)
    child_device_list = await power_strip.get_child_device_list()

    device_map = {
        "sound_system": 0,
        "laptop_charger": 1,
        "drive_1": 2,
    }

    if device_name not in device_map:
        print(f"Error: Unknown device '{device_name}'. Available devices: {list(device_map.keys())}")
        return

    device_index = device_map[device_name]
    device = child_device_list[device_index]
    plug = await power_strip.plug(device_id=device.device_id)

    if not device.device_on:
        await plug.on()
        print(f'Turned {device_name} on')
    else:
        await plug.off()
        print(f'Turned {device_name} off')

def parse_args():
    parser = argparse.ArgumentParser(description="Control Tapo P300 child devices.")
    parser.add_argument("device", type=str, help="Name of the device to control (e.g., 'laptop_charger', 'drive_1', 'sound_system')")
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_args()
    asyncio.run(control_device(args.device))
