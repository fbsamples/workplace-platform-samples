# GitHub File an Issue

An example of filing a GitHub issue from a Workplace group, with roundtrip replies when the issues close. This example uses a [Basic Authentication](https://developer.github.com/v3/auth/#basic-authentication) on the GitHub API, so it will require you to generate a [personal access token](https://github.com/settings/tokens).

To set up this example, generate your GitHub access token, then create a new Workplace [custom integration](https://developers.facebook.com/docs/workplace/integrations/custom-integrations) app. Edit the `/config/default.json` file to add the custom integration token, app ID, app secret and a verify token for the [webhook subscription](https://developers.facebook.com/docs/workplace/integrations/custom-integrations/webhooks).

This example also maps GitHub Handles to Workplace IDs, so you can attribute the person who closed an issue via a comment in Workplace. You can add GitHub handles for this example using the `githubhandles.json` file.

*FileAnIssue requires **Read group content** and **Manage group content** permissions*
