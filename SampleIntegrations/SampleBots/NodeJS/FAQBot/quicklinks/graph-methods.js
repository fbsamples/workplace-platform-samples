module.exports = function(request, config){

  let module = {};

  //GraphAPI endpoint
  module._ga = request.defaults({
    baseUrl: 'https://graph.facebook.com',
    json: true,
    auth: {
        'bearer' : config.ACCESS_TOKEN
      }
    })

    //Send messages by using the Send API
    module._callSendAPI = function(messageData) {
      this._ga({
        url: '/me/messages',
        method: 'POST',
        json: messageData
      },
      function (error, response, body) {
        if(!error && response.statusCode == 200) {
          var recipientId = body.recipient_id;
          var messageId = body.message_id;
          if (messageId) console.log('Successfully sent message with id %s to recipient %s', messageId, recipientId);
          else console.log('Successfully called Send API for recipient %s', recipientId);
        } else {
          console.error('Failed calling Send API', response.statusCode, response.statusMessage, body.error);
        }
      });
    }

    return module;

}
