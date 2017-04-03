# FeedPoster Sample

An example custom integration that automates posting new articles into a predefined Workplace group when new content appears on a given RSS feed. 

## Setup
1. Create a new [Custom Integration](https://developers.facebook.com/docs/workplace/custom-integrations) app with **Post to Groups** permission.
2. Check out the code and deploy to a server capable of hosting [node.js](https://nodejs.org) applications.
3. Run `npm install` to install the required modules
4. Modify the `.env` file to include the `ACCESS_TOKEN` for your app, the group ID for your `TARGET_GROUP` and a URL for the RSS feed you want to use, and start the node application by running `node clock.js`

## Notes on Cron
This app uses the `node-cron` module. Visit the [cron project page](https://github.com/ncb000gt/node-cron) for details on how to use it for custom scheduling.