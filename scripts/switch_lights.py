#!/home/anthe/software/miniconda3/envs/home_automation/bin/python

import sys
import asyncio
import pandas as pd
import argparse
from tapo import ApiClient

async def control_device(device_name):
    user = pd.read_csv('~/.tapo.profile', index_col=0, header=None)
    tapo_username = user.loc['TAPO_USERNAME'].item() # os.getenv("TAPO_USERNAME")
    tapo_password = user.loc["TAPO_PASSWORD"].item() # os.getenv("TAPO_PASSWORD")
    if device_name not in user.index:
        print(f"Error: Device '{device_name}' not found in profile")
        sys.exit(1)
    ip_address = user.loc[device_name].item() # os.getenv("TAPO_STRIPE_IP")

    client = ApiClient(tapo_username, tapo_password)
    device = await client.l530(ip_address)

    device_info = await device.get_device_info()
    device_on = device_info.to_dict()['device_on']
    if not device_on:
        await device.on()
        print(f'Turned {device_name} on')
    else:
        await device.off()
        print(f'Turned {device_name} off')

def parse_args():
    parser = argparse.ArgumentParser(description="Control Tapo P300 child devices.")
    parser.add_argument("device", type=str, help="Name of the device to control (e.g., 'laptop_charger', 'drive_1', 'sound_system')")
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_args()
    asyncio.run(control_device(args.device))
