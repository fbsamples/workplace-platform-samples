
var common = require("./common.js"),
    rp = require("request-promise"),
    config = require("../../config/config.js");

// const scimAPIUrl = "https://www.workplace.com/scim/v1/";
const scimAPIUrl = "https://scim.workplace.com/Users/";
module.exports = {
  "getUserByExternalId": function getUserByExternalId(externalId) {
    let options = {
      url: scimAPIUrl,
      qs:{
        "filter": "externalId eq \"" + externalId + "\"",
      },
      headers: {
        "Authorization": config.page_access_token,
        "Content-Type": "application/json",
        "User-Agent": "wp-claim-portal",
      },
      method: "GET",
    };
    return rp(options);
  },
  "updateUserEmail": function updateUserEmail(originalEmail, updatedEmail) {
    return this.getUserByEmail(originalEmail).then(user => {
      let newUser = JSON.parse(user).Resources[0];
      if (!newUser){
        throw new Error("Could not find " + originalEmail);
      }
      let options = common.createPutOptions(scimAPIUrl + "/" + newUser.id);
      newUser.userName = updatedEmail;
      options.body = JSON.stringify(newUser);
      return rp(options);  
    }).catch(error => {
      throw error;
    });
  },
};

