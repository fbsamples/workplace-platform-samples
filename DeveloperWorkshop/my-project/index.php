<?php
  // Parameters
  $access_token = '{{ACCESS_TOKEN}}';
  $token = '{{VERIFY_TOKEN}}';
  $url = "https://graph.facebook.com/me/messages?access_token=".$access_token;

  if($_GET['hub_challenge']){
    if (isset($_GET['hub_verify_token'])){
      if($token == $_GET['hub_verify_token']){
        echo $_GET['hub_challenge'];
        exit;
      }else{
        error_log("Mismatch Token.");
      }
    }
  }

  $req = file_get_contents('php://input');
  if(!($req)){
    exit ('End');
  }
  error_log($req);

  //Received data processing from Webhook
  $str_json = json_decode($req, true);

  $mid = $str_json['entry'][0]['id'];
  $senderid = $str_json['entry'][0]['messaging'][0]['sender']['id'];
  $mtext = $str_json['entry'][0]['messaging'][0]['message']['text'];

  /*
    Sample process
    if user says 
      hello, hey or start, bot responds greeting.
      menu, show menu.
      others, do not understand your request.
  */
  switch(strtolower($mtext)){
    case 'hello':
    case 'hey':
    case 'start';
      send_request($url, greeting($senderid, $name));
      break;
    case 'menu':
      send_request($url, menu($senderid));
      send_request($url, menu_list($senderid));
      break;
    default;
      send_request($url, others($senderid));
  }

// Send chat bot response.
function send_request($url, $message){
  $ch = curl_init();
  curl_setopt($ch, CURLOPT_URL, $url);
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
  curl_setopt($ch, CURLOPT_POST, 1);
  curl_setopt($ch, CURLOPT_POSTFIELDS, $message);

  $headers = array();
  $headers[] = 'Content-Type: application/json';
  curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

  $result = curl_exec($ch);
}


function greeting($senderid, $name){
  return '{
    "recipient": {
      "id":"'.$senderid.'"
    },
    "message": {
      "text": "Hello!! I\'m a Concierge Bot.\\nPlease click Menu to start.",
      "quick_replies":[{
        "content_type":"text",
        "title":"Menu",
        "payload":"<POSTBACK_PAYLOAD>",
        "image_url":"https://workplacedeveloperphp.herokuapp.com/imgs/icon01.png"
      }]
    }
  }';
}

function menu($senderid){
  return '{
    "recipient": {
      "id":"'.$senderid.'"
    },"message": {
      "text": "What are you looking for today?"
    }
  }';
}

function menu_list($senderid){
  return '{
    "recipient":{
      "id":"'.$senderid.'"
    },
    "message":{
      "attachment":{
        "type":"template",
        "payload":{
          "template_type":"generic",
          "elements":[{
            "title":"New Hirer Training",
            "image_url":"https://workplacedeveloperphp.herokuapp.com/imgs/learning.png",
            "subtitle":"Online Training Courses",
            "default_action": {
              "type": "web_url",
              "url": "https://work.workplace.com/work/knowledge",
              "webview_height_ratio": "tall"
            }
          },
          {
            "title":"Help Desk",
            "image_url":"https://workplacedeveloperphp.herokuapp.com/imgs/helpdesk.png",
            "subtitle":"Welcome to the Helpdesk. Here you will be able to find what you look for.",
            "default_action": {
              "type": "web_url",
              "url": "https://www.workplace.com/help/work",
              "webview_height_ratio": "tall"
            }
          },
          {
            "title":"Set up Meeting",
            "image_url":"https://workplacedeveloperphp.herokuapp.com/imgs/meet.png",
            "subtitle":"Set 1 on 1 meeting with team members.",
            "default_action": {
              "type": "web_url",
              "url": "https://work.workplace.com/events",
              "webview_height_ratio": "tall"
            }
          },
          {
            "title":"Benefits & Perks",
            "image_url":"https://workplacedeveloperphp.herokuapp.com/imgs/benefits.png",
            "subtitle":"Learn about some of your benefits as a full-time employee.",
            "default_action": {
              "type": "web_url",
              "url": "https://www.workplace.com/help/work",
              "webview_height_ratio": "tall"
            }
          },
          ]
        }
      }
    }
  }';
}

function others($senderid){
  return '{
    "recipient": {
      "id":"'.$senderid.'"
    },"message": {
      "text": "I\'m sorry. I can\'t understand what is your request."
    }
  }';
}
?>