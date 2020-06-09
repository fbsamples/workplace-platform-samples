var GoogleSpreadsheet = require('google-spreadsheet');
var creds = require('./client_secret.json')


//Variable declaration for column names

var tag = "";
var meaning = "";
var know_more = "";
var related_links = "";


var eachRow = new Map();
var rowsval;
var found_word_flag=true;
var found_word="";




require('dotenv').config(); //Configuration values like workplace ID, Google Sheet details


//Variable declaration for getting all the value from the config value again

var doc = new GoogleSpreadsheet(process.env.Google_sheet_bot_queries);
var newquerydoc = new GoogleSpreadsheet(process.env.Google_sheet_new_queries);
var AdminworkplaceId = process.env.Admin_workplace_id;
var Google_sheet_bot_queries_link= process.env.Google_sheet_bot_queries_link;
var newquerydoc_link= process.env.Google_sheet_new_queries_link;



module.exports = function (graph_api) {

    //Get messages sent to the bot by the user
    module._getMessages = function (req) {
        let msgs = [],
            data = req.body;
        // Make sure this is a page subscription
        if (data.object == 'page') {
            for (let pageEntry of data.entry) {
                for (let messagingEvent of pageEntry.messaging) {
                    if (messagingEvent.message) msgs.push(messagingEvent);
                }
            }
        }
        return msgs;
    }

    //Handle received message
    module._handleMessage = function (message) {


        let senderID = message.sender.id;
        doc.useServiceAccountAuth(creds, function (err) {

            // Get all of the rows from the spreadsheet
            doc.getRows(1, function (err, rows) {
                console.log("console message")
                rows.forEach(function (rowValue) {
                    eachRow.set(rowValue.tag, rowValue.index)
                    rowsval = rows;
                })
            });
        });


        //getting the message from the user
        var incoming_message = message.message.text
//        console.log(incoming_message)

        //Welcome message for user
        if (incoming_message.includes("Hey") || incoming_message.includes("Hello") || incoming_message.includes("Hi")) {
            this._sendMessage(senderID, "Hello !! I am the FAQ Bot. Please type any term that you dont know off and I can help you get more information on it :) ");

        } else if (incoming_message.length > 0) {

            //- User friendliness  check for "message too short"
            if (incoming_message.length < 3) {

                this._sendMessage(senderID, "Sorry your message is too short for me to understand , please ensure input message should at least be 3 or more letters");
            /*
                Developer can add more checks to the incoming message and reply the the sender by adding conditions here
             */

            } else {

                found_word_flag=false;
                found_word="";


                //Splitting the sender message to multiple words to find the query by comparing each word with the tag from the google sheet
                var each_word= incoming_message.split(" ");

                each_word.forEach(function (element) {

//                    console.log("word is " + element)

                    if (eachRow.has(element)) {
                        found_word_flag=true;
                        found_word=element;
                    }

                })

                //Get the details from google sheet if the any word is same as any of the tag in the sheet

                if(found_word_flag)
                {
//                  console.log('item present in index ' + eachRow.get(found_word))

                    //row number for the sheet
                    index = eachRow.get(found_word) - 1;
                    tag = rowsval[index].tag;
                    meaning = rowsval[index].meaning;
                    know_more = rowsval[index].def;
                    related_links = rowsval[index].more;

                    //send details of the row with personalised message to the sender

                    this._sendMessage(senderID, "Hey !! You want to know about  " + found_word + ". I can help with you that :)" + found_word
                        + " is " + meaning + ". " + know_more + " . You can read more about it in this link :  " + related_links);
                }
            else

                    //if none od the word from the user message match the tags in the sheet
                 {
                    this._sendMessage(senderID, "Sorry I did not find that one , But dont worry I have sent it to the admin for review. It will be updated soon. ");


                    /*
                    Send message to the admin
                    Add the incoming message in the admin message
                    Add the google sheet bot queries link and new query google sheet link
                     */
                    
                    this._sendMessage(AdminworkplaceId, "Hey Admin!! The Help bot just got a question called : " + incoming_message + "  \n which it does not know the answer for. " +
                        "Can you update the sheet with the meaning ?  \n Quick link :"+ Google_sheet_bot_queries_link + " https://docs.google.com/spreadsheets/d/1D7CvKvJ0o6Wy8ZxZx3Oj4RfwqUaVBs-ueWC6xWZ9-_8/edit#gid=0 .. \n " +
                        "Dont worry if you want" +
                        "to do it later , i have saved the query here : "+newquerydoc_link);


                    //Add the new query tag to the new sheet

                    newquerydoc.useServiceAccountAuth(creds, function (err) {
                        newquerydoc.addRow(1, {tag: incoming_message}, function (err) {
                            if (err) {
                                console.log(err);
                            }
                        });

                    });

                }

            }


        }


    }

    //Send message from the bot to the user
    module._sendMessage = function (recipientId, text) {
        let messageData = {
            recipient: {
                id: recipientId
            },
            message: {
                text: text,
                metadata: 'DEVELOPER_DEFINED_METADATA'
            }
        };
        graph_api._callSendAPI(messageData);
    }

    return module;

}
