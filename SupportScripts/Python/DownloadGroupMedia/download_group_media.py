# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
# 
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

import os
import requests
from urllib.parse import urlparse

ACCESS_TOKEN = 'YOUR_ACCESS_TOKEN'
GROUP_ID = 'WORPLACE_GROUP_ID'


def get_file_extension(url):
    parsed = urlparse(url)
    path = os.path.splitext(parsed.path)
    return path[1]


def download_image(image_url, filepath):
    image_data = requests.get(image_url, stream=True)
    if image_data.status_code == 200:
        with open(filepath, 'wb') as f:
            for chunk in image_data:
                f.write(chunk)


url = f'https://graph.facebook.com/{GROUP_ID}/feed'
params = {
    'access_token': ACCESS_TOKEN,
    'fields': 'attachments{media,subattachments}',
    'limit': 100
}

directory_counter = 1
save_directory = os.path.join(os.getcwd(), f'workplace_group_media')
while os.path.exists(save_directory):
    save_directory = os.path.join(
        os.getcwd(), f'workplace_group_media_{directory_counter}')
    directory_counter += 1

os.makedirs(save_directory)

file_counter = 0

while url:

    response = requests.get(url, params=params)
    data = response.json()
    posts = data.get('data', [])

    for post in posts:
        attachments = post.get('attachments', {}).get('data', [])
        for attachment in attachments:

            subattachments = attachment.get(
                'subattachments', {}).get('data', [])

            media = attachment.get('media')
            if media:
                image_url = media['image']['src']
                file_counter += 1
                file_extension = get_file_extension(image_url)
                filepath = os.path.join(
                    save_directory, f"file_{file_counter}{file_extension}")
                download_image(image_url, filepath)

            for subattachment in subattachments:
                subattachment_media = subattachment.get('media')
                if subattachment_media:
                    subattachment_media_url = subattachment_media['image']['src']
                    file_counter += 1
                    file_extension = get_file_extension(
                        subattachment_media_url)
                    filepath = os.path.join(
                        save_directory, f"file_{file_counter}{file_extension}")
                    download_image(subattachment_media_url, filepath)

    paging = data.get('paging', {})
    url = paging.get('next')
