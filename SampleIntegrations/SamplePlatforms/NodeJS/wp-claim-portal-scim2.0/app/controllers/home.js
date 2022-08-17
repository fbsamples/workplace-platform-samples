var express = require("express"),
    router = express.Router();

module.exports = function (app) {
  app.use("/", router);
};

// List out all the thanks recorded in the database
router.get("/", function (request, response) {
  response.render("pages/home", {message: "", access_code: "", access_code_url: "",});
});