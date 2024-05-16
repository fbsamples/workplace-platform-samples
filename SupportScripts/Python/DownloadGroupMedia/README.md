# Workplace Download Group Media Support Script

This Python script downloads all media (images at this time) files from a specified Workplace by Facebook group.

NOTE: At this time, only images are downloaded.

## Requirements

- Python 3.6 or higher
- `requests` library

## Setup

1. Clone this repository.
2. Install the requests Python library using pip:

```bash
pip install requests
```

1. Replace `YOUR_ACCESS_TOKEN` and `WORPLACE_GROUP_ID` in the script with your actual access token and the ID of the Workplace group you want to download media from. [Read this documentation on how to set up a custom integration on Workplace to get an access token.](https://developers.facebook.com/docs/workplace/custom-integrations-new) Your integration will need permission to `Read all messages` and `Read group content` in addition to having access to the group.

## Usage

Run the script using Python:

```bash
python download_group_media.py
```

The script will download all media files from the specified Workplace group and save them in a new directory in the current working directory. The directory will be named `workplace_group_media`, or `workplace_group_media_X` if a directory with the previous name already exists, where `X` is a number.

## Note

This script only downloads media files that are directly attached to posts. It does not download media files that are linked from external sources.
