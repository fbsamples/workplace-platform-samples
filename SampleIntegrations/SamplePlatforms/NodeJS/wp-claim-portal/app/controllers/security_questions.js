var express = require("express"),
    router = express.Router(),
    config = require("../../config/config"),
    messages = require("../../config/messages"),
    scim = require("../models/account");

module.exports = function (app) {
  app.use("/", router);
};

router.post("/", function (req, response) {
  let employee_id = req.body.employeeId,
      security_questions = [req.body.securityQuestionOne, req.body.securityQuestionTwo,];

  const { Pool, } = require("pg");
  const connectionString = config.database_url;
  
  const pool = new Pool({
    connectionString: connectionString,
  });

  //check security questions
  pool.query(`SELECT * FROM employees WHERE employee_id = $1::text;`,[employee_id,], (err, res) => {
    let correctAnswers = false;
    console.log(res.rows.length);
    if (res === undefined || res.rows.length === 0){
      response.render("pages/home", {message: messages.USER_NOT_READY, });
      return;
    }
    if (security_questions[0] === res.rows[0].answer1 &&
      security_questions[1] === res.rows[0].answer2){
        correctAnswers = true;
    }
    if (!correctAnswers){
      console.log(`Security questions don't match for user ${employee_id}`);
      response.render("pages/home", {message: messages.ANSWER_DONT_MATCH, });
      return;
    }
    // get access code for user
    scim.getUserByExternalId(employee_id).then((result) => {
      let scimResults = JSON.parse(result);
      if (!Array.isArray(scimResults.Resources) || !scimResults.Resources.length){
        response.render("pages/home", {message: messages.USER_NOT_READY, });
      }
      let account = scimResults.Resources[0];
      let accountDetails = account["urn:scim:schemas:extension:facebook:accountstatusdetails:1.0"];
      if (accountDetails.invited == false){
        response.render("pages/home", {message: messages.USER_NOT_READY, });
      }
      let url = getRedirectURI(req.headers["user-agent"],accountDetails.accessCode);
      response.redirect(url);
    }).catch((error)=> {
      console.log(error);
      response.render("pages/home", {message: messages.SOMETHING_WRONG, });
    });  

    pool.end();
  });
    
});

function getRedirectURI (user_agent, access_code){
  var isiOS = /iPad|iPhone|iPod/.test(user_agent);
  var isAndroid = user_agent.toLowerCase().indexOf("android") > -1; 

  if (isiOS || isAndroid){
    return "fb-work-emailless://accesscode?access_code=" + access_code;
  } else {
    return "https://work.facebook.com/accesscode/?access_code=" + access_code;
  }
}